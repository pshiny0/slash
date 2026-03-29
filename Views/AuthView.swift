import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var isGoogleLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showEmailAuth: Bool = false
    @State private var showPasswordReset: Bool = false

    var body: some View {
        ZStack {
            GradientBackground()
                .environmentObject(themeManager)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 24) {
                        Spacer(minLength: 60)
                        
                        // Logo and Welcome
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.selectedTheme.accent.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Text("slash")
                                    .font(.tanTangkiwood(size: 32))
                                    .foregroundColor(themeManager.selectedTheme.accent)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome to Slash")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                
                                Text("Manage your subscriptions with ease")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .frame(minHeight: 300)
                    
                    // Auth Form Section
                    VStack(spacing: 24) {
                        if showEmailAuth {
                            // Email Authentication Form
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text(isSignUp ? "Create Account" : "Sign In")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button(action: { showEmailAuth = false }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                                .font(.title2)
                                        }
                                    }
                                    
                                    if let errorMessage {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(themeManager.selectedTheme.error)
                                            Text(errorMessage)
                                                .font(.caption)
                                                .foregroundColor(themeManager.selectedTheme.error)
                                        }
                                        .padding()
                                        .background(themeManager.selectedTheme.error.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(spacing: 16) {
                                        ModernTextField(
                                            placeholder: "Email address",
                                            text: $email,
                                            keyboardType: .emailAddress
                                        )
                                        
                                        ModernTextField(
                                            placeholder: "Password",
                                            text: $password,
                                            isSecure: true
                                        )
                                        
                                        if isSignUp {
                                            ModernTextField(
                                                placeholder: "Display name",
                                                text: $displayName
                                            )
                                        }
                                    }
                                    
                                    VStack(spacing: 12) {
                                        ModernButton(
                                            title: isLoading ? "Please wait..." : (isSignUp ? "Create Account" : "Sign In"),
                                            action: handleEmailAuth,
                                            style: .primary
                                        )
                                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                                        
                                        if !isSignUp {
                                            Button(action: { showPasswordReset = true }) {
                                                Text("Forgot Password?")
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.selectedTheme.accent)
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                        .background(themeManager.selectedTheme.textSecondary.opacity(0.3))
                                    
                                    Button(action: toggleMode) {
                                        HStack {
                                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                                .font(.caption)
                                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                            
                                            Text(isSignUp ? "Sign In" : "Sign Up")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(themeManager.selectedTheme.accent)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Main Authentication Options
                            VStack(spacing: 24) {
                                // Google Sign In Button
                                Button(action: handleGoogle) {
                                    HStack(spacing: 12) {
                                        if isGoogleLoading {
                                            ProgressView()
                                                .tint(themeManager.selectedTheme.textPrimary)
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "globe")
                                                .font(.system(size: 18, weight: .medium))
                                        }
                                        
                                        Text("Continue with Google")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(themeManager.selectedTheme.cardBackground)
                                    .cornerRadius(12)
                                    .shadow(
                                        color: themeManager.selectedTheme.textPrimary.opacity(0.05),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                                }
                                .disabled(isGoogleLoading)
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(themeManager.selectedTheme.textSecondary.opacity(0.3))
                                        .frame(height: 1)
                                    
                                    Text("or")
                                        .font(.caption)
                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(themeManager.selectedTheme.textSecondary.opacity(0.3))
                                        .frame(height: 1)
                                }
                                
                                // Email Sign In Button
                                Button(action: { showEmailAuth = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 18, weight: .medium))
                                        
                                        Text("Continue with Email")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(themeManager.selectedTheme.cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(themeManager.selectedTheme.accent)
                                    .cornerRadius(12)
                                }
                                
                                // Skip Sign In (Testing)
                                Button(action: handleSkipSignIn) {
                                    Text("Skip Sign In (Testing)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        .underline()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 5)
                }
            }
        }
        // Follow app/system choice; do not force color scheme here
        .alert("Reset Password", isPresented: $showPasswordReset) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            
            Button("Send Reset Email") {
                // TODO: Implement password reset
                showPasswordReset = false
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
    }

    private func toggleMode() { isSignUp.toggle() }

    private func handleEmailAuth() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                if isSignUp {
                    try await dataManager.signUpWithEmail(email: email, password: password, displayName: displayName)
                } else {
                    try await dataManager.signInWithEmail(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    
    private func handleGoogle() {
        errorMessage = nil
        isGoogleLoading = true
        Task {
            do {
                try await dataManager.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
            isGoogleLoading = false
        }
    }
    
    // TEMPORARY: Skip sign in for testing
    private func handleSkipSignIn() {
        // This will bypass authentication and go directly to the main app
        dataManager.skipAuthenticationForTesting()
    }
}

#Preview {
    AuthView()
        .environmentObject(DataManager())
        .environmentObject(ThemeManager())
}
