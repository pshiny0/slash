import SwiftUI
import GoogleSignIn
import FirebaseCore
import UIKit

struct SmartImportView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var emailConnections: [EmailConnection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingAddEmail = false
    @State private var subscriptionCounts: [UUID: Int] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Smart Import")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                                .padding(.top)
                            
                            Text("Automatically import subscriptions from your Gmail accounts")
                                .font(.subheadline)
                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        // Connected Accounts Card
                        ModernCard {
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Connected Accounts")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                if emailConnections.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "envelope.badge")
                                            .font(.system(size: 40))
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        
                                        Text("No email accounts connected")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        
                                        Button(action: {
                                            showingAddEmail = true
                                        }) {
                                            Text("Add Email Account")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(themeManager.selectedTheme.accent)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(emailConnections) { connection in
                                            EmailConnectionRow(
                                                connection: connection,
                                                subscriptionCount: subscriptionCounts[connection.id],
                                                onReconnect: {
                                                    await reconnectConnection(connection)
                                                },
                                                onRemove: {
                                                    await removeConnection(connection)
                                                }
                                            )
                                            .environmentObject(themeManager)
                                            
                                            if connection.id != emailConnections.last?.id {
                                                Divider()
                                                    .background(themeManager.selectedTheme.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add Email Button
                        if !emailConnections.isEmpty {
                            Button(action: {
                                showingAddEmail = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Email Account")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.selectedTheme.accent)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
            .sheet(isPresented: $showingAddEmail) {
                AddEmailAccountView(onEmailAdded: {
                    await loadEmailConnections()
                })
                .environmentObject(themeManager)
                .environmentObject(dataManager)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .task {
                await loadEmailConnections()
            }
        }
    }
    
    private func loadEmailConnections() async {
        guard let user = dataManager.currentUser else { return }
        
        // Load from current user (already loaded via auth state)
        emailConnections = user.emailConnections
    }
    
    private func reconnectConnection(_ connection: EmailConnection) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Re-authenticate with Google
            guard let presentingViewController = await getPresentingViewController() else {
                errorMessage = "Unable to present authentication"
                showingError = true
                return
            }
            
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "No client ID found"
                showingError = true
                return
            }
            
            // Configure Google Sign-In
            let config = GIDConfiguration(clientID: clientID)
            // Note: GoogleSignIn iOS SDK doesn't directly support additionalScopes in signIn
            // We'll need to request Gmail scope separately or configure OAuth client with the scope
            // For now, use the standard signIn method
            GIDSignIn.sharedInstance.configuration = config
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            // Request additional scopes if needed
            // Note: In production, you'd need to configure your OAuth client to include gmail.readonly scope
            // For now, we'll proceed with the tokens we get
            
            guard let email = result.user.profile?.email else {
                errorMessage = "Failed to get email address"
                showingError = true
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let refreshToken = result.user.refreshToken.tokenString
            
            // Update connection
            var updatedConnection = connection
            updatedConnection.accessToken = accessToken
            updatedConnection.refreshToken = refreshToken
            updatedConnection.lastSync = Date()
            
            try await dataManager.firebase.updateEmailConnection(updatedConnection, for: dataManager.currentUser!.id)
            
            await loadEmailConnections()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func removeConnection(_ connection: EmailConnection) async {
        guard let user = dataManager.currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await dataManager.firebase.deleteEmailConnection(id: connection.id, for: user.id)
            await loadEmailConnections()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    private func getPresentingViewController() async -> UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.rootViewController
            }
        }
        return nil
    }
}

struct EmailConnectionRow: View {
    let connection: EmailConnection
    let subscriptionCount: Int?
    let onReconnect: () async -> Void
    let onRemove: () async -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isReconnecting = false
    @State private var isRemoving = false
    
    var statusText: String {
        connection.status == .valid ? "Valid" : "Expired"
    }
    
    var statusColor: Color {
        connection.status == .valid ? themeManager.selectedTheme.success : themeManager.selectedTheme.error
    }
    
    var lastSyncText: String {
        if let lastSync = connection.lastSync {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: lastSync, relativeTo: Date())
        }
        return "Never"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Email Icon
                ZStack {
                    Circle()
                        .fill(themeManager.selectedTheme.accent.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
                
                // Email Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.emailAddress)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(statusText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.1))
                            .foregroundColor(statusColor)
                            .cornerRadius(4)
                        
                        Text("Last sync: \(lastSyncText)")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                    }
                    
                    if let count = subscriptionCount {
                        Text("\(count) subscriptions found")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                if connection.status == .expired {
                    Button(action: {
                        Task {
                            isReconnecting = true
                            await onReconnect()
                            isReconnecting = false
                        }
                    }) {
                        Text("Reconnect")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.selectedTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeManager.selectedTheme.accent.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .disabled(isReconnecting)
                }
                
                Button(action: {
                    Task {
                        isRemoving = true
                        await onRemove()
                        isRemoving = false
                    }
                }) {
                    Text("Remove")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.selectedTheme.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.selectedTheme.error.opacity(0.1))
                        .cornerRadius(6)
                }
                .disabled(isRemoving)
            }
        }
    }
}

struct AddEmailAccountView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let onEmailAdded: () async -> Void
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.selectedTheme.accent)
                        
                        Text("Connect Gmail Account")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                        
                        Text("We'll securely access your Gmail to automatically detect and import subscription receipts")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await addEmailAccount()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "envelope.fill")
                            }
                            Text(isLoading ? "Connecting..." : "Connect Gmail")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.selectedTheme.accent)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func addEmailAccount() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let presentingViewController = await getPresentingViewController() else {
                errorMessage = "Unable to present authentication"
                showingError = true
                return
            }
            
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "No client ID found"
                showingError = true
                return
            }
            
            // Configure Google Sign-In
            let config = GIDConfiguration(clientID: clientID)
            // Note: GoogleSignIn iOS SDK doesn't directly support additionalScopes in signIn
            // We'll need to configure OAuth client with the scope in Google Cloud Console
            // For now, use the standard signIn method
            GIDSignIn.sharedInstance.configuration = config
            
            // Sign in (Gmail scope should be configured in OAuth client settings)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let email = result.user.profile?.email else {
                errorMessage = "Failed to get email address"
                showingError = true
                return
            }
            
            // Check if already connected
            if let user = dataManager.currentUser,
               user.emailConnections.contains(where: { $0.emailAddress == email }) {
                errorMessage = "This email is already connected"
                showingError = true
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let refreshToken = result.user.refreshToken.tokenString
            
            // Create email connection
            let connection = EmailConnection(
                emailAddress: email,
                provider: "google",
                accessToken: accessToken,
                refreshToken: refreshToken,
                lastSync: nil
            )
            
            // Save to Firestore
            guard let user = dataManager.currentUser else {
                errorMessage = "User not authenticated"
                showingError = true
                return
            }
            
            try await dataManager.firebase.saveEmailConnection(connection, for: user.id)
            
            await onEmailAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    private func getPresentingViewController() async -> UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.rootViewController
            }
        }
        return nil
    }
}

#Preview {
    SmartImportView()
        .environmentObject(DataManager())
        .environmentObject(ThemeManager())
}
