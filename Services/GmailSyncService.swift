import Foundation
import GoogleSignIn
import CryptoKit
import FirebaseCore

final class GmailSyncService {
    private let baseURL = "https://gmail.googleapis.com/gmail/v1"
    
    // MARK: - Token Refresh
    func refreshAccessToken(refreshToken: String) async throws -> String {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GmailSyncError.noClientID
        }
        
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GmailSyncError.tokenRefreshFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw GmailSyncError.tokenRefreshFailed
        }
        
        return accessToken
    }
    
    // MARK: - Gmail API Methods
    func listMessages(accessToken: String, query: String = "", maxResults: Int = 10) async throws -> [GmailMessage] {
        var urlString = "\(baseURL)/users/me/messages?maxResults=\(maxResults)"
        if !query.isEmpty {
            urlString += "&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        
        guard let url = URL(string: urlString) else {
            throw GmailSyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailSyncError.apiError(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GmailSyncError.tokenExpired
            }
            throw GmailSyncError.apiError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]] else {
            return []
        }
        
        // Fetch full message details
        var fullMessages: [GmailMessage] = []
        for message in messages {
            if let id = message["id"] as? String {
                do {
                    let fullMessage = try await getMessage(accessToken: accessToken, messageId: id)
                    fullMessages.append(fullMessage)
                } catch {
                    print("Error fetching message \(id): \(error)")
                }
            }
        }
        
        return fullMessages
    }
    
    func getMessage(accessToken: String, messageId: String) async throws -> GmailMessage {
        let urlString = "\(baseURL)/users/me/messages/\(messageId)?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date"
        
        guard let url = URL(string: urlString) else {
            throw GmailSyncError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailSyncError.apiError(-1)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GmailSyncError.tokenExpired
            }
            throw GmailSyncError.apiError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = json["payload"] as? [String: Any],
              let headers = payload["headers"] as? [[String: Any]] else {
            throw GmailSyncError.invalidResponse
        }
        
        var from: String = ""
        var subject: String = ""
        var date: String = ""
        
        for header in headers {
            if let name = header["name"] as? String,
               let value = header["value"] as? String {
                switch name.lowercased() {
                case "from":
                    from = value
                case "subject":
                    subject = value
                case "date":
                    date = value
                default:
                    break
                }
            }
        }
        
        return GmailMessage(
            id: messageId,
            from: from,
            subject: subject,
            date: date
        )
    }
    
    // MARK: - Sync Gmail
    func syncGmail(connection: EmailConnection) async throws -> GmailSyncResult {
        // Try to use current access token
        var accessToken = connection.accessToken
        
        // Attempt to refresh if needed
        do {
            let messages = try await listMessages(accessToken: accessToken, query: "in:inbox has:nouserlabels -category:promotions -category:social", maxResults: 50)
            
            // Filter messages from subscription senders and parse
            let subscriptions = parseMessagesForSubscriptions(messages: messages)
            
            return GmailSyncResult(
                success: true,
                subscriptionsFound: subscriptions.count,
                newAccessToken: accessToken
            )
        } catch GmailSyncError.tokenExpired {
            // Refresh token
            do {
                accessToken = try await refreshAccessToken(refreshToken: connection.refreshToken)
                
                // Retry with new token
                let messages = try await listMessages(accessToken: accessToken, query: "in:inbox has:nouserlabels -category:promotions -category:social", maxResults: 50)
                let subscriptions = parseMessagesForSubscriptions(messages: messages)
                
                return GmailSyncResult(
                    success: true,
                    subscriptionsFound: subscriptions.count,
                    newAccessToken: accessToken
                )
            } catch {
                throw GmailSyncError.tokenRefreshFailed
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Message Parsing
    private func parseMessagesForSubscriptions(messages: [GmailMessage]) -> [ParsedSubscription] {
        var subscriptions: [ParsedSubscription] = []
        
        // Known subscription sender patterns
        let subscriptionSenders = [
            "netflix", "spotify", "amazon prime", "apple", "disney", "hulu",
            "hbo", "paramount", "peacock", "youtube", "adobe", "microsoft",
            "dropbox", "google one", "icloud", "atlassian", "slack", "zoom"
        ]
        
        for message in messages {
            let fromLower = message.from.lowercased()
            
            // Check if sender matches known subscription patterns
            guard subscriptionSenders.contains(where: { fromLower.contains($0) }) else {
                continue
            }
            
            // Parse subject for subscription info
            if let parsed = parseSubscriptionFromMessage(message) {
                subscriptions.append(parsed)
            }
        }
        
        return subscriptions
    }
    
    private func parseSubscriptionFromMessage(_ message: GmailMessage) -> ParsedSubscription? {
        // Extract merchant name from sender
        let merchant = extractMerchantName(from: message.from)
        
        // Try to extract price and frequency from subject
        let (price, frequency) = extractPriceAndFrequency(from: message.subject)
        
        // Skip if we can't extract essential info
        guard !merchant.isEmpty, price > 0 else {
            return nil
        }
        
        return ParsedSubscription(
            merchant: merchant,
            price: price,
            frequency: frequency
        )
    }
    
    private func extractMerchantName(from sender: String) -> String {
        // Extract name from email address or display name
        // e.g., "Netflix <billing@netflix.com>" -> "Netflix"
        if let startIndex = sender.range(of: "<"),
           let endIndex = sender.range(of: "@", range: startIndex.upperBound..<sender.endIndex) {
            let domain = String(sender[startIndex.upperBound..<endIndex.lowerBound])
            return domain.capitalized
        }
        
        if let atIndex = sender.firstIndex(of: "@") {
            let name = String(sender[..<atIndex])
            return name.capitalized
        }
        
        return sender
    }
    
    private func extractPriceAndFrequency(from subject: String) -> (price: Double, frequency: String) {
        var price: Double = 0
        var frequency: String = "monthly"
        
        // Try to extract price (e.g., "$9.99", "9.99 USD")
        let pricePattern = #"\$?(\d+\.?\d*)"#
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let match = regex.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)),
           let range = Range(match.range(at: 1), in: subject) {
            price = Double(subject[range]) ?? 0
        }
        
        // Detect frequency
        let subjectLower = subject.lowercased()
        if subjectLower.contains("yearly") || subjectLower.contains("annual") {
            frequency = "yearly"
        } else if subjectLower.contains("weekly") {
            frequency = "weekly"
        } else if subjectLower.contains("quarterly") {
            frequency = "quarterly"
        }
        
        return (price, frequency)
    }
    
    // MARK: - Deduping
    static func generateSubscriptionHash(merchant: String, price: Double, frequency: String) -> String {
        let input = "\(merchant.lowercased())|\(price)|\(frequency.lowercased())"
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Models
struct GmailMessage {
    let id: String
    let from: String
    let subject: String
    let date: String
}

struct ParsedSubscription {
    let merchant: String
    let price: Double
    let frequency: String
}

struct GmailSyncResult {
    let success: Bool
    let subscriptionsFound: Int
    let newAccessToken: String?
}

enum GmailSyncError: LocalizedError {
    case noClientID
    case invalidURL
    case tokenExpired
    case tokenRefreshFailed
    case apiError(Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noClientID:
            return "Google client ID not found"
        case .invalidURL:
            return "Invalid URL"
        case .tokenExpired:
            return "Access token expired"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .apiError(let code):
            return "Gmail API error: \(code)"
        case .invalidResponse:
            return "Invalid response from Gmail API"
        }
    }
}

