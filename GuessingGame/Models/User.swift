import Foundation

struct User: Codable, Equatable {
    let id: String
    let displayName: String
    let email: String?
    var avatar: String
    var createdAt: Date
    
    init(id: String, displayName: String, email: String? = nil, avatar: String = "😀") {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatar = avatar
        self.createdAt = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "displayName": displayName,
            "email": email ?? "",
            "avatar": avatar,
            "createdAt": createdAt.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> User? {
        guard let id = dict["id"] as? String,
              let displayName = dict["displayName"] as? String,
              let avatar = dict["avatar"] as? String,
              let createdAtTimestamp = dict["createdAt"] as? TimeInterval else {
            return nil
        }
        
        let email = dict["email"] as? String
        var user = User(id: id, displayName: displayName, email: email?.isEmpty == true ? nil : email, avatar: avatar)
        user.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        return user
    }
}

enum AuthenticationState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case needsAvatar(User)
}