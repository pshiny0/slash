import Foundation

struct SlashUser: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var displayName: String
    var profileImageURL: String?
    var firstName: String?
    var lastName: String?
    var provider: AuthProvider?
    var emailConnections: [EmailConnection]
    
    init(id: String, email: String, displayName: String, profileImageURL: String? = nil, firstName: String? = nil, lastName: String? = nil, provider: AuthProvider? = nil, emailConnections: [EmailConnection] = []) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.firstName = firstName
        self.lastName = lastName
        self.provider = provider
        self.emailConnections = emailConnections
    }
    
    // Custom decoder to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        provider = try container.decodeIfPresent(AuthProvider.self, forKey: .provider)
        
        // Decode emailConnections with backward compatibility
        if let connections = try container.decodeIfPresent([EmailConnection].self, forKey: .emailConnections) {
            emailConnections = connections
        } else {
            emailConnections = []
        }
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encode(emailConnections, forKey: .emailConnections)
    }
    
    // CodingKeys enum
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profileImageURL
        case firstName
        case lastName
        case provider
        case emailConnections
    }
    
    // Equatable conformance
    static func == (lhs: SlashUser, rhs: SlashUser) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.displayName == rhs.displayName &&
               lhs.profileImageURL == rhs.profileImageURL &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.provider == rhs.provider &&
               lhs.emailConnections == rhs.emailConnections
    }
    
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


