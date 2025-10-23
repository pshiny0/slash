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
    private let firebase = FirebaseService()
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

    // MARK: - Subscriptions
    private func startSubscriptionsListener() {
        firebase.subscriptionsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subs in
                self?.subscriptions = subs
            }
            .store(in: &cancellables)
    }
    
    func refreshSubscriptions() {
        // Cancel existing listener and restart it to force refresh
        cancellables.removeAll()
        startSubscriptionsListener()
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
    
    // TEMPORARY: For testing purposes only
    func skipAuthenticationForTesting() {
        let mockUser = SlashUser(
            id: "test-user",
            email: "test@example.com",
            displayName: "Test User",
            profileImageURL: nil,
            firstName: "Test",
            lastName: "User",
            provider: .email
        )
        
        DispatchQueue.main.async {
            self.currentUser = mockUser
            self.isAuthenticated = true
        }
    }
}


