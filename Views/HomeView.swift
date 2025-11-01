import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showAdd: Bool = false
    @State private var searchText: String = ""
    @State private var filterCategory: SubscriptionCategory? = nil
    @State private var showFilterMenu: Bool = false
    @State private var viewportHeight: CGFloat = 0
    @AppStorage("needsAttentionExpanded") private var needsAttentionExpanded: Bool = false
    @AppStorage("inactiveExpanded") private var inactiveExpanded: Bool = false

    private var upcomingRenewals: [Subscription] {
        dataManager.subscriptions.filter { sub in
            sub.isUpcoming && sub.status == .active
        }.sorted { $0.daysUntilRenewal < $1.daysUntilRenewal }
    }
    
    private var filteredSubscriptions: [Subscription] {
        dataManager.subscriptions.filter { sub in
            let matchesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let matchesCat = filterCategory == nil || sub.category == filterCategory
            return matchesSearch && matchesCat
        }
    }
    
    // Group subscriptions by status
    private var activeSubscriptions: [Subscription] {
        filteredSubscriptions.filter { $0.status == .active }
            .sorted { $0.renewalDate < $1.renewalDate }
    }
    
    private var pendingSubscriptions: [Subscription] {
        filteredSubscriptions.filter { $0.status == .pendingDecision }
            .sorted { $0.renewalDate < $1.renewalDate }
    }
    
    private var inactiveSubscriptions: [Subscription] {
        filteredSubscriptions.filter { $0.status.isInactive }
            .sorted { $0.renewalDate < $1.renewalDate }
    }


    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: 0).id("top")
                        // Modern Header
                        VStack(spacing: 16) {
                            HStack {
                                Text("Hey, \(dataManager.currentUser?.displayName.components(separatedBy: " ").first ?? "User")")
                                    .font(.tanTangkiwood(size: 36))
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        // Force refresh subscriptions by restarting the listener
                                        dataManager.refreshSubscriptions()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                        .frame(width: 44, height: 44)
                                        .background(themeManager.selectedTheme.accent.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                                
                                TextField("Search subscriptions...", text: $searchText)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    .tint(themeManager.selectedTheme.accent)
                                    .placeholder(when: searchText.isEmpty) {
                                        Text("Search subscriptions...")
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    }
                                }
                            }
                            .padding()
                            .background(themeManager.selectedTheme.cardBackground)
                            .cornerRadius(16)
                            .shadow(color: themeManager.selectedTheme.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.top, -16)
                        
                        // Filter Chips
                        if filterCategory != nil {
                            HStack {
                                Text("Filtered by: \(filterCategory?.rawValue.capitalized ?? "")")
                                    .font(.caption)
                                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                                
                                Spacer()
                                
                                Button(action: { filterCategory = nil }) {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Upcoming Renewals Section
                        if !upcomingRenewals.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Upcoming Renewals")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(upcomingRenewals) { subscription in
                                            NavigationLink(value: subscription.id) {
                                                UpcomingRenewalCard(subscription: subscription)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // All Subscriptions Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("All Subscriptions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                
                                Spacer()
                                
                                Button(action: { showFilterMenu = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                        Text("Filter")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(themeManager.selectedTheme.secondary)
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                            
                            if filteredSubscriptions.isEmpty {
                                // Empty State
                                ModernCard {
                                    VStack(spacing: 20) {
                                        Image(systemName: "creditcard.circle")
                                            .font(.system(size: 64))
                                            .foregroundColor(themeManager.selectedTheme.accent.opacity(0.6))
                                        
                                        VStack(spacing: 8) {
                                            Text("No subscriptions yet")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                                            
                                            Text("Start tracking your subscriptions by adding your first one")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        
                                        ModernButton(
                                            title: "Add Subscription",
                                            action: { showAdd = true },
                                            style: .primary
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 12) {
                                    // Active Subscriptions (no grouping header)
                                    ForEach(activeSubscriptions) { subscription in
                                        SubscriptionRowCard(subscription: subscription)
                                    }
                                    
                                    // Needs Attention Section (Collapsible)
                                    if !pendingSubscriptions.isEmpty {
                                        CollapsibleSection(
                                            title: "Needs Attention (\(pendingSubscriptions.count))",
                                            isExpanded: $needsAttentionExpanded
                                        ) {
                                            ForEach(pendingSubscriptions) { subscription in
                                                SubscriptionRowCard(subscription: subscription, isPending: true)
                                            }
                                        }
                                    }
                                    
                                    // Inactive Section (Collapsible)
                                    if !inactiveSubscriptions.isEmpty {
                                        CollapsibleSection(
                                            title: "Inactive (\(inactiveSubscriptions.count))",
                                            isExpanded: $inactiveExpanded
                                        ) {
                                            ForEach(inactiveSubscriptions) { subscription in
                                                SubscriptionRowCard(subscription: subscription)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add some bottom padding for the floating button
                        Spacer(minLength: 5)
                    }
                    // Remove minHeight so layout matches Analytics exactly
                }
                .onReceive(NotificationCenter.default.publisher(for: .slashTabChanged)) { _ in
                    withAnimation(.easeInOut) { proxy.scrollTo("top", anchor: .top) }
                }
                .onChange(of: dataManager.searchQuery) { _ in
                    withAnimation(.easeInOut) { proxy.scrollTo("top", anchor: .top) }
                }
                .onChange(of: dataManager.selectedCategory) { _ in
                    withAnimation(.easeInOut) { proxy.scrollTo("top", anchor: .top) }
                }
                .onAppear { 
                    proxy.scrollTo("top", anchor: .top)
                    configureScrollbarAppearance()
                }
                }
                
                // Floating Add Button above tab bar
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAdd = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(themeManager.selectedTheme.cardBackground)
                                .frame(width: 52, height: 52)
                                .background(themeManager.selectedTheme.accent)
                                .clipShape(Circle())
                                .shadow(color: themeManager.selectedTheme.accent.opacity(0.8), radius: 15, x: 0, y: 6)
                        }
                        .background(
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 80, height: 80)
                                .blur(radius: 12)
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationDestination(for: String.self) { id in
                if let sub = dataManager.subscriptions.first(where: { $0.id == id }) {
                    SubscriptionDetailView(subscription: sub)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) {
                AddEditSubscriptionView()
            }
            .confirmationDialog("Filter by Category", isPresented: $showFilterMenu) {
                Button("All Categories") { filterCategory = nil }
                ForEach(SubscriptionCategory.allCases) { category in
                    Button(category.displayName) { filterCategory = category }
                }
                Button("Cancel", role: .cancel) { }
            }
            // Remove viewport tracking to mirror Analytics layout
        }
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

struct ModernSubscriptionCard: View {
    let subscription: Subscription
    @EnvironmentObject private var themeManager: ThemeManager
    
    var renewalColor: Color {
        switch subscription.daysUntilRenewal {
        case ..<7: return themeManager.selectedTheme.error
        case ..<14: return themeManager.selectedTheme.warning
        default: return themeManager.selectedTheme.success
        }
    }
    
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
                    HStack(spacing: 4) {
                        Circle()
                            .fill(renewalColor)
                            .frame(width: 8, height: 8)
                        
                        Text("Renews in \(subscription.daysUntilRenewal) days")
                            .font(.caption)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                    }
                    
                    Text(subscription.category.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.selectedTheme.accent.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text("monthly")
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
        case .entertainment:
            return "play.circle.fill"
        case .productivity:
            return "briefcase.fill"
        case .utilities:
            return "wrench.and.screwdriver.fill"
        case .health:
            return "heart.fill"
        case .other:
            return "creditcard.fill"
        }
    }
}

struct CompactSubscriptionCard: View {
    let subscription: Subscription
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and category
            HStack {
                Image(systemName: serviceIcon)
                    .font(.title2)
                    .foregroundColor(themeManager.selectedTheme.accent)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Text(subscription.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.selectedTheme.accent.opacity(0.1))
                    .foregroundColor(themeManager.selectedTheme.accent)
                    .cornerRadius(8)
            }
            
            // Service name
            Text(subscription.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.selectedTheme.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            // Price at bottom
            HStack {
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Spacer()
                
                // Renewal indicator
                if subscription.renewalDate > Date() {
                    let daysUntilRenewal = Calendar.current.dateComponents([.day], from: Date(), to: subscription.renewalDate).day ?? 0
                    if daysUntilRenewal <= 7 {
                        Text("\(daysUntilRenewal)d")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.selectedTheme.warning.opacity(0.2))
                            .foregroundColor(themeManager.selectedTheme.warning)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .frame(height: 120)
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
        case .entertainment:
            return "play.circle.fill"
        case .productivity:
            return "briefcase.fill"
        case .utilities:
            return "wrench.and.screwdriver.fill"
        case .health:
            return "heart.fill"
        case .other:
            return "creditcard.fill"
        }
    }
}

struct UpcomingRenewalCard: View {
    let subscription: Subscription
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var urgencyColor: Color {
        switch subscription.daysUntilRenewal {
        case 0: return themeManager.selectedTheme.error // Today
        case 1...3: return themeManager.selectedTheme.warning // 3 days
        default: return themeManager.selectedTheme.success // 1 week
        }
    }
    
    private var urgencyText: String {
        switch subscription.daysUntilRenewal {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "\(subscription.daysUntilRenewal) days"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with logo and urgency badge
            HStack {
                // Service Logo (placeholder for now)
                ZStack {
                    Circle()
                        .fill(themeManager.selectedTheme.accent.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: serviceIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
                
                Spacer()
                
                // Urgency Badge
                Text(urgencyText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(urgencyColor)
                    .cornerRadius(8)
            }
            
            // Subscription Details
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                    .lineLimit(2)
                
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text("Renews \(renewalDateText)")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
        }
        .padding()
        .frame(width: 160, height: 140)
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
    
    private var renewalDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: subscription.renewalDate)
    }
}

// MARK: - Subscription Row Card (Minimal Design)
struct SubscriptionRowCard: View {
    let subscription: Subscription
    var isPending: Bool = false
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    @State private var showReminderModal = false
    
    private var isPastDue: Bool {
        subscription.daysUntilRenewal < 0
    }
    
    var body: some View {
        Group {
            if subscription.status == .pendingDecision || (subscription.status == .active && isPastDue) {
                // For pending or past due subscriptions, show modal on tap instead of navigation
                Button(action: {
                    showReminderModal = true
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    cardContent
                }
                .sheet(isPresented: $showReminderModal) {
                    PendingReminderModal(subscription: subscription)
                }
            } else {
                // For other subscriptions, allow navigation
                NavigationLink(value: subscription.id) {
                    cardContent
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    do {
                        try await dataManager.deleteSubscription(subscription)
                        print("Successfully deleted subscription: \(subscription.name)")
                    } catch {
                        print("Error deleting subscription: \(error)")
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            // Service Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: serviceIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconForegroundColor)
                    .opacity(subscription.status.isInactive ? 0.6 : 1.0)
            }
            
            // Subscription Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(subscription.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                        .opacity(cardOpacity)
                    
                    Spacer()
                    
                    // Shared Indicator
                    if subscription.isShared {
                        Text("👥")
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    // Next Billing Date
                    Text(nextBillingDateText)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                        .opacity(cardOpacity)
                    
                    // Status Tag (shown for non-active or past due subscriptions)
                    if let statusLabel = effectiveStatusLabel {
                        Text(statusLabel)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(effectiveStatusTagColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(effectiveStatusTagBackgroundColor)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                    .opacity(cardOpacity)
            }
        }
        .padding()
        .background(themeManager.selectedTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: (isPending || isPastDue) ? 1 : 0)
        )
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
    
    private var nextBillingDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        if subscription.status == .ended || subscription.status == .canceled {
            return formatter.string(from: subscription.renewalDate)
        } else if subscription.daysUntilRenewal < 0 {
            return "Past due"
        } else {
            return "Next: \(formatter.string(from: subscription.renewalDate))"
        }
    }
    
    // Visual hierarchy styling
    private var cardOpacity: Double {
        switch subscription.status {
        case .canceled:
            return 0.6
        case .ended:
            return 0.5
        default:
            return 1.0
        }
    }
    
    private var iconBackgroundColor: Color {
        // Show yellow accent for pending or past due subscriptions
        if subscription.status == .pendingDecision || (subscription.status == .active && subscription.daysUntilRenewal < 0) {
            return themeManager.selectedTheme.warning
        }
        return themeManager.selectedTheme.accent
    }
    
    private var iconForegroundColor: Color {
        // Show yellow accent for pending or past due subscriptions
        if subscription.status == .pendingDecision || (subscription.status == .active && subscription.daysUntilRenewal < 0) {
            return themeManager.selectedTheme.warning
        }
        return themeManager.selectedTheme.accent
    }
    
    // Effective status label considering both status and renewal date
    private var effectiveStatusLabel: String? {
        // First check explicit status labels
        if let label = subscription.status.displayLabel {
            return label
        }
        
        // If active but renewal date is in the past, show "Needs Update"
        if subscription.status == .active && subscription.daysUntilRenewal < 0 {
            return "Needs Update"
        }
        
        // If paused and renewal date is in the past, show "Expired"
        if subscription.status == .paused && subscription.daysUntilRenewal < 0 {
            return "Expired"
        }
        
        return nil
    }
    
    private var effectiveStatusTagColor: Color {
        // Check if renewal date is past
        let isPastDue = subscription.daysUntilRenewal < 0
        
        switch subscription.status {
        case .pendingDecision:
            return themeManager.selectedTheme.warning // Yellow accent
        case .active:
            if isPastDue {
                return themeManager.selectedTheme.warning // Yellow accent for past due
            }
            return themeManager.selectedTheme.textPrimary
        case .ended:
            return themeManager.selectedTheme.textSecondary // Gray tint
        case .canceled:
            return themeManager.selectedTheme.textSecondary // Dimmed
        case .paused:
            if isPastDue {
                return themeManager.selectedTheme.textSecondary // Gray tint for expired
            }
            return themeManager.selectedTheme.textSecondary
        }
    }
    
    private var effectiveStatusTagBackgroundColor: Color {
        // Check if renewal date is past
        let isPastDue = subscription.daysUntilRenewal < 0
        
        switch subscription.status {
        case .pendingDecision:
            return themeManager.selectedTheme.warning.opacity(0.15) // Yellow accent
        case .active:
            if isPastDue {
                return themeManager.selectedTheme.warning.opacity(0.15) // Yellow accent for past due
            }
            return Color.clear
        case .ended:
            return themeManager.selectedTheme.textSecondary.opacity(0.1) // Gray tint
        case .canceled:
            return themeManager.selectedTheme.textSecondary.opacity(0.1) // Dimmed
        case .paused:
            if isPastDue {
                return themeManager.selectedTheme.textSecondary.opacity(0.1) // Gray tint for expired
            }
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        themeManager.selectedTheme.warning.opacity(0.3)
    }
}

struct QuickStatView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
            }
        }
    }
}

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Pending Reminder Modal
struct PendingReminderModal: View {
    let subscription: Subscription
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(themeManager.selectedTheme.warning.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.selectedTheme.warning)
                    }
                    
                    // Question
                    VStack(spacing: 8) {
                        Text("Did this renew?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                        
                        Text(subscription.name)
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        ModernButton(
                            title: "Yes, Renewed",
                            action: {
                                dataManager.confirmRenewal(for: subscription.id)
                                dismiss()
                            },
                            style: .primary
                        )
                        
                        ModernButton(
                            title: "No, Cancelled",
                            action: {
                                dataManager.declineRenewal(for: subscription.id)
                                dismiss()
                            },
                            style: .secondary
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 40)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
            }
        }
    }
}


