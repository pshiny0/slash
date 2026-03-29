import Foundation
import Combine
import UIKit

final class DataManager: ObservableObject {
    // Auth
    @Published private(set) var currentUser: SlashUser? = nil
    @Published var isAuthenticated: Bool = false

    // Subscriptions
    @Published private(set) var subscriptions: [Subscription] = []
    @Published var searchQuery: String = ""
    @Published var selectedCategory: SubscriptionCategory? = nil

    // Services directory
    @Published private(set) var serviceDirectory: [ServiceDirectoryItem] = []
    
    // Activity tracking
    @Published private(set) var activities: [ActivityItem] = []
    
    // Budget
    @Published var monthlyBudget: Double = 0.0

    private var cancellables: Set<AnyCancellable> = []
    let firebase = FirebaseService()
    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        firebase.configure()
        
        // Load saved budget
        loadBudget()

        firebase.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                if user != nil {
                    self?.startSubscriptionsListener()
                    if let urlString = user?.profileImageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                        ImageCache.shared.prefetch(url: url)
                    }
                } else {
                    self?.subscriptions = []
                }
            }
            .store(in: &cancellables)

        loadServiceDirectory()
    }

    // MARK: - Auth
    func signInWithEmail(email: String, password: String) async throws {
        try await firebase.signInWithEmail(email: email, password: password)
    }

    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        try await firebase.signUpWithEmail(email: email, password: password, displayName: displayName)
    }


    func signInWithGoogle() async throws {
        try await firebase.signInWithGoogle()
    }

    func signOut() throws {
        try firebase.signOut()
    }

    func updateCurrentUserProfile(displayName: String, firstName: String?, lastName: String?) async throws {
        try await firebase.updateCurrentUserProfile(
            displayName: displayName,
            firstName: firstName,
            lastName: lastName
        )
    }

    // MARK: - Subscriptions
    private func startSubscriptionsListener() {
        firebase.subscriptionsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subs in
                self?.subscriptions = subs
                self?.processRenewalsIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    func refreshSubscriptions() {
        // Cancel existing listener and restart it to force refresh
        cancellables.removeAll()
        startSubscriptionsListener()
    }

    // MARK: - Renewal Processing
    private func processRenewalsIfNeeded() {
        guard !subscriptions.isEmpty else { return }
        let today = Calendar.current.startOfDay(for: Date())
        for var sub in subscriptions {
            let due = Calendar.current.startOfDay(for: sub.renewalDate)
            
            // Schedule notifications only - do NOT automatically update renewal dates
            // Users must manually confirm renewals
            switch sub.renewalPreference {
            case .autoRenew:
                // schedule soft reminder on renewal day
                NotificationsManager.cancelReminder(for: sub)
                NotificationsManager.scheduleSoftRenewalDay(for: sub)
                // Don't automatically update renewal date - user must confirm
                if today >= due && sub.status == .active {
                    // Mark as needing update when past due (but don't auto-update the date)
                    sub.status = .pendingDecision
                    Task { try? await self.updateSubscription(sub) }
                }
            case .askMeFirst:
                // schedule 3-day prior reminder
                NotificationsManager.cancelReminder(for: sub)
                NotificationsManager.scheduleAskMeFirstReminder(for: sub)
                if today >= due {
                    if sub.status != .active { continue }
                    // Mark as needing update when past due
                    sub.status = .pendingDecision
                    Task { try? await self.updateSubscription(sub) }
                }
            case .oneTimeTrial:
                // schedule 1-day prior reminder
                NotificationsManager.cancelReminder(for: sub)
                NotificationsManager.scheduleOneTimeEndingReminder(for: sub)
                if today >= due {
                    // Mark trial as ended when past due
                    sub.status = .ended
                    Task { try? await self.updateSubscription(sub) }
                }
            }
        }
    }

    func confirmRenewal(for subscriptionId: String) {
        guard var sub = subscriptions.first(where: { $0.id == subscriptionId }) else { return }
        
        // Allow renewal confirmation for any subscription that is past due or pending
        // Only proceed if pending decision or on/after due date
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: sub.renewalDate)
        
        // Skip one-time trials - they should remain ended
        guard sub.renewalPreference != .oneTimeTrial else { return }
        
        if today >= due || sub.status == .pendingDecision {
            // Manually update renewal date only after user confirmation
            sub.renewalDate = sub.billingCycle.calculateRenewalDate(from: sub.renewalDate)
            sub.status = .active
            NotificationsManager.cancelReminder(for: sub)
            
            // Schedule appropriate reminder based on renewal preference
            switch sub.renewalPreference {
            case .autoRenew:
                NotificationsManager.scheduleSoftRenewalDay(for: sub)
            case .askMeFirst:
                NotificationsManager.scheduleAskMeFirstReminder(for: sub)
            case .oneTimeTrial:
                break // Should not reach here due to guard above
            }
            
            Task { try? await self.updateSubscription(sub) }
        }
    }

    func declineRenewal(for subscriptionId: String) {
        guard var sub = subscriptions.first(where: { $0.id == subscriptionId }) else { return }
        
        // Allow cancellation for any past due or pending subscription
        // Mark as cancelled when user declines renewal
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: sub.renewalDate)
        
        // Only process if past due or pending
        if today >= due || sub.status == .pendingDecision {
            // Skip one-time trials - they should remain ended, not cancelled
            if sub.renewalPreference != .oneTimeTrial {
                sub.status = .canceled
            }
            NotificationsManager.cancelReminder(for: sub)
            Task { try? await self.updateSubscription(sub) }
        }
    }
    
    // MARK: - Budget Management
    func updateBudget(_ budget: Double) {
        monthlyBudget = budget
        // Save to UserDefaults for persistence
        UserDefaults.standard.set(budget, forKey: "monthlyBudget")
    }
    
    func loadBudget() {
        monthlyBudget = UserDefaults.standard.double(forKey: "monthlyBudget")
    }
    
    // MARK: - Activity Tracking
    private func addActivity(_ activity: ActivityItem) {
        print("🔍 DataManager: Adding activity - \(activity.type.rawValue) for \(activity.subscriptionName)")
        DispatchQueue.main.async {
            self.activities.insert(activity, at: 0)
            print("🔍 DataManager: Total activities now: \(self.activities.count)")
            // Keep only last 50 activities
            if self.activities.count > 50 {
                self.activities = Array(self.activities.prefix(50))
            }
        }
    }
    
    private func trackSubscriptionAdded(_ subscription: Subscription) {
        guard let user = currentUser else { return }
        let activity = ActivityItem(
            id: UUID().uuidString,
            type: .added,
            subscriptionName: subscription.name,
            amount: subscription.price,
            date: Date(),
            userId: user.id
        )
        addActivity(activity)
    }
    
    private func trackSubscriptionUpdated(_ subscription: Subscription) {
        guard let user = currentUser else { return }
        let activity = ActivityItem(
            id: UUID().uuidString,
            type: .updated,
            subscriptionName: subscription.name,
            amount: subscription.price,
            date: Date(),
            userId: user.id
        )
        addActivity(activity)
    }
    
    private func trackSubscriptionDeleted(_ subscription: Subscription) {
        guard let user = currentUser else { return }
        let activity = ActivityItem(
            id: UUID().uuidString,
            type: .deleted,
            subscriptionName: subscription.name,
            amount: subscription.price,
            date: Date(),
            userId: user.id
        )
        addActivity(activity)
    }

    func addSubscription(_ sub: Subscription) async throws {
        try await firebase.addSubscription(sub)
        trackSubscriptionAdded(sub)
    }

    func updateSubscription(_ sub: Subscription) async throws {
        try await firebase.updateSubscription(sub)
        trackSubscriptionUpdated(sub)
    }

    func deleteSubscription(_ sub: Subscription) async throws {
        print("DataManager: Attempting to delete subscription \(sub.id)")
        print("DataManager: Current user ID: \(currentUser?.id ?? "nil")")
        print("DataManager: Subscription owner ID: \(sub.ownerId)")
        print("DataManager: Is authenticated: \(isAuthenticated)")
        
        try await firebase.deleteSubscription(id: sub.id)
        trackSubscriptionDeleted(sub)
    }

    // MARK: - Directory
    private func loadServiceDirectory() {
        guard let url = Bundle.main.url(forResource: "services", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([ServiceDirectoryItem].self, from: data)
            serviceDirectory = items
        } catch {
            // Swallow to avoid blocking app start if file missing
        }
    }

    func lookupService(named name: String) -> ServiceDirectoryItem? {
        serviceDirectory.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
    
    // MARK: - Gmail Sync
    private let gmailSync = GmailSyncService()
    
    func syncAllGmailConnections() async throws {
        guard let user = currentUser else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Sync each email connection independently
        for var connection in user.emailConnections {
            do {
                // Sync this connection
                let result = try await syncGmailConnection(connection)
                
                // Update access token if refreshed
                if let newAccessToken = result.newAccessToken {
                    connection.accessToken = newAccessToken
                    connection.lastSync = Date()
                    
                    // Update connection in Firestore
                    try await firebase.updateEmailConnection(connection, for: user.id)
                }
            } catch {
                print("Error syncing connection \(connection.emailAddress): \(error)")
                // Mark as expired if refresh failed
                if let gmailError = error as? GmailSyncError,
                   case .tokenRefreshFailed = gmailError {
                    // Connection will be marked as expired on next load
                }
            }
        }
    }
    
    private func syncGmailConnection(_ connection: EmailConnection) async throws -> GmailSyncResult {
        // Sync Gmail
        let syncResult = try await gmailSync.syncGmail(connection: connection)
        
        // Parse messages and create/update subscriptions
        // Note: This is a placeholder - actual parsing would happen in GmailSyncService
        // The real implementation would fetch messages, parse them, and create subscriptions
        
        return syncResult
    }
    
    // MARK: - Deduping
    private func generateSubscriptionHash(merchant: String, price: Double, frequency: String) -> String {
        return GmailSyncService.generateSubscriptionHash(merchant: merchant, price: price, frequency: frequency)
    }
    
    func addOrUpdateSubscriptionFromEmail(merchant: String, price: Double, frequency: String, billingDate: Date?) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Generate hash for deduping
        let hash = generateSubscriptionHash(merchant: merchant, price: price, frequency: frequency)
        
        // Check if subscription with this hash already exists
        let existingSubscription = subscriptions.first { sub in
            // For now, check by name and price - in a full implementation, we'd store the hash
            sub.name.lowercased() == merchant.lowercased() && abs(sub.price - price) < 0.01
        }
        
        if let existing = existingSubscription {
            // Update existing subscription
            var updated = existing
            updated.price = price
            // Update other fields as needed
            
            try await updateSubscription(updated)
        } else {
            // Create new subscription
            // Map frequency string to BillingCycle
            let billingCycle: BillingCycle = {
                switch frequency.lowercased() {
                case "yearly", "annual": return .yearly
                case "quarterly": return .quarterly
                case "weekly": return .weekly
                default: return .monthly
                }
            }()
            
            let renewalDate = billingDate ?? billingCycle.calculateRenewalDate(from: Date())
            
            let newSubscription = Subscription(
                id: UUID().uuidString,
                name: merchant,
                price: price,
                renewalDate: renewalDate,
                startDate: billingDate ?? Date(),
                category: .other,
                ownerId: user.id,
                billingCycle: billingCycle
            )
            
            try await addSubscription(newSubscription)
        }
    }
    
    // TEMPORARY: For testing purposes only
    func skipAuthenticationForTesting() {
        let mockUser = SlashUser(
            id: "test-user",
            email: "test@example.com",
            displayName: "Test User",
            profileImageURL: nil,
            firstName: "Test",
            lastName: "User",
            provider: .email,
            emailConnections: []
        )
        
        DispatchQueue.main.async {
            self.currentUser = mockUser
            self.isAuthenticated = true
        }
    }
}

