import Foundation

struct EmailConnection: Identifiable, Codable, Equatable {
    var id: UUID
    var emailAddress: String
    var provider: String
    var accessToken: String
    var refreshToken: String
    var lastSync: Date?
    
    init(id: UUID = UUID(), emailAddress: String, provider: String = "google", accessToken: String, refreshToken: String, lastSync: Date? = nil) {
        self.id = id
        self.emailAddress = emailAddress
        self.provider = provider
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.lastSync = lastSync
    }
    
    var isExpired: Bool {
        // Consider expired if lastSync is more than 1 hour ago and we haven't synced recently
        // This is a simple heuristic - in practice, we'd check the token itself
        guard let lastSync = lastSync else { return false }
        return Date().timeIntervalSince(lastSync) > 3600
    }
    
    var status: ConnectionStatus {
        if isExpired {
            return .expired
        }
        return .valid
    }
}

enum ConnectionStatus: String, Codable {
    case valid
    case expired
    
    var displayName: String {
        switch self {
        case .valid: return "Valid"
        case .expired: return "Expired"
        }
    }
}

