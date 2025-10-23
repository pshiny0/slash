import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTimeframe: TimeFrame = .monthly
    
    enum TimeFrame: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
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
                                Text("Analytics")
                                    .font(.tanTangkiwood(size: 36))
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                
                                Spacer()
                            }
                            
                            // Time Frame Selector
                            HStack(spacing: 8) {
                                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                    Button(action: { selectedTimeframe = timeframe }) {
                                        Text(timeframe.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedTimeframe == timeframe ? .white : themeManager.selectedTheme.textSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedTimeframe == timeframe ? themeManager.selectedTheme.accent : themeManager.selectedTheme.secondary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, -16)
                        
                        // Stats Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ModernStatCard(
                                title: "Total Subscriptions",
                                value: "\(dataManager.subscriptions.count)",
                                icon: "rectangle.stack.fill",
                                color: themeManager.selectedTheme.accent,
                                trend: nil
                            )
                            
                            ModernStatCard(
                                title: "\(selectedTimeframe.rawValue) Cost",
                                value: monthlyCostText,
                                icon: "dollarsign.circle.fill",
                                color: themeManager.selectedTheme.success,
                                trend: nil
                            )
                        }
                        .padding(.horizontal)
                        
                        // Spending Overview
                        if !dataManager.subscriptions.isEmpty {
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text("Spending Overview")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    // Circular Progress Chart
                                    HStack(spacing: 24) {
                                        CircularProgressView(
                                            progress: spendingProgress,
                                            total: totalCost,
                                            color: themeManager.selectedTheme.accent
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            SpendingOverviewRow(
                                                title: "This \(selectedTimeframe.rawValue)",
                                                amount: totalCost,
                                                color: themeManager.selectedTheme.accent
                                            )
                                            
                                            if selectedTimeframe != .yearly {
                                                SpendingOverviewRow(
                                                    title: "Projected Yearly",
                                                    amount: totalMonthlyCost * 12,
                                                    color: themeManager.selectedTheme.warning
                                                )
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Category Breakdown
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text("Category Breakdown")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(categoryBreakdown, id: \.category) { data in
                                            CategoryBreakdownRow(
                                                category: data.category,
                                                amount: data.totalCost,
                                                percentage: data.percentage,
                                                color: categoryColor(for: data.category)
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Recent Activity
                            ModernCard {
                                VStack(spacing: 20) {
                                    HStack {
                                        Text("Recent Activity")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(recentActivity, id: \.id) { activity in
                                            ActivityRow(activity: activity)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Empty State
                            ModernCard {
                                VStack(spacing: 20) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 64))
                                        .foregroundColor(themeManager.selectedTheme.accent.opacity(0.6))
                                    
                                    VStack(spacing: 8) {
                                        Text("No Analytics Yet")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        Text("Add subscriptions to see your spending breakdown, category analysis, and spending trends")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                            .multilineTextAlignment(.center)
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
    }
    
    private var monthlyCostText: String {
        String(format: "$%.2f", totalCost)
    }
    
    private var totalMonthlyCost: Double {
        dataManager.subscriptions.reduce(into: 0.0) { total, subscription in
            total += subscription.price
        }
    }
    
    private var totalCost: Double {
        switch selectedTimeframe {
        case .weekly:
            return totalMonthlyCost / 4.33 // Approximate weeks per month
        case .monthly:
            return totalMonthlyCost
        case .yearly:
            return totalMonthlyCost * 12
        }
    }
    
    private var spendingProgress: Double {
        // Calculate progress based on budget
        guard dataManager.monthlyBudget > 0 else { return 0.0 }
        let budgetForTimeframe: Double
        switch selectedTimeframe {
        case .weekly:
            budgetForTimeframe = dataManager.monthlyBudget / 4.33
        case .monthly:
            budgetForTimeframe = dataManager.monthlyBudget
        case .yearly:
            budgetForTimeframe = dataManager.monthlyBudget * 12
        }
        return min(totalCost / budgetForTimeframe, 1.0)
    }
    
    private var categoryBreakdown: [CategoryAnalytics] {
        let grouped = Dictionary(grouping: dataManager.subscriptions) { $0.category }
        let total = totalCost
        
        return grouped.map { category, subs in
            let categoryTotal = subs.reduce(into: 0.0) { total, sub in
                total += sub.price
            }
            return CategoryAnalytics(
                category: category,
                totalCost: categoryTotal,
                percentage: total > 0 ? (categoryTotal / total) * 100 : 0
            )
        }.sorted { $0.totalCost > $1.totalCost }
    }
    
    private var recentActivity: [ActivityItem] {
        // Return the most recent 5 activities
        let activities = Array(dataManager.activities.prefix(5))
        print("🔍 Analytics: Recent activities count: \(activities.count)")
        for activity in activities {
            print("🔍 Activity: \(activity.type.rawValue) - \(activity.subscriptionName) - \(activity.date)")
        }
        return activities
    }
    
    private func categoryColor(for category: SubscriptionCategory) -> Color {
        switch category {
        case .entertainment: return Color.blue
        case .productivity: return Color.cyan
        case .utilities: return Color.green
        case .health: return Color.orange
        case .other: return Color.gray
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

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.success)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(themeManager.selectedTheme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.selectedTheme.success.opacity(0.1))
                        .cornerRadius(8)
                }
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

struct CircularProgressView: View {
    let progress: Double
    let total: Double
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(themeManager.selectedTheme.secondary, lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            VStack(spacing: 2) {
                if dataManager.monthlyBudget > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Text("of budget")
                        .font(.caption2)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                } else {
                    Text("Set budget")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                    
                    Text("to track spending")
                        .font(.caption2)
                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                }
            }
        }
    }
}

struct SpendingOverviewRow: View {
    let title: String
    let amount: Double
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.textSecondary)
            
            Spacer()
            
            Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct CategoryBreakdownRow: View {
    let category: SubscriptionCategory
    let amount: Double
    let percentage: Double
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text("\(String(format: "%.1f", percentage))% of total")
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
            
            Spacer()
            
            Text(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.selectedTheme.textPrimary)
        }
        .padding(.vertical, 8)
    }
    
    private var categoryIcon: String {
        switch category {
        case .entertainment: return "play.circle.fill"
        case .productivity: return "briefcase.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .health: return "heart.fill"
        case .other: return "creditcard.fill"
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: activityIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(activityColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activityText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                
                Text(activity.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(themeManager.selectedTheme.textSecondary)
            }
            
            Spacer()
            
            Text(activity.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(activityColor)
        }
        .padding(.vertical, 8)
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .added: return themeManager.selectedTheme.success
        case .updated: return themeManager.selectedTheme.warning
        case .deleted: return themeManager.selectedTheme.error
        case .renewed: return themeManager.selectedTheme.accent
        case .cancelled: return themeManager.selectedTheme.error
        }
    }
    
    private var activityIcon: String {
        switch activity.type {
        case .added: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        case .renewed: return "arrow.clockwise.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
    
    private var activityText: String {
        switch activity.type {
        case .added: return "Added \(activity.subscriptionName)"
        case .updated: return "Updated \(activity.subscriptionName)"
        case .deleted: return "Deleted \(activity.subscriptionName)"
        case .renewed: return "\(activity.subscriptionName) renewed"
        case .cancelled: return "Cancelled \(activity.subscriptionName)"
        }
    }
}

// MARK: - Data Models
struct CategoryAnalytics {
    let category: SubscriptionCategory
    let totalCost: Double
    let percentage: Double
}

struct ActivityItem: Codable, Identifiable {
    let id: String
    let type: ActivityType
    let subscriptionName: String
    let amount: Double
    let date: Date
    let userId: String
    
    enum ActivityType: String, Codable {
        case added
        case updated
        case deleted
        case renewed
        case cancelled
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(DataManager())
}

