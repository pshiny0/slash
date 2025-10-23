import SwiftUI

struct AddEditSubscriptionView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var existing: Subscription? = nil

    @State private var name: String = ""
    @State private var priceText: String = ""
    @State private var renewalDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var startDate: Date = Date()
    @State private var category: SubscriptionCategory = .other
    @State private var billingCycle: BillingCycle = .monthly
    @State private var notes: String = ""
    @State private var shareEmails: String = ""
    @State private var cancelLink: URL? = nil
    @State private var cancelScheme: URL? = nil
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var validationErrors: Set<String> = []
    @State private var validationTrigger: Int = 0
    @State private var showValidationErrors: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(existing == nil ? "Add Subscription" : "Edit Subscription")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Text(existing == nil ? "Track a new subscription service" : "Update subscription details")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 0)
                        
                        // Subscription Details Card
                        ModernCard {
                            VStack(spacing: 24) {
                                HStack {
                                    Text("Add Subscription")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 20) {
                                    // Subscription Name
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Subscription Name *")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(showValidationErrors && validationErrors.contains("name") ? .red : themeManager.selectedTheme.textPrimary)
                                            .id("name-\(validationTrigger)")
                                        
                                        ModernTextField(
                                            placeholder: "Netflix, Spotify, Notion",
                                            text: $name
                                        )
                                        .onChange(of: name) { newValue in
                                            scheduleLookup(for: newValue)
                                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                validationErrors.remove("name")
                                                validationTrigger += 1
                                            }
                                        }
                                    }
                                    
                                    // Category and Amount Row
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Category *")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(validationErrors.contains("category") ? .red : themeManager.selectedTheme.textPrimary)
                                            
                                            Menu {
                                                ForEach(SubscriptionCategory.allCases) { cat in
                                                    Button(action: { category = cat }) {
                                                        Text(cat.displayName)
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(category.displayName)
                                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                                    Spacer()
                                                    Image(systemName: "chevron.down")
                                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                                        .font(.caption)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(themeManager.selectedTheme.secondary)
                                                .cornerRadius(12)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Amount *")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(showValidationErrors && validationErrors.contains("amount") ? .red : themeManager.selectedTheme.textPrimary)
                                                .id("amount-\(validationTrigger)")
                                            
                                            ModernTextField(
                                                placeholder: "15.99",
                                                text: $priceText,
                                                keyboardType: .decimalPad
                                            )
                                            .onChange(of: priceText) { newValue in
                                                if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    validationErrors.remove("amount")
                                                    validationTrigger += 1
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Billing Cycle and Start Date Row
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Billing Cycle *")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(validationErrors.contains("billingCycle") ? .red : themeManager.selectedTheme.textPrimary)
                                            
                                            Menu {
                                                ForEach(BillingCycle.allCases) { cycle in
                                                    Button(action: { 
                                                        billingCycle = cycle
                                                        updateRenewalDate()
                                                        validationErrors.remove("billingCycle")
                                                    }) {
                                                        Text(cycle.displayName)
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(billingCycle.displayName)
                                                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                                                    Spacer()
                                                    Image(systemName: "chevron.down")
                                                        .foregroundColor(themeManager.selectedTheme.textSecondary)
                                                        .font(.caption)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(themeManager.selectedTheme.secondary)
                                                .cornerRadius(12)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Start Date *")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(validationErrors.contains("startDate") ? .red : themeManager.selectedTheme.textPrimary)
                                            
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(themeManager.selectedTheme.secondary)
                                            .cornerRadius(12)
                                            .onChange(of: startDate) { _ in
                                                updateRenewalDate()
                                                validationErrors.remove("startDate")
                                            }
                                        }
                                    }
                                    
                                    // Shared With
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Shared With")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        ModernTextField(
                                            placeholder: "Share with emails (comma-separated)",
                                            text: $shareEmails
                                        )
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        
                                        Text("Used to manage or invite shared members")
                                            .font(.caption)
                                            .foregroundColor(themeManager.selectedTheme.textSecondary)
                                    }
                                    
                                    // Notes
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Notes")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                        
                                        TextField("", text: $notes, axis: .vertical)
                                            .placeholder(when: notes.isEmpty) {
                                                Text("Add any additional notes about this subscription")
                                                    .foregroundColor(themeManager.selectedTheme.textSecondary)
                                            }
                                            .padding()
                                            .background(themeManager.selectedTheme.secondary)
                                            .cornerRadius(12)
                                            .foregroundColor(themeManager.selectedTheme.textPrimary)
                                            .tint(themeManager.selectedTheme.accent)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 5)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.selectedTheme.accent)
                }
                
                ToolbarItem(placement: .confirmationAction) { 
                    Button("Save") {
                        save()
                    }
                    .foregroundColor(themeManager.selectedTheme.accent)
                    .disabled(isLoading)
                }
            }
            .onAppear { loadExisting() }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func loadExisting() {
        guard let existing else { return }
        name = existing.name
        priceText = String(existing.price)
        startDate = existing.startDate
        category = existing.category
        billingCycle = existing.billingCycle
        notes = existing.notes ?? ""
        cancelLink = existing.cancelLink
        cancelScheme = existing.cancelScheme
        
        // Calculate renewal date based on billing cycle and start date
        updateRenewalDate()
    }

    // Debounced service directory lookup to avoid main-thread work while typing
    @State private var lookupWorkItem: DispatchWorkItem? = nil
    private func scheduleLookup(for query: String) {
        lookupWorkItem?.cancel()
        let item = DispatchWorkItem { [weak dataManager] in
            guard !query.isEmpty, let item = dataManager?.lookupService(named: query) else { return }
            DispatchQueue.main.async {
                cancelLink = item.cancelURL
                cancelScheme = item.appURLScheme
            }
        }
        lookupWorkItem = item
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    private func save() {
        guard let user = dataManager.currentUser else { 
            errorMessage = "Please sign in to add subscriptions"
            showError = true
            return 
        }
        
        // Clear previous validation errors
        validationErrors.removeAll()
        
        // Validate mandatory fields
        var hasErrors = false
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🔴 VALIDATION: Name is empty, adding to errors")
            validationErrors.insert("name")
            hasErrors = true
        } else {
            print("🔴 VALIDATION: Name is not empty: '\(name)'")
        }
        
        if priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.insert("amount")
            hasErrors = true
        }
        
        if hasErrors {
            print("🔴 VALIDATION: Has errors, setting showValidationErrors = true")
            print("🔴 VALIDATION: Errors: \(validationErrors)")
            // Force UI update by setting showValidationErrors
            showValidationErrors = true
            validationTrigger += 1
            return
        } else {
            print("🔴 VALIDATION: No errors found")
        }
        
        guard let price = Double(priceText), price > 0 else {
            validationErrors.insert("amount")
            return
        }
        
        isLoading = true
        
        let sharedWith = shareEmails
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let sub = Subscription(
            id: existing?.id ?? UUID().uuidString,
            name: name,
            price: price,
            renewalDate: renewalDate,
            startDate: startDate,
            category: category,
            notes: notes.isEmpty ? nil : notes,
            ownerId: user.id,
            cancelLink: cancelLink,
            cancelScheme: cancelScheme,
            sharedWith: sharedWith,
            status: .active,
            billingCycle: billingCycle
        )
        
        Task {
            do {
            if existing == nil {
                    try await dataManager.addSubscription(sub)
            } else {
                    try await dataManager.updateSubscription(sub)
                }
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func updateRenewalDate() {
        renewalDate = billingCycle.calculateRenewalDate(from: startDate)
    }
}


