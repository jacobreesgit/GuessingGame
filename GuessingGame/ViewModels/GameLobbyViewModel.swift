import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

@MainActor
class GameLobbyViewModel: ObservableObject {
    @Published var gameSession: GameSession?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isConnected = false
    @Published var gameStarted = false
    
    private let database = Database.database().reference()
    private var sessionListener: DatabaseHandle?
    private var currentUser: User
    
    init(user: User) {
        self.currentUser = user
    }
    
    deinit {
        if let listener = sessionListener {
            database.removeObserver(withHandle: listener)
        }
    }
    
    // MARK: - Session Management
    
    func createGame() {
        isLoading = true
        errorMessage = ""
        
        let gameCode = generateGameCode()
        let hostPlayer = GamePlayer(
            id: currentUser.id,
            displayName: currentUser.displayName,
            avatar: currentUser.avatar
        )
        
        let session = GameSession(
            id: gameCode,
            hostId: currentUser.id,
            hostPlayer: hostPlayer
        )
        
        database.child("sessions").child(gameCode).setValue(session.toDictionary()) { [weak self] error, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Failed to create game: \(error.localizedDescription)"
                    self.isLoading = false
                } else {
                    self.gameSession = session
                    self.startListening(to: gameCode)
                    self.isLoading = false
                    self.isConnected = true
                    print("Game created successfully with code: \(gameCode)")
                }
            }
        }
    }
    
    func joinGame(code: String) {
        guard !code.isEmpty else {
            errorMessage = "Please enter a game code"
            return
        }
        
        let gameCode = code.uppercased()
        isLoading = true
        errorMessage = ""
        
        // First check if session exists
        database.child("sessions").child(gameCode).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            Task { @MainActor in
                if !snapshot.exists() {
                    self.errorMessage = "Game session not found. Please check the code and try again."
                    self.isLoading = false
                    return
                }
                
                guard let sessionData = snapshot.value as? [String: Any],
                      let session = GameSession.fromDictionary(sessionData) else {
                    self.errorMessage = "Invalid game session data"
                    self.isLoading = false
                    return
                }
                
                // Check if game has already started
                if session.gameStarted {
                    self.errorMessage = "This game has already started"
                    self.isLoading = false
                    return
                }
                
                // Check if player is already in the session
                if session.players.keys.contains(self.currentUser.id) {
                    self.errorMessage = "You're already in this game"
                    self.isLoading = false
                    return
                }
                
                // Add player to session
                let newPlayer = GamePlayer(
                    id: self.currentUser.id,
                    displayName: self.currentUser.displayName,
                    avatar: self.currentUser.avatar
                )
                
                self.database.child("sessions").child(gameCode).child("players").child(self.currentUser.id).setValue(newPlayer.toDictionary()) { [weak self] error, _ in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        if let error = error {
                            self.errorMessage = "Failed to join game: \(error.localizedDescription)"
                            self.isLoading = false
                        } else {
                            self.gameSession = session
                            self.startListening(to: gameCode)
                            self.isLoading = false
                            self.isConnected = true
                            print("Successfully joined game with code: \(gameCode)")
                        }
                    }
                }
            }
        }
    }
    
    func startGame() {
        guard let session = gameSession,
              session.hostId == currentUser.id else {
            errorMessage = "Only the host can start the game"
            return
        }
        
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
        
        // Mark game as started
        updatedSession.gameStarted = true
        
        database.child("sessions").child(session.id).setValue(updatedSession.toDictionary()) { [weak self] error, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Failed to start game: \(error.localizedDescription)"
                } else {
                    print("Game started successfully")
                }
            }
        }
    }
    
    func leaveGame() {
        guard let session = gameSession else { return }
        
        // Remove player from session
        database.child("sessions").child(session.id).child("players").child(currentUser.id).removeValue() { [weak self] error, _ in
            if let error = error {
                print("Failed to leave game: \(error.localizedDescription)")
            } else {
                print("Successfully left game")
            }
            
            Task { @MainActor in
                await self?.cleanup()
            }
        }
    }
    
    // MARK: - Real-time Listeners
    
    private func startListening(to gameCode: String) {
        removeSessionListener()
        
        sessionListener = database.child("sessions").child(gameCode).observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            Task { @MainActor in
                if !snapshot.exists() {
                    // Session was deleted
                    self.errorMessage = "Game session ended"
                    await self.cleanup()
                    return
                }
                
                guard let sessionData = snapshot.value as? [String: Any],
                      let session = GameSession.fromDictionary(sessionData) else {
                    self.errorMessage = "Invalid session data"
                    return
                }
                
                // Check if current user is still in the session
                if !session.players.keys.contains(self.currentUser.id) {
                    self.errorMessage = "You have been removed from the game"
                    await self.cleanup()
                    return
                }
                
                self.gameSession = session
                
                // Check if game has started
                if session.gameStarted && !self.gameStarted {
                    self.gameStarted = true
                    print("Game has started!")
                }
            }
        }
    }
    
    private func removeSessionListener() {
        if let listener = sessionListener {
            database.removeObserver(withHandle: listener)
            sessionListener = nil
        }
    }
    
    private func cleanup() async {
        removeSessionListener()
        gameSession = nil
        isConnected = false
        gameStarted = false
    }
    
    // MARK: - Helper Methods
    
    private func generateGameCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    var isHost: Bool {
        guard let session = gameSession else { return false }
        return session.hostId == currentUser.id
    }
    
    var playerCount: Int {
        return gameSession?.players.count ?? 0
    }
    
    var players: [GamePlayer] {
        return gameSession?.playersList ?? []
    }
    
    var gameCode: String {
        return gameSession?.id ?? ""
    }
}