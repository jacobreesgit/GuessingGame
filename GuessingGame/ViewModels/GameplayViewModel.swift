import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class GameplayViewModel: ObservableObject {
    @Published var gameSession: GameSession?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var currentUser: User
    @Published var timeRemaining: Int = 30
    @Published var isTimerRunning = false
    
    private let database = Database.database().reference()
    private var sessionListener: DatabaseHandle?
    private var turnTimer: Timer?
    
    init(user: User, gameSession: GameSession) {
        self.currentUser = user
        self.gameSession = gameSession
        startListening()
    }
    
    deinit {
        if let listener = sessionListener {
            database.removeObserver(withHandle: listener)
        }
        turnTimer?.invalidate()
    }
    
    // MARK: - Game Management
    
    func startGameplay() {
        guard let session = gameSession,
              session.hostId == currentUser.id else {
            errorMessage = "Only the host can start the game"
            return
        }
        
        isLoading = true
        
        // Assign roles randomly
        let playerIDs = Array(session.players.keys)
        let shuffledPlayers = playerIDs.shuffled()
        let answererID = shuffledPlayers.first!
        let guesserIDs = Array(shuffledPlayers.dropFirst())
        
        // Create initial game state
        let gameState = GameState(answererID: answererID, guesserIDs: guesserIDs)
        
        // Update session with roles and game state
        var updatedSession = session
        updatedSession.gameState = gameState
        
        // Assign roles
        for playerID in playerIDs {
            updatedSession.playerRoles[playerID] = playerID == answererID ? .answerer : .guesser
        }
        
        // Save to Firebase
        database.child("sessions").child(session.id).setValue(updatedSession.toDictionary()) { [weak self] error, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Failed to start game: \(error.localizedDescription)"
                    self.isLoading = false
                } else {
                    self.isLoading = false
                    print("Game started successfully")
                }
            }
        }
    }
    
    func setSecretWord(category: String, word: String) {
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.answererID == currentUser.id else {
            errorMessage = "Only the answerer can set the secret word"
            return
        }
        
        gameState.category = category
        gameState.secretWord = word
        gameState.phase = .questioning
        gameState.turnStartTime = Date()
        
        updateGameState(gameState)
    }
    
    func askQuestion(_ questionText: String) {
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.currentTurnPlayerID == currentUser.id,
              gameState.phase == .questioning else {
            errorMessage = "It's not your turn to ask a question"
            return
        }
        
        let question = Question(
            askerID: currentUser.id,
            askerName: currentUser.displayName,
            question: questionText
        )
        
        gameState.addQuestion(question)
        updateGameState(gameState)
    }
    
    func answerQuestion(questionID: String, answer: String) {
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.answererID == currentUser.id else {
            errorMessage = "Only the answerer can answer questions"
            return
        }
        
        gameState.answerQuestion(questionID: questionID, answer: answer)
        gameState.nextTurn()
        gameState.turnStartTime = Date()
        updateGameState(gameState)
    }
    
    func makeGuess(_ guess: String) {
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.currentTurnPlayerID == currentUser.id else {
            errorMessage = "It's not your turn to make a guess"
            return
        }
        
        if gameState.isCorrectGuess(guess) {
            // Winner!
            gameState.winnerID = currentUser.id
            gameState.phase = .gameOver
        } else {
            // Incorrect guess, continue game
            gameState.nextTurn()
            gameState.turnStartTime = Date()
        }
        
        updateGameState(gameState)
    }
    
    func playAgain() {
        guard let session = gameSession,
              session.hostId == currentUser.id else {
            errorMessage = "Only the host can start a new game"
            return
        }
        
        isLoading = true
        
        // Reset game state for new round
        let playerIDs = Array(session.players.keys)
        guard playerIDs.count >= 2 else {
            errorMessage = "Need at least 2 players to start a new game"
            isLoading = false
            return
        }
        
        let shuffledPlayers = playerIDs.shuffled()
        let answererID = shuffledPlayers.first!
        let guesserIDs = Array(shuffledPlayers.dropFirst())
        
        var newGameState = GameState(answererID: answererID, guesserIDs: guesserIDs)
        if let currentGameState = session.gameState {
            newGameState.roundNumber = currentGameState.roundNumber + 1
        }
        
        var updatedSession = session
        updatedSession.gameState = newGameState
        
        // Reassign roles for new round
        updatedSession.playerRoles.removeAll()
        for playerID in playerIDs {
            updatedSession.playerRoles[playerID] = playerID == answererID ? .answerer : .guesser
        }
        
        // Clear previous game data but keep players
        database.child("sessions").child(session.id).child("gameState").setValue(newGameState.toDictionary()) { [weak self] error, _ in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = "Failed to start new game: \(error.localizedDescription)"
                    self?.isLoading = false
                } else {
                    // Update player roles
                    let roleUpdates = updatedSession.playerRoles.mapValues { $0.rawValue }
                    self?.database.child("sessions").child(session.id).child("playerRoles").setValue(roleUpdates) { [weak self] error, _ in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            if let error = error {
                                self?.errorMessage = "Failed to update roles: \(error.localizedDescription)"
                            } else {
                                print("New game started successfully!")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetToLobby() {
        guard let session = gameSession,
              session.hostId == currentUser.id else {
            errorMessage = "Only the host can reset to lobby"
            return
        }
        
        isLoading = true
        
        // Reset session to lobby state
        var updatedSession = session
        updatedSession.gameState = nil
        updatedSession.gameStarted = false
        updatedSession.playerRoles.removeAll()
        
        database.child("sessions").child(session.id).setValue(updatedSession.toDictionary()) { [weak self] error, _ in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = "Failed to reset to lobby: \(error.localizedDescription)"
                    self?.isLoading = false
                } else {
                    self?.isLoading = false
                    print("Reset to lobby successfully!")
                }
            }
        }
    }
    
    private func updateGameState(_ gameState: GameState) {
        guard let session = gameSession else { return }
        
        var updatedSession = session
        updatedSession.gameState = gameState
        
        database.child("sessions").child(session.id).child("gameState").setValue(gameState.toDictionary()) { [weak self] error, _ in
            if let error = error {
                Task { @MainActor in
                    self?.errorMessage = "Failed to update game: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Turn Timer Management
    
    private func startTurnTimer() {
        stopTurnTimer()
        
        guard let gameState = gameSession?.gameState,
              let turnStartTime = gameState.turnStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(turnStartTime)
        let remaining = max(0, Double(gameState.turnTimeLimit) - elapsed)
        
        timeRemaining = Int(remaining)
        
        if remaining > 0 {
            isTimerRunning = true
            turnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateTimer()
                }
            }
        } else {
            handleTurnTimeout()
        }
    }
    
    private func stopTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
        isTimerRunning = false
    }
    
    private func updateTimer() {
        guard let gameState = gameSession?.gameState,
              let turnStartTime = gameState.turnStartTime else {
            stopTurnTimer()
            return
        }
        
        let elapsed = Date().timeIntervalSince(turnStartTime)
        let remaining = max(0, Double(gameState.turnTimeLimit) - elapsed)
        
        timeRemaining = Int(remaining)
        
        if remaining <= 0 {
            handleTurnTimeout()
        }
    }
    
    private func handleTurnTimeout() {
        stopTurnTimer()
        
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.phase == .questioning,
              gameState.currentTurnPlayerID == currentUser.id,
              isGuesser else { return }
        
        // Skip turn due to timeout
        gameState.nextTurn()
        gameState.turnStartTime = Date()
        updateGameState(gameState)
    }
    
    func skipTurn() {
        guard let session = gameSession,
              var gameState = session.gameState,
              gameState.currentTurnPlayerID == currentUser.id else {
            errorMessage = "It's not your turn to skip"
            return
        }
        
        gameState.nextTurn()
        gameState.turnStartTime = Date()
        updateGameState(gameState)
    }
    
    func addEmojiReaction(_ emoji: String) {
        guard let session = gameSession,
              var gameState = session.gameState else { return }
        
        let reaction = EmojiReaction(
            playerID: currentUser.id,
            playerName: currentUser.displayName,
            emoji: emoji
        )
        
        gameState.reactions.append(reaction)
        updateGameState(gameState)
    }
    
    func leaveGame() {
        guard let session = gameSession else { return }
        
        let wasHost = session.hostId == currentUser.id
        let remainingPlayers = session.players.filter { $0.key != currentUser.id }
        
        if remainingPlayers.isEmpty {
            // Last player leaving, delete the session
            database.child("sessions").child(session.id).removeValue() { error, _ in
                if let error = error {
                    print("Failed to delete session: \(error.localizedDescription)")
                } else {
                    print("Session deleted successfully")
                }
            }
            return
        }
        
        // Handle game state when player leaves during active game
        if var gameState = session.gameState, session.gameStarted {
            let currentPlayerRole = session.playerRoles[currentUser.id]
            
            if currentPlayerRole == .answerer {
                // If answerer leaves, end the game
                gameState.phase = .gameOver
                gameState.winnerID = nil // No winner due to answerer leaving
            } else if currentPlayerRole == .guesser {
                // Remove from turn order if it's a guesser
                gameState.turnOrder.removeAll { $0 == currentUser.id }
                
                // If current turn player is leaving, advance to next
                if gameState.currentTurnPlayerID == currentUser.id && !gameState.turnOrder.isEmpty {
                    gameState.currentTurnPlayerID = gameState.turnOrder.first!
                    gameState.turnStartTime = Date()
                }
                
                // If no guessers left, end the game
                if gameState.turnOrder.isEmpty {
                    gameState.phase = .gameOver
                    gameState.winnerID = gameState.answererID // Answerer wins by default
                }
            }
            
            // Update the game state
            updateGameState(gameState)
        }
        
        if wasHost {
            // Transfer host to another player
            let newHostId = remainingPlayers.keys.randomElement()!
            let updates: [String: Any] = [
                "hostId": newHostId,
                "players/\(currentUser.id)": NSNull(),
                "playerRoles/\(currentUser.id)": NSNull()
            ]
            
            database.child("sessions").child(session.id).updateChildValues(updates) { error, _ in
                if let error = error {
                    print("Failed to transfer host and leave: \(error.localizedDescription)")
                } else {
                    print("Host transferred and left successfully")
                }
            }
        } else {
            // Regular player leaving
            let updates: [String: Any] = [
                "players/\(currentUser.id)": NSNull(),
                "playerRoles/\(currentUser.id)": NSNull()
            ]
            
            database.child("sessions").child(session.id).updateChildValues(updates) { error, _ in
                if let error = error {
                    print("Failed to leave game: \(error.localizedDescription)")
                } else {
                    print("Successfully left game")
                }
            }
        }
    }
    
    // MARK: - Real-time Listeners
    
    private func startListening() {
        guard let session = gameSession else { return }
        
        sessionListener = database.child("sessions").child(session.id).observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            Task { @MainActor in
                if !snapshot.exists() {
                    self.errorMessage = "Game session ended"
                    return
                }
                
                guard let sessionData = snapshot.value as? [String: Any],
                      let updatedSession = GameSession.fromDictionary(sessionData) else {
                    self.errorMessage = "Invalid session data"
                    return
                }
                
                self.gameSession = updatedSession
                
                // Update timer when game state changes
                if let gameState = updatedSession.gameState {
                    if gameState.phase == .questioning && 
                       gameState.currentTurnPlayerID == self.currentUser.id &&
                       self.isGuesser {
                        self.startTurnTimer()
                    } else {
                        self.stopTurnTimer()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var currentPlayerRole: PlayerRole? {
        return gameSession?.playerRoles[currentUser.id]
    }
    
    var isAnswerer: Bool {
        return currentPlayerRole == .answerer
    }
    
    var isGuesser: Bool {
        return currentPlayerRole == .guesser
    }
    
    var isMyTurn: Bool {
        guard let gameState = gameSession?.gameState else { return false }
        
        if gameState.phase == .setup && isAnswerer {
            return true
        }
        
        if gameState.phase == .questioning {
            if isAnswerer && gameState.unansweredQuestions.count > 0 {
                return true
            }
            if isGuesser && gameState.currentTurnPlayerID == currentUser.id {
                return true
            }
        }
        
        return false
    }
    
    var currentTurnPlayer: GamePlayer? {
        guard let session = gameSession,
              let gameState = session.gameState else { return nil }
        
        if gameState.phase == .setup {
            return session.players[gameState.answererID]
        } else {
            return session.players[gameState.currentTurnPlayerID]
        }
    }
    
    var winner: GamePlayer? {
        guard let session = gameSession,
              let gameState = session.gameState,
              let winnerID = gameState.winnerID else { return nil }
        
        return session.players[winnerID]
    }
    
    var gamePhase: GamePhase {
        return gameSession?.gameState?.phase ?? .setup
    }
    
    var questions: [Question] {
        return gameSession?.gameState?.questions ?? []
    }
    
    var latestUnansweredQuestion: Question? {
        return gameSession?.gameState?.unansweredQuestions.last
    }
    
    var secretWord: String {
        return gameSession?.gameState?.secretWord ?? ""
    }
    
    var category: String {
        return gameSession?.gameState?.category ?? ""
    }
    
    var roundNumber: Int {
        return gameSession?.gameState?.roundNumber ?? 1
    }
    
    var isHost: Bool {
        guard let session = gameSession else { return false }
        return session.hostId == currentUser.id
    }
    
    var reactions: [EmojiReaction] {
        return gameSession?.gameState?.reactions ?? []
    }
    
    var recentReactions: [EmojiReaction] {
        let cutoff = Date().addingTimeInterval(-10) // Last 10 seconds
        return reactions.filter { $0.timestamp > cutoff }
    }
}