import SwiftUI

struct GameplayView: View {
    @StateObject private var gameplayViewModel: GameplayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLeaveConfirmation = false
    
    init(user: User, gameSession: GameSession) {
        self._gameplayViewModel = StateObject(wrappedValue: GameplayViewModel(user: user, gameSession: gameSession))
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch gameplayViewModel.gamePhase {
                case .setup:
                    setupPhaseView
                case .questioning:
                    questioningPhaseView
                case .gameOver:
                    GameOverView(gameplayViewModel: gameplayViewModel)
                }
            }
            .navigationTitle("GuessingGame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        showingLeaveConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    gameStatusIndicator
                }
            }
            .alert("Leave Game", isPresented: $showingLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    gameplayViewModel.leaveGame()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to leave this game?")
            }
            .alert("Error", isPresented: .constant(!gameplayViewModel.errorMessage.isEmpty)) {
                Button("OK") {
                    gameplayViewModel.errorMessage = ""
                }
            } message: {
                Text(gameplayViewModel.errorMessage)
            }
            .onChange(of: gameplayViewModel.gameSession?.gameStarted) { _, gameStarted in
                // Navigate back to lobby if game is reset
                if gameStarted == false {
                    dismiss()
                }
            }
        }
    }
    
    private var setupPhaseView: some View {
        VStack(spacing: 24) {
            if gameplayViewModel.isAnswerer {
                AnswererView(gameplayViewModel: gameplayViewModel)
            } else {
                waitingForAnswererView
            }
        }
    }
    
    private var questioningPhaseView: some View {
        GuesserView(gameplayViewModel: gameplayViewModel)
    }
    
    private var waitingForAnswererView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Text("⏳")
                    .font(.system(size: 60))
                
                Text("Waiting for Secret Word")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("The answerer is choosing a category and secret word")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Answerer info
            if let answerer = gameplayViewModel.gameSession?.players[gameplayViewModel.gameSession?.gameState?.answererID ?? ""] {
                VStack(spacing: 12) {
                    Text(answerer.avatar)
                        .font(.system(size: 50))
                        .padding()
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                    
                    Text("\(answerer.displayName) is the Answerer")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Round \(gameplayViewModel.roundNumber)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Loading indicator
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Please wait...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var gameStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(gameplayViewModel.isMyTurn ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(gameplayViewModel.isMyTurn ? "Your Turn" : "Wait")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct GameOverView: View {
    @ObservedObject var gameplayViewModel: GameplayViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Winner celebration
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("Game Over!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let winner = gameplayViewModel.winner {
                    VStack(spacing: 12) {
                        Text(winner.avatar)
                            .font(.system(size: 60))
                            .padding()
                            .background(Circle().fill(Color.yellow.opacity(0.2)))
                        
                        Text("\(winner.displayName) Wins!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        if winner.id == gameplayViewModel.currentUser.id {
                            Text("Congratulations! 🎊")
                                .font(.headline)
                                .foregroundColor(.orange)
                        } else {
                            Text("Better luck next time!")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("😔")
                            .font(.system(size: 60))
                        
                        Text("Game Ended")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Text("A player left the game")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Game summary
            VStack(spacing: 16) {
                Text("Game Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    GameSummaryRow(label: "Round", value: "\(gameplayViewModel.roundNumber)")
                    GameSummaryRow(label: "Category", value: gameplayViewModel.category)
                    GameSummaryRow(label: "Secret Word", value: gameplayViewModel.secretWord)
                    GameSummaryRow(label: "Questions Asked", value: "\(gameplayViewModel.questions.count)")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                if gameplayViewModel.isHost {
                    if gameplayViewModel.isLoading {
                        ProgressView("Starting new game...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Button(action: {
                            gameplayViewModel.playAgain()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Play Again")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            gameplayViewModel.resetToLobby()
                        }) {
                            HStack {
                                Image(systemName: "house")
                                Text("Back to Lobby")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    Text("Waiting for host to choose next action...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
}

struct GameSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct GameplayView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(id: "1", displayName: "Test User", avatar: "😀")
        let session = GameSession(id: "ABC123", hostId: "1", hostPlayer: GamePlayer(id: "1", displayName: "Test User", avatar: "😀"))
        
        GameplayView(user: user, gameSession: session)
    }
}