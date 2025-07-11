import Foundation

struct GameSession: Codable, Equatable {
    let id: String
    let hostId: String
    var players: [String: GamePlayer]
    var gameStarted: Bool
    var gameState: GameState?
    var playerRoles: [String: PlayerRole]
    var createdAt: Date
    
    init(id: String, hostId: String, hostPlayer: GamePlayer) {
        self.id = id
        self.hostId = hostId
        self.players = [hostId: hostPlayer]
        self.gameStarted = false
        self.gameState = nil
        self.playerRoles = [:]
        self.createdAt = Date()
    }
    
    func toDictionary() -> [String: Any] {
        let playersDict = players.mapValues { $0.toDictionary() }
        let rolesDict = playerRoles.mapValues { $0.rawValue }
        
        var dict: [String: Any] = [
            "id": id,
            "hostId": hostId,
            "players": playersDict,
            "gameStarted": gameStarted,
            "playerRoles": rolesDict,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        
        if let gameState = gameState {
            dict["gameState"] = gameState.toDictionary()
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> GameSession? {
        guard let id = dict["id"] as? String,
              let hostId = dict["hostId"] as? String,
              let playersDict = dict["players"] as? [String: [String: Any]],
              let gameStarted = dict["gameStarted"] as? Bool,
              let createdAtTimestamp = dict["createdAt"] as? TimeInterval else {
            return nil
        }
        
        var players: [String: GamePlayer] = [:]
        for (playerId, playerDict) in playersDict {
            if let player = GamePlayer.fromDictionary(playerDict) {
                players[playerId] = player
            }
        }
        
        guard let hostPlayer = players[hostId] else {
            return nil
        }
        
        var session = GameSession(id: id, hostId: hostId, hostPlayer: hostPlayer)
        session.players = players
        session.gameStarted = gameStarted
        session.createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        
        // Parse player roles
        if let rolesDict = dict["playerRoles"] as? [String: String] {
            var playerRoles: [String: PlayerRole] = [:]
            for (playerId, roleString) in rolesDict {
                if let role = PlayerRole(rawValue: roleString) {
                    playerRoles[playerId] = role
                }
            }
            session.playerRoles = playerRoles
        }
        
        // Parse game state
        if let gameStateDict = dict["gameState"] as? [String: Any] {
            session.gameState = GameState.fromDictionary(gameStateDict)
        }
        
        return session
    }
    
    var isHost: Bool {
        return players[hostId] != nil
    }
    
    var playersList: [GamePlayer] {
        return Array(players.values).sorted { $0.joinedAt < $1.joinedAt }
    }
}

struct GamePlayer: Codable, Equatable {
    let id: String
    let displayName: String
    let avatar: String
    let joinedAt: Date
    
    init(id: String, displayName: String, avatar: String) {
        self.id = id
        self.displayName = displayName
        self.avatar = avatar
        self.joinedAt = Date()
    }
    
    init(id: String, displayName: String, avatar: String, joinedAt: Date) {
        self.id = id
        self.displayName = displayName
        self.avatar = avatar
        self.joinedAt = joinedAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "displayName": displayName,
            "avatar": avatar,
            "joinedAt": joinedAt.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> GamePlayer? {
        guard let id = dict["id"] as? String,
              let displayName = dict["displayName"] as? String,
              let avatar = dict["avatar"] as? String,
              let joinedAtTimestamp = dict["joinedAt"] as? TimeInterval else {
            return nil
        }
        
        let joinedAt = Date(timeIntervalSince1970: joinedAtTimestamp)
        return GamePlayer(id: id, displayName: displayName, avatar: avatar, joinedAt: joinedAt)
    }
}

enum GameSessionError: Error, LocalizedError {
    case sessionNotFound
    case sessionFull
    case alreadyInSession
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Game session not found. Please check the code and try again."
        case .sessionFull:
            return "This game session is full."
        case .alreadyInSession:
            return "You're already in this game session."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}