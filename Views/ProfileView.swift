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
    @State private var showingSmartImport = false
    @State private var showingPersonalDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.selectedTheme.primary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    AppTopSection(contentSpacing: 0) {
                        AppScreenTitle(title: "Profile")
                    } content: {
                        EmptyView()
                    }
                    .padding(.bottom, 10)
                    .background(themeManager.selectedTheme.primary)

                    List {
                        Section {
                            ProfileHeaderView()
                        }

                        Section("Settings") {
                            settingsRow(title: "Personal details") {
                                showingPersonalDetails = true
                            }

                            settingsRow(title: "Theme", value: themeManager.selectedTheme.name) {
                                showingThemePicker = true
                            }

                            settingsRow(title: "App Icon", value: appIconManager.currentIcon.displayName) {
                                showingAppIconPicker = true
                            }

                            settingsRow(title: "Notifications") {
                                showingNotificationsSettings = true
                            }

                            settingsRow(title: "Privacy & Security") {
                                showingPrivacySettings = true
                            }

                            settingsRow(
                                title: "Monthly Budget",
                                value: dataManager.monthlyBudget > 0 ? "$\(Int(dataManager.monthlyBudget))" : nil
                            ) {
                                showingBudgetSettings = true
                            }

                            settingsRow(title: "Smart Import") {
                                showingSmartImport = true
                            }

                            settingsRow(title: "Help & Support") {
                                // TODO: Implement help & support
                            }
                        }

                        Section("Account") {
                            Button(role: .destructive) {
                                showingSignOutAlert = true
                            } label: {
                                Text("Sign Out")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
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
        .sheet(isPresented: $showingPersonalDetails) {
            PersonalDetailsView()
                .environmentObject(themeManager)
                .environmentObject(dataManager)
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
        .sheet(isPresented: $showingSmartImport) {
            SmartImportView()
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
        HStack(spacing: 16) {
            Group {
                if let profileImageURL = dataManager.currentUser?.profileImageURL,
                   !profileImageURL.isEmpty,
                   let url = URL(string: profileImageURL) {
                    CachedImageView(url: url) {
                        AnyView(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        )
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let email = dataManager.currentUser?.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
    private func settingsRow(title: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LabeledContent {
                HStack(spacing: 8) {
                    if let value {
                        Text(value)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            } label: {
                Text(title)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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

struct PersonalDetailsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("First name", text: $firstName)
                    TextField("Last name", text: $lastName)
                    TextField("Display name", text: $displayName)
                }

                if let email = dataManager.currentUser?.email, !email.isEmpty {
                    Section("Email") {
                        LabeledContent("Email", value: email)
                    }
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.selectedTheme.primary.ignoresSafeArea())
            .navigationTitle("Personal details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await saveDetails()
                        }
                    }
                    .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                let user = dataManager.currentUser
                firstName = user?.firstName ?? ""
                lastName = user?.lastName ?? ""
                displayName = user?.displayName ?? "User"
            }
        }
    }

    @MainActor
    private func saveDetails() async {
        isSaving = true
        errorMessage = nil

        do {
            try await dataManager.updateCurrentUserProfile(
                displayName: displayName,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
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
        .environmentObject(ThemeManager())
        .environmentObject(AppIconManager())
}
