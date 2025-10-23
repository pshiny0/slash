import Foundation

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    case entertainment
    case productivity
    case utilities
    case health
    case other

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .entertainment: return "Entertainment"
        case .productivity: return "Productivity"
        case .utilities: return "Utilities"
        case .health: return "Health"
        case .other: return "Other"
        }
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active
    case canceled
    case paused
}

enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
    
    func calculateRenewalDate(from startDate: Date) -> Date {
        let calendar = Calendar.current
        
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            // For custom, we'll use monthly as default
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }
}

struct Subscription: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var price: Double
    var renewalDate: Date
    var startDate: Date
    var category: SubscriptionCategory
    var notes: String?
    var ownerId: String
    var cancelLink: URL?
    var cancelScheme: URL?
    var sharedWith: [String]
    var status: SubscriptionStatus
    var billingCycle: BillingCycle
    
    // Custom initializer to handle backward compatibility
    init(id: String, name: String, price: Double, renewalDate: Date, startDate: Date, category: SubscriptionCategory, notes: String? = nil, ownerId: String, cancelLink: URL? = nil, cancelScheme: URL? = nil, sharedWith: [String] = [], status: SubscriptionStatus = .active, billingCycle: BillingCycle = .monthly) {
        self.id = id
        self.name = name
        self.price = price
        self.renewalDate = renewalDate
        self.startDate = startDate
        self.category = category
        self.notes = notes
        self.ownerId = ownerId
        self.cancelLink = cancelLink
        self.cancelScheme = cancelScheme
        self.sharedWith = sharedWith
        self.status = status
        self.billingCycle = billingCycle
    }
    
    // Custom decoder to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Double.self, forKey: .price)
        renewalDate = try container.decode(Date.self, forKey: .renewalDate)
        category = try container.decode(SubscriptionCategory.self, forKey: .category)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        cancelLink = try container.decodeIfPresent(URL.self, forKey: .cancelLink)
        cancelScheme = try container.decodeIfPresent(URL.self, forKey: .cancelScheme)
        sharedWith = try container.decodeIfPresent([String].self, forKey: .sharedWith) ?? []
        
        // Handle backward compatibility for new fields
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? renewalDate
        status = try container.decodeIfPresent(SubscriptionStatus.self, forKey: .status) ?? .active
        billingCycle = try container.decodeIfPresent(BillingCycle.self, forKey: .billingCycle) ?? .monthly
    }

    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: renewalDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    var isShared: Bool {
        return !sharedWith.isEmpty
    }
    
    var isUpcoming: Bool {
        return daysUntilRenewal <= 10 && daysUntilRenewal >= 0
    }
}

struct ServiceDirectoryItem: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let cancelURL: URL?
    let appURLScheme: URL?
}



