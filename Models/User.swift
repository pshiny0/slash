import Foundation

struct SlashUser: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var displayName: String
    var profileImageURL: String?
    var firstName: String?
    var lastName: String?
    var provider: AuthProvider?
    
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return displayName
    }
}

enum AuthProvider: String, Codable, CaseIterable {
    case google = "google"
    case apple = "apple"
    case email = "email"
    
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .apple: return "Apple"
        case .email: return "Email"
        }
    }
}


