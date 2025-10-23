import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

final class FirebaseService {
    private let authStateSubject = CurrentValueSubject<SlashUser?, Never>(nil)
    var authStatePublisher: AnyPublisher<SlashUser?, Never> { authStateSubject.eraseToAnyPublisher() }
    
    private let db = Firestore.firestore()
    private var subscriptionsListener: ListenerRegistration?

    func configure() {
        // FirebaseApp.configure() is now called in SlashApp.init()
        
        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        // Listen to auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                let slashUser = SlashUser(
                    id: user.uid,
                    email: user.email ?? "",
                    displayName: user.displayName ?? "",
                    profileImageURL: user.photoURL?.absoluteString,
                    firstName: user.displayName?.components(separatedBy: " ").first,
                    lastName: user.displayName?.components(separatedBy: " ").dropFirst().joined(separator: " "),
                    provider: self?.getAuthProvider(from: user)
                )
                self?.authStateSubject.send(slashUser)
            } else {
                self?.authStateSubject.send(nil)
            }
        }
    }

    // MARK: - Auth
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        // Auth state listener will handle updating the subject
    }

    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Auth state listener will handle updating the subject
    }


    func signInWithGoogle() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
                        continuation.resume(throwing: NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No presenting view controller"]))
                        return
                    }
                    
                    guard let clientID = FirebaseApp.app()?.options.clientID else {
                        continuation.resume(throwing: NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No client ID found"]))
                        return
                    }
                    
                    // Configure Google Sign-In
                    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                    
                    // Add some debugging
                    print("Starting Google Sign-In with client ID: \(clientID)")
                    print("Presenting view controller: \(presentingViewController)")
                    
                    // Check if Google Sign-In is properly configured
                    guard GIDSignIn.sharedInstance.configuration != nil else {
                        throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not properly configured"])
                    }
                    
                    // Always prompt for account selection to allow switching accounts
                    print("Starting Google Sign-In with account selection")
                    
                    do {
                        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
                        guard let idToken = result.user.idToken?.tokenString else {
                            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google"])
                        }
                        
                        let accessToken = result.user.accessToken.tokenString
                        
                        // Create Firebase credential using the ID token and access token
                        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                        
                        // Sign in to Firebase with the Google credential
                        let authResult = try await Auth.auth().signIn(with: credential)
                        continuation.resume()
                    } catch {
                        print("Google Sign-In failed with error: \(error)")
                        // Check if it's a SafariViewService error
                        if error.localizedDescription.contains("SafariViewService") || 
                           error.localizedDescription.contains("Security") ||
                           error.localizedDescription.contains("not trusted") {
                            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In is not available on this device. Please try Apple Sign-In or email/password authentication instead."])
                        } else {
                            throw error
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        
        // Clear Google Sign-In cache to allow switching accounts
        GIDSignIn.sharedInstance.signOut()
        
        // Auth state listener will handle updating the subject
        subscriptionsListener?.remove()
        subscriptionsListener = nil
    }

    // MARK: - Subscriptions
    func subscriptionsPublisher() -> AnyPublisher<[Subscription], Never> {
        let subject = PassthroughSubject<[Subscription], Never>()
        
        // Remove any existing listener
        subscriptionsListener?.remove()
        
        guard let currentUser = Auth.auth().currentUser else {
            subject.send([])
            subject.send(completion: .finished)
            return subject.eraseToAnyPublisher()
        }
        
        print("Starting subscriptions listener for user: \(currentUser.uid)")
        
        subscriptionsListener = db.collection("subscriptions")
            .whereField("ownerId", isEqualTo: currentUser.uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching subscriptions: \(error)")
                    print("Error details: \(error.localizedDescription)")
                    subject.send([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in subscriptions collection")
                    subject.send([])
                    return
                }
                
                print("Found \(documents.count) subscription documents")
                let subscriptions = documents.compactMap { doc -> Subscription? in
                    do {
                        let subscription = try doc.data(as: Subscription.self)
                        print("Loaded subscription: \(subscription.name) (owner: \(subscription.ownerId))")
                        return subscription
                    } catch {
                        print("Error parsing subscription document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                print("Successfully loaded \(subscriptions.count) subscriptions")
                subject.send(subscriptions)
            }
        
        return subject.eraseToAnyPublisher()
    }

    func addSubscription(_ sub: Subscription) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var subscription = sub
        subscription.ownerId = currentUser.uid
        
        print("=== ADD SUBSCRIPTION DEBUG ===")
        print("Adding subscription for user: \(currentUser.uid)")
        print("Subscription ID from app: \(subscription.id)")
        print("Subscription name: \(subscription.name)")
        print("Subscription owner: \(subscription.ownerId)")
        
        // Use setData with the specific document ID instead of addDocument
        try db.collection("subscriptions").document(subscription.id).setData(from: subscription)
        print("Successfully added subscription with ID: \(subscription.id)")
        print("=== ADD SUBSCRIPTION END ===")
    }

    func updateSubscription(_ sub: Subscription) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("Updating subscription \(sub.id) for user: \(currentUser.uid)")
        print("Subscription owner: \(sub.ownerId)")
        
        // Ensure the ownerId is set correctly
        var updatedSub = sub
        updatedSub.ownerId = currentUser.uid
        
        try db.collection("subscriptions").document(sub.id).setData(from: updatedSub)
        print("Successfully updated subscription")
    }

    func deleteSubscription(id: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        print("=== DELETE DEBUG INFO ===")
        print("Attempting to delete subscription \(id)")
        print("Current user ID: \(currentUser.uid)")
        print("Current user email: \(currentUser.email ?? "no email")")
        print("User is authenticated: \(Auth.auth().currentUser != nil)")
        
        // First, let's try to read the document to check ownership
        do {
            let doc = try await db.collection("subscriptions").document(id).getDocument()
            if doc.exists {
                let data = doc.data()
                print("Document exists. Owner ID in document: \(data?["ownerId"] as? String ?? "nil")")
                print("Current user ID: \(currentUser.uid)")
                print("Ownership matches: \(data?["ownerId"] as? String == currentUser.uid)")
                print("Full document data: \(data ?? [:])")
            } else {
                print("Document does not exist!")
                print("Let's check if there are any documents with similar IDs...")
                
                // Let's also check what documents actually exist
                let query = db.collection("subscriptions").whereField("ownerId", isEqualTo: currentUser.uid)
                let snapshot = try await query.getDocuments()
                print("Found \(snapshot.documents.count) documents for this user:")
                for doc in snapshot.documents {
                    print("  - Document ID: \(doc.documentID)")
                    let data = doc.data()
                    print("    Name: \(data["name"] as? String ?? "unknown")")
                    print("    Owner: \(data["ownerId"] as? String ?? "unknown")")
                }
            }
        } catch {
            print("Error reading document before delete: \(error)")
        }
        
        print("Attempting delete operation...")
        
        // Let's try a different approach - delete by query instead of by document ID
        do {
            let query = db.collection("subscriptions").whereField("ownerId", isEqualTo: currentUser.uid)
            let snapshot = try await query.getDocuments()
            
            print("Found \(snapshot.documents.count) documents for this user:")
            for doc in snapshot.documents {
                let data = doc.data()
                let docId = doc.documentID
                let name = data["name"] as? String ?? "unknown"
                let owner = data["ownerId"] as? String ?? "unknown"
                
                print("  - Document ID: \(docId)")
                print("    Name: \(name)")
                print("    Owner: \(owner)")
                print("    Matches target ID \(id): \(docId == id)")
            }
            
            // Try to find and delete the document with matching ID
            if let targetDoc = snapshot.documents.first(where: { $0.documentID == id }) {
                print("Found matching document, attempting delete...")
                try await db.collection("subscriptions").document(id).delete()
                print("Successfully deleted subscription \(id)")
            } else {
                print("ERROR: No document found with ID \(id)")
                print("Available document IDs:")
                for doc in snapshot.documents {
                    print("  - \(doc.documentID)")
                }
            }
        } catch {
            print("Error during delete operation: \(error)")
            throw error
        }
        
        print("=== DELETE DEBUG END ===")
    }
    
    // MARK: - Helper Functions
    private func getAuthProvider(from user: FirebaseAuth.User) -> AuthProvider {
        // Check if user signed in with Google
        if let providerData = user.providerData.first(where: { $0.providerID == "google.com" }) {
            return .google
        }
        // Check if user signed in with Apple
        else if let providerData = user.providerData.first(where: { $0.providerID == "apple.com" }) {
            return .apple
        }
        // Default to email/password
        else {
            return .email
        }
    }
    

}



