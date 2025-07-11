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
    
    private let database = Database.database().reference()
    private var sessionListener: DatabaseHandle?
    
    init(user: User, gameSession: GameSession) {
        self.currentUser = user
        self.gameSession = gameSession
        startListening()
    }
    
    deinit {
        if let listener = sessionListener {
            database.removeObserver(withHandle: listener)
        }
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
        }
        
        updateGameState(gameState)
    }
    
    func playAgain() {
        guard let session = gameSession,
              session.hostId == currentUser.id else {
            errorMessage = "Only the host can start a new game"
            return
        }
        
        // Reset game state for new round
        let playerIDs = Array(session.players.keys)
        let shuffledPlayers = playerIDs.shuffled()
        let answererID = shuffledPlayers.first!
        let guesserIDs = Array(shuffledPlayers.dropFirst())
        
        var newGameState = GameState(answererID: answererID, guesserIDs: guesserIDs)
        if let currentGameState = session.gameState {
            newGameState.roundNumber = currentGameState.roundNumber + 1
        }
        
        var updatedSession = session
        updatedSession.gameState = newGameState
        
        // Reassign roles
        for playerID in playerIDs {
            updatedSession.playerRoles[playerID] = playerID == answererID ? .answerer : .guesser
        }
        
        database.child("sessions").child(session.id).setValue(updatedSession.toDictionary()) { [weak self] error, _ in
            if let error = error {
                Task { @MainActor in
                    self?.errorMessage = "Failed to start new game: \(error.localizedDescription)"
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
}