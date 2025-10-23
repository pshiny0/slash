# Firebase Setup Guide for Slash

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "Slash" (or your preferred name)
4. Disable Google Analytics for now (you can enable later)
5. Click "Create project"

## Step 2: Add iOS App to Firebase Project

1. In your Firebase project dashboard, click "Add app" and select iOS
2. Enter your iOS bundle ID: `com.example.slash`
3. Enter app nickname: "Slash"
4. Click "Register app"

## Step 3: Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file
2. Replace the template file in your project:
   ```bash
   cp ~/Downloads/GoogleService-Info.plist /Users/shinypidugu/Projects/Slash/Resources/
   ```

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable "Email/Password" authentication:
   - Click on "Email/Password"
   - Toggle "Enable"
   - Click "Save"

## Step 5: Set up Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location closest to you
5. Click "Done"

## Step 6: Update Firestore Security Rules

Replace the default rules with these (go to Firestore → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own subscriptions
    match /subscriptions/{subscriptionId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.ownerId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.ownerId;
    }
  }
}
```

## Step 7: Regenerate Xcode Project

```bash
cd /Users/shinypidugu/Projects/Slash
xcodegen generate
```

## Step 8: Test the App

1. Open `Slash.xcodeproj` in Xcode
2. Build and run the app
3. Try creating an account with email/password
4. The app should now work with real Firebase authentication!

## Optional: Enable Additional Sign-in Methods

### Apple Sign-In
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Apple"
3. Follow the setup instructions

### Google Sign-In
1. In Firebase Console → Authentication → Sign-in method  
2. Enable "Google"
3. Add your iOS app's bundle ID
4. Download the updated GoogleService-Info.plist

## Troubleshooting

- **Build errors**: Make sure you've downloaded the correct GoogleService-Info.plist
- **Authentication not working**: Check that Email/Password is enabled in Firebase Console
- **Database errors**: Verify Firestore rules allow your user to read/write data

## Next Steps

- Add Apple Sign-In and Google Sign-In implementations
- Set up proper Firestore security rules for production
- Add error handling and user feedback
- Implement subscription management features
