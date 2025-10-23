import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showAdd: Bool = false
    @State private var searchText: String = ""
    @State private var filterCategory: SubscriptionCategory? = nil
    @State private var showFilterMenu: Bool = false
    @State private var viewportHeight: CGFloat = 0

    private var upcomingRenewals: [Subscription] {
        dataManager.subscriptions.filter { sub in
            sub.isUpcoming && sub.status == .active
        }.sorted { $0.daysUntilRenewal < $1.daysUntilRenewal }
    }
    
    private var allSubscriptions: [Subscription] {
        dataManager.subscriptions.filter { sub in
            let matchesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let matchesCat = filterCategory == nil || sub.category == filterCategory
            return matchesSearch && matchesCat
        }.sorted { $0.renewalDate < $1.renewalDate }
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
                            
                            if allSubscriptions.isEmpty {
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
                                    ForEach(allSubscriptions) { subscription in
                                        NavigationLink(value: subscription.id) {
                                            AllSubscriptionsRow(subscription: subscription)
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
                                            
                                            Button {
                                                // TODO: Implement edit functionality
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            
                                            Button {
                                                // TODO: Implement share functionality
                                            } label: {
                                                Label("Share", systemImage: "square.and.arrow.up")
                                            }
                                            
                                            Button {
                                                // TODO: Implement reminder adjustment
                                            } label: {
                                                Label("Reminder", systemImage: "bell")
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
        case .productivity:
            return "briefcase.fill"
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
        case .productivity:
            return "briefcase.fill"
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

struct AllSubscriptionsRow: View {
    let subscription: Subscription
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // App Icon/Logo
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
                HStack {
                    Text(subscription.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Spacer()
                    
                    // Shared Indicator
                    if subscription.isShared {
                        Text("👥")
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 12) {
                    // Billing Cycle
                    Text(subscription.billingCycle.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.selectedTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.selectedTheme.accent.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Status Badge
                    Text(subscription.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Renewal Date
                Text("Renews \(renewalDateText)")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text(subscription.billingCycle.rawValue)
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
    
    private var statusColor: Color {
        switch subscription.status {
        case .active: return themeManager.selectedTheme.success
        case .canceled: return themeManager.selectedTheme.error
        case .paused: return themeManager.selectedTheme.warning
        }
    }
    
    private var renewalDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: subscription.renewalDate)
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


