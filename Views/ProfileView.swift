import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var appIconManager: AppIconManager
    @State private var showingSignOutAlert = false
    @State private var showingThemePicker = false
    @State private var showingAppIconPicker = false
    @State private var displayName: String = "User"
    @State private var showingNotificationsSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingBudgetSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: 0).id("top")
                        // Header
                        VStack(spacing: 16) {
                            HStack {
                                Text("Profile")
                                    .font(.tanTangkiwood(size: 36))
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, -16)
                        
                        // Profile Header Card
                        ModernCard {
                            ProfileHeaderView()
                        }
                        .padding(.horizontal)
                        
                        // User Stats Card
                        ModernCard {
                            UserStatsSection()
                        }
                        .padding(.horizontal)
                        
                        // Settings Cards
                        ModernCard {
                            SettingsSection()
                        }
                        .padding(.horizontal)
                        
                        // Account Actions Card
                        ModernCard {
                            AccountActionsSection()
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 5)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .slashTabChanged)) { _ in
                    withAnimation(.easeInOut) { proxy.scrollTo("top", anchor: .top) }
                }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                updateDisplayName()
                configureScrollbarAppearance()
            }
            .onChange(of: dataManager.currentUser) { _ in
                updateDisplayName()
            }
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingAppIconPicker) {
            AppIconPickerView()
                .environmentObject(themeManager)
                .environmentObject(appIconManager)
        }
        .sheet(isPresented: $showingNotificationsSettings) {
            NotificationsSettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingBudgetSettings) {
            BudgetSettingsView()
                .environmentObject(themeManager)
                .environmentObject(dataManager)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                do {
                    try dataManager.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    @ViewBuilder
    private func ProfileHeaderView() -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(themeManager.selectedTheme.accent)
                        .font(.title2)
                }
            }
            
            HStack(spacing: 16) {
                // Profile Avatar
                Group {
                    if let profileImageURL = dataManager.currentUser?.profileImageURL,
                       !profileImageURL.isEmpty,
                       let url = URL(string: profileImageURL) {
                        CachedImageView(url: url) {
                            AnyView(
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                    .font(.system(size: 60))
                            )
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(themeManager.selectedTheme.accent)
                            .font(.system(size: 60))
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(themeManager.selectedTheme.accent, lineWidth: 3)
                )
                
                // User Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Text(dataManager.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                        
                        Text(memberSince)
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func UserStatsSection() -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Account Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItemView(
                    icon: "creditcard.fill",
                    title: "Subscriptions",
                    value: "\(dataManager.subscriptions.count)",
                    color: themeManager.selectedTheme.accent
                )
                
                StatItemView(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly Cost",
                    value: monthlyCostText,
                    color: themeManager.selectedTheme.success
                )
                
                StatItemView(
                    icon: "calendar.circle.fill",
                    title: "Active Since",
                    value: "Oct 2024",
                    color: themeManager.selectedTheme.warning
                )
            }
        }
    }
    
    @ViewBuilder
    private func SettingsSection() -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernSettingsRow(
                    icon: "paintbrush.fill",
                    title: "Theme",
                    subtitle: themeManager.selectedTheme.name,
                    color: themeManager.selectedTheme.accent
                ) {
                    showingThemePicker = true
                }
                
                ModernSettingsRow(
                    icon: "app.fill",
                    title: "App Icon",
                    subtitle: appIconManager.currentIcon.displayName,
                    color: themeManager.selectedTheme.warning
                ) {
                    showingAppIconPicker = true
                }
                
                ModernSettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage notification preferences",
                    color: themeManager.selectedTheme.warning
                ) {
                    showingNotificationsSettings = true
                }
                
                ModernSettingsRow(
                    icon: "lock.fill",
                    title: "Privacy & Security",
                    subtitle: "Manage your privacy settings",
                    color: themeManager.selectedTheme.error
                ) {
                    showingPrivacySettings = true
                }
                
                ModernSettingsRow(
                    icon: "dollarsign.circle.fill",
                    title: "Monthly Budget",
                    subtitle: dataManager.monthlyBudget > 0 ? "$\(Int(dataManager.monthlyBudget))" : "Set your monthly budget",
                    color: themeManager.selectedTheme.success
                ) {
                    showingBudgetSettings = true
                }
                
                ModernSettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    color: themeManager.selectedTheme.accent
                ) {
                    // TODO: Implement help & support
                }
            }
        }
    }
    
    @ViewBuilder
    private func AccountActionsSection() -> some View {
        VStack(spacing: 20) {
            HStack {
                Text("Account Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(themeManager.selectedTheme.error)
                        
                        Text("Sign Out")
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.selectedTheme.error)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(themeManager.selectedTheme.error.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var monthlyCostText: String {
        let total = dataManager.subscriptions.reduce(into: 0.0) { total, subscription in
            total += subscription.price
        }
        return String(format: "$%.2f", total)
    }
    
    private func updateDisplayName() {
        if let user = dataManager.currentUser {
            let fullName = user.displayName
            if !fullName.isEmpty {
                displayName = fullName
                return
            }
        }
        displayName = "User"
    }
    
    private var memberSince: String {
        // For now, return a placeholder. In the future, this could come from user metadata
        return "October 2024"
    }
    
    private func configureScrollbarAppearance() {
        // Configure scrollbar appearance based on theme
        if themeManager.selectedTheme.name.contains("Dark") {
            // Light scrollbar for dark theme
            UIScrollView.appearance().indicatorStyle = .white
        } else {
            // Dark scrollbar for light theme
            UIScrollView.appearance().indicatorStyle = .black
        }
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModernSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationsSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Notifications Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                            .padding(.top)
                        
                        Text("Manage your notification preferences")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
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
        }
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Privacy & Security")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                            .padding(.top)
                        
                        Text("Manage your privacy and security settings")
                            .font(.subheadline)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
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
        }
    }
}

struct BudgetSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var budgetAmount: String = ""
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Monthly Budget")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                            
                            Text("Set your monthly spending limit to track your subscription expenses")
                                .font(.subheadline)
                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Budget Input Card
                        ModernCard {
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Budget Amount")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("$")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    TextField("0", text: $budgetAmount)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        .onTapGesture {
                                            isEditing = true
                                        }
                                }
                                
                                if dataManager.monthlyBudget > 0 {
                                    HStack {
                                        Text("Current: $\(Int(dataManager.monthlyBudget))")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        
                                        Spacer()
                                        
                                        Button("Clear") {
                                            dataManager.updateBudget(0)
                                            budgetAmount = ""
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.selectedTheme.error)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Current Spending Info
                        if dataManager.monthlyBudget > 0 {
                            ModernCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Current Spending")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    let currentSpending = dataManager.subscriptions.reduce(0.0) { $0 + $1.price }
                                    let percentage = currentSpending / dataManager.monthlyBudget
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("$\(Int(currentSpending))")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                                            
                                            Text("of $\(Int(dataManager.monthlyBudget))")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(Int(percentage * 100))%")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(percentage > 1.0 ? themeManager.selectedTheme.error : themeManager.selectedTheme.success)
                                            
                                            Text("used")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                        }
                                    }
                                    
                                    // Progress bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(themeManager.selectedTheme.secondary)
                                                .frame(height: 8)
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(percentage > 1.0 ? themeManager.selectedTheme.error : themeManager.selectedTheme.success)
                                                .frame(width: geometry.size.width * min(percentage, 1.0), height: 8)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let amount = Double(budgetAmount), amount >= 0 {
                            dataManager.updateBudget(amount)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.accent)
                    .disabled(budgetAmount.isEmpty || Double(budgetAmount) == nil)
                }
            }
        }
        .onAppear {
            if dataManager.monthlyBudget > 0 {
                budgetAmount = String(Int(dataManager.monthlyBudget))
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(DataManager())
}
