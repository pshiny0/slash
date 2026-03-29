import SwiftUI
import UIKit

struct SubscriptionDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let subscription: Subscription
    @State private var showEdit: Bool = false
    @State private var showDeleteAlert: Bool = false

    var canEdit: Bool {
        let isOwner = dataManager.currentUser?.id == subscription.ownerId
        let subscriptionExists = dataManager.subscriptions.contains { $0.id == subscription.id }
        
        print("canEdit check - User ID: \(dataManager.currentUser?.id ?? "nil")")
        print("canEdit check - Subscription owner ID: \(subscription.ownerId)")
        print("canEdit check - Is owner: \(isOwner)")
        print("canEdit check - Subscription exists: \(subscriptionExists)")
        print("canEdit check - Final result: \(isOwner && subscriptionExists)")
        
        return isOwner && subscriptionExists
    }

    var body: some View {
        ZStack {
            GradientBackground()
                .environmentObject(themeManager)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(subscription.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                
                                Text(subscription.category.rawValue.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(themeManager.selectedTheme.accent.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            if canEdit {
                                Button(action: { showEdit = true }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 0)
                    
                    // Overview Card
                    ModernCard {
                        VStack(spacing: 20) {
                            HStack {
                                Text("Overview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                DetailRowView(
                                    icon: "dollarsign.circle.fill",
                                    title: "Price",
                                    value: Text(subscription.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD")),
                                    color: themeManager.selectedTheme.success
                                )
                                
                                DetailRowView(
                                    icon: "calendar.circle.fill",
                                    title: "Next Renewal",
                                    value: Text(subscription.renewalDate, style: .date),
                                    color: renewalColor
                                )
                                
                                DetailRowView(
                                    icon: "clock.circle.fill",
                                    title: "Days Until Renewal",
                                    value: Text("\(subscription.daysUntilRenewal) days"),
                                    color: renewalColor
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes Card
                    if let notes = subscription.notes, !notes.isEmpty {
                        ModernCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                    Text("Notes")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sharing Card
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.2.circle.fill")
                                    .foregroundColor(themeManager.selectedTheme.accent)
                                Text("Sharing")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                                
                                Spacer()
                            }
                            
                            if subscription.sharedWith.isEmpty {
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    Text("Not shared with anyone")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    Spacer()
                                }
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(subscription.sharedWith, id: \.self) { email in
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(themeManager.selectedTheme.accent)
                                            Text(email)
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Management Actions
                    if subscription.cancelLink != nil || subscription.cancelScheme != nil {
                        ModernCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "scissors.circle.fill")
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                    Text("Management")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Button(action: openCancel) {
                                        HStack {
                                            Image(systemName: "link")
                                            Text("Open Cancellation Guide")
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.selectedTheme.accent)
                                        .padding()
                                        .background(themeManager.selectedTheme.accent.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Delete Button (if can edit)
                    if canEdit {
                        ModernCard {
                            Button(action: { showDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundColor(themeManager.selectedTheme.error)
                                    Text("Delete Subscription")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.selectedTheme.error)
                                    Spacer()
                                }
                                .padding()
                                .background(themeManager.selectedTheme.error.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 5)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            AddEditSubscriptionView(existing: subscription)
        }
        .alert("Delete Subscription", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        print("=== DETAIL VIEW DELETE ===")
                        print("Subscription ID: \(subscription.id)")
                        print("Subscription name: \(subscription.name)")
                        print("Subscription owner: \(subscription.ownerId)")
                        print("Current user: \(dataManager.currentUser?.id ?? "nil")")
                        print("=========================")
                        
                        try await dataManager.deleteSubscription(subscription)
                        // Navigate back after successful deletion
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    } catch {
                        print("Error deleting subscription: \(error)")
                        // You could show an error alert here if needed
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this subscription? This action cannot be undone.")
        }
    }

    private var renewalColor: Color {
        switch subscription.daysUntilRenewal {
        case ..<7: return themeManager.selectedTheme.error
        case ..<14: return themeManager.selectedTheme.warning
        default: return themeManager.selectedTheme.success
        }
    }

    private func openCancel() {
        if let scheme = subscription.cancelScheme, UIApplication.shared.canOpenURL(scheme) {
            UIApplication.shared.open(scheme)
        } else if let url = subscription.cancelLink {
            UIApplication.shared.open(url)
        }
    }
}

struct DetailRowView: View {
    let icon: String
    let title: String
    let value: Text
    let color: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.selectedTheme.textSecondary)
            
            Spacer()
            
            value
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.selectedTheme.textPrimary)
        }
    }
}

#Preview {
    SubscriptionDetailView(
        subscription: Subscription(
            id: UUID().uuidString,
            name: "Netflix",
            price: 15.99,
            renewalDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            startDate: Calendar.current.date(byAdding: .month, value: -5, to: Date()) ?? Date(),
            category: .entertainment,
            notes: "Premium plan shared with family.",
            ownerId: "preview-user",
            cancelLink: URL(string: "https://www.netflix.com/cancelplan"),
            sharedWith: ["alex@example.com"],
            status: .active,
            billingCycle: .monthly,
            renewalPreference: .autoRenew,
            reminderDaysBefore: 3
        )
    )
    .environmentObject(DataManager())
    .environmentObject(ThemeManager())
}
