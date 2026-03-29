import SwiftUI

struct SharedView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showShareSheet = false
    @State private var showFamilyInvite = false
    @State private var selectedSubscription: Subscription?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.selectedTheme.primary
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: 0).id("top")
                        AppTopSection {
                            AppScreenTitle(title: "Sharing")
                        } content: {
                            sharingOverviewCard
                        }

                        // Quick Actions
                        ModernCard {
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Quick Actions")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ModernQuickActionCard(
                                        title: "Share Subscription",
                                        icon: "square.and.arrow.up",
                                        color: themeManager.selectedTheme.accent
                                    ) {
                                        showShareSheet = true
                                    }
                                    
                                    ModernQuickActionCard(
                                        title: "Join Family Plan",
                                        icon: "person.3.fill",
                                        color: themeManager.selectedTheme.success
                                    ) {
                                        showFamilyInvite = true
                                    }
                                    
                                    ModernQuickActionCard(
                                        title: "Create Group",
                                        icon: "person.2.circle.fill",
                                        color: themeManager.selectedTheme.warning
                                    ) {
                                        // TODO: Implement create group
                                    }
                                    
                                    ModernQuickActionCard(
                                        title: "Manage Sharing",
                                        icon: "gear.circle.fill",
                                        color: themeManager.selectedTheme.textSecondary
                                    ) {
                                        // TODO: Implement manage sharing
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Shared Subscriptions
                        if !sharedSubscriptions.isEmpty {
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text("Shared Subscriptions")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(sharedSubscriptions, id: \.id) { subscription in
                                            ModernSharedSubscriptionRow(subscription: subscription)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Empty State
                            ModernCard {
                                VStack(spacing: 20) {
                                    Image(systemName: "person.2.circle")
                                        .font(.system(size: 64))
                                        .foregroundColor(themeManager.selectedTheme.accent.opacity(0.6))
                                    
                                    VStack(spacing: 8) {
                                        Text("No Shared Subscriptions")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Text("Share your subscriptions with family or friends to split costs and save money")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    ModernButton(
                                        title: "Share Your First Subscription",
                                        action: { showShareSheet = true },
                                        style: .primary
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Family Plans Section
                        if !familyPlans.isEmpty {
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text("Family Plans")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(familyPlans, id: \.id) { plan in
                                            FamilyPlanRow(plan: plan)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
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
                configureScrollbarAppearance()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSubscriptionView(selectedSubscription: selectedSubscription)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showFamilyInvite) {
            FamilyInviteView()
                .environmentObject(themeManager)
        }
    }

    private var sharingOverviewCard: some View {
        ModernCard {
            VStack(spacing: 20) {
                HStack {
                    Text("Sharing Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)

                    Spacer()
                }

                HStack(spacing: 20) {
                    SharingStatView(
                        icon: "person.2.fill",
                        title: "Shared",
                        value: "\(sharedSubscriptions.count)",
                        color: themeManager.selectedTheme.accent
                    )

                    SharingStatView(
                        icon: "person.3.fill",
                        title: "Family Plans",
                        value: "\(familyPlans.count)",
                        color: themeManager.selectedTheme.success
                    )

                    SharingStatView(
                        icon: "dollarsign.circle.fill",
                        title: "Saved",
                        value: monthlySavingsText,
                        color: themeManager.selectedTheme.warning
                    )
                }
            }
        }
    }
    
    private var sharedSubscriptions: [Subscription] {
        // For now, return empty array. In the future, this would filter
        // subscriptions that are shared with others
        return []
    }
    
    private var familyPlans: [FamilyPlan] {
        // Return empty array until family plan feature is implemented
        return []
    }
    
    private var monthlySavingsText: String {
        // Return $0 until sharing calculations are implemented
        return "$0"
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

struct ModernSharedSubscriptionRow: View {
    let subscription: Subscription
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Service Icon
            ZStack {
                Circle()
                    .fill(themeManager.selectedTheme.accent.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: serviceIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.accent)
            }
            
            // Subscription Details
            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                HStack(spacing: 12) {
                    Text(subscription.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.selectedTheme.accent.opacity(0.1))
                        .cornerRadius(8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("Shared")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Cost
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text("split cost")
                    .font(.caption2)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackground)
        .cornerRadius(16)
        .shadow(
            color: themeManager.selectedTheme.textPrimary.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private var serviceIcon: String {
        switch subscription.category {
        case .entertainment: return "play.circle.fill"
        case .productivity: return "briefcase.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .health: return "heart.fill"
        case .other: return "creditcard.fill"
        }
    }
}

struct ModernQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.selectedTheme.cardBackground)
            .cornerRadius(16)
            .shadow(
                color: themeManager.selectedTheme.textPrimary.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SharingStatView: View {
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

struct FamilyPlanRow: View {
    let plan: FamilyPlan
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.selectedTheme.success.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.selectedTheme.success)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text("\(plan.memberCount) members • $\(String(format: "%.2f", plan.monthlyCost))")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackground)
        .cornerRadius(16)
        .shadow(
            color: themeManager.selectedTheme.textPrimary.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

struct ShareSubscriptionView: View {
    let selectedSubscription: Subscription?
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Share Subscription")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                            .padding(.top)
                        
                        Text("Share your subscription with family and friends")
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
        }
    }
}

struct FamilyInviteView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Join Family Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                            .padding(.top)
                        
                        Text("Join an existing family plan to save money")
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
        }
    }
}

// MARK: - Data Models
struct FamilyPlan {
    let id: String
    let name: String
    let memberCount: Int
    let monthlyCost: Double
}

#Preview {
    SharedView()
        .environmentObject(DataManager())
        .environmentObject(ThemeManager())
}
