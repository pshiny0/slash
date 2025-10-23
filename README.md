Slash (SwiftUI + Firebase)
=================================

A minimal SwiftUI app to manage and share subscriptions with Firestore backup and offline support.

Features
- SwiftUI, NavigationStack, light/dark
- Firebase Auth (Apple/Google/Email) and Firestore (offline caching)
- Add/Edit/Delete subscriptions, share by email
- Local notification 3 days before renewal
- Service directory with cancel links in `Resources/services.json`

Project Setup
1. Open Xcode and create an iOS App named `Slash` with SwiftUI & Swift concurrency.
2. Add Firebase via Swift Package Manager: `https://github.com/firebase/firebase-ios-sdk`
   - Add: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift, FirebaseCore
3. Add GoogleSignIn via SPM: `https://github.com/google/GoogleSignIn-iOS`
4. Enable Sign in with Apple capability.
5. Download `GoogleService-Info.plist` from Firebase console and add to the target.
6. In `FirebaseService`, replace stubs with real Firebase calls and enable Firestore persistence.

Firestore structure
- `users/{userId}`: { userId, email, displayName }
- `subscriptions/{subscriptionId}`: { name, price, renewalDate, category, ownerId, cancelLink, sharedWith[] }

Offline
Firestore offline is enabled via settings; listeners will sync when online.

Notifications
Request permission at startup and schedule per-subscription reminders.

Notes
- Email-to-userId resolution for sharing is stubbed.
- Email inbox scanning is out-of-scope in this starter; integrate Mail APIs if desired.

