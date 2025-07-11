import Foundation

/// Mock data for SwiftUI previews
struct PreviewData {
    
    // MARK: - Users
    static let sampleUser = User(
        id: "1",
        displayName: "John Doe",
        email: "john@example.com",
        avatar: "😀"
    )
    
    static let longNameUser = User(
        id: "2",
        displayName: "Alexander Maximilian Fitzgerald III",
        email: "alexander.maximilian.fitzgerald@verylongdomain.com",
        avatar: "👑"
    )
    
    static let noEmailUser = User(
        id: "3",
        displayName: "Anonymous User",
        email: nil,
        avatar: "🎭"
    )
    
    static let specialCharUser = User(
        id: "4",
        displayName: "José María García-López",
        email: "josé@example.com",
        avatar: "🌟"
    )
    
    // MARK: - Game Players
    static let hostPlayer = GamePlayer(
        id: "1",
        displayName: "Host Player",
        avatar: "👑"
    )
    
    static let player2 = GamePlayer(
        id: "2",
        displayName: "Player Two",
        avatar: "🎮"
    )
    
    static let player3 = GamePlayer(
        id: "3",
        displayName: "Third Player",
        avatar: "🎯"
    )
    
    static let longNamePlayer = GamePlayer(
        id: "4",
        displayName: "Alexander Maximilian Fitzgerald",
        avatar: "🎭"
    )
    
    // MARK: - Game Sessions
    static let emptyGameSession: GameSession = {
        let session = GameSession(id: "GAME123", hostId: "1", hostPlayer: hostPlayer)
        return session
    }()
    
    static let twoPlayerSession: GameSession = {
        var session = GameSession(id: "GAME456", hostId: "1", hostPlayer: hostPlayer)
        session.players["2"] = player2
        return session
    }()
    
    static let fullLobbySession: GameSession = {
        var session = GameSession(id: "GAME789", hostId: "1", hostPlayer: hostPlayer)
        session.players["2"] = player2
        session.players["3"] = player3
        session.players["4"] = longNamePlayer
        return session
    }()
    
    static let startedGameSession: GameSession = {
        var session = GameSession(id: "GAMEABC", hostId: "1", hostPlayer: hostPlayer)
        session.players["2"] = player2
        session.gameStarted = true
        session.playerRoles = ["1": .answerer, "2": .guesser]
        
        // Create a basic game state
        var gameState = GameState(answererID: "1", guesserIDs: ["2"])
        gameState.category = "Animals"
        gameState.secretWord = "Elephant"
        gameState.phase = .questioning
        var question = Question(askerID: "2", askerName: "Player Two", question: "Is it a mammal?")
        question.answer = "Yes"
        question.isAnswered = true
        question.timestamp = Date().addingTimeInterval(-60)
        gameState.questions = [question]
        session.gameState = gameState
        
        return session
    }()
    
    // MARK: - Game States for different phases
    static let setupPhaseGameSession: GameSession = {
        var session = startedGameSession
        session.gameState?.phase = .setup
        session.gameState?.questions = []
        return session
    }()
    
    static let gameOverSession: GameSession = {
        var session = startedGameSession
        session.gameState?.phase = .gameOver
        return session
    }()
    
    // MARK: - Questions for testing
    static let sampleQuestions: [Question] = {
        var q1 = Question(askerID: "2", askerName: "Player Two", question: "Is it bigger than a breadbox?")
        q1.answer = "Yes"
        q1.isAnswered = true
        q1.timestamp = Date().addingTimeInterval(-300)
        
        var q2 = Question(askerID: "2", askerName: "Player Two", question: "Can you find it in a house?")
        q2.answer = "No"
        q2.isAnswered = true
        q2.timestamp = Date().addingTimeInterval(-240)
        
        var q3 = Question(askerID: "2", askerName: "Player Two", question: "Is it alive?")
        q3.answer = "Yes"
        q3.isAnswered = true
        q3.timestamp = Date().addingTimeInterval(-180)
        
        var q4 = Question(askerID: "2", askerName: "Player Two", question: "Does it have four legs?")
        q4.answer = "Yes"
        q4.isAnswered = true
        q4.timestamp = Date().addingTimeInterval(-120)
        
        var q5 = Question(askerID: "2", askerName: "Player Two", question: "This is a really long question that tests how the UI handles text that might wrap to multiple lines in the question display area?")
        q5.answer = "Maybe, it depends on the specific circumstances and context"
        q5.isAnswered = true
        q5.timestamp = Date().addingTimeInterval(-60)
        
        return [q1, q2, q3, q4, q5]
    }()
    
    // MARK: - Game Session with lots of questions
    static let sessionWithManyQuestions: GameSession = {
        var session = startedGameSession
        session.gameState?.questions = sampleQuestions
        return session
    }()
}

// MARK: - GamePlayer Extension for Preview
extension GamePlayer {
    func toUser() -> User {
        return User(id: id, displayName: displayName, email: "\(displayName.lowercased().replacingOccurrences(of: " ", with: ""))@example.com", avatar: avatar)
    }
}