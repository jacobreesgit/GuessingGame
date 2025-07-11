import SwiftUI

struct GameLobbyView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLeaveConfirmation = false
    @State private var navigateToGameplay = false
    @State private var shouldDismissToRoot = false
    let user: User
    let onDismissToHome: (() -> Void)?
    
    init(user: User) {
        self.user = user
        self.onDismissToHome = nil
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user))
    }
    
    init(user: User, initialGameSession: GameSession, onDismissToHome: (() -> Void)? = nil) {
        self.user = user
        self.onDismissToHome = onDismissToHome
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user, initialGameSession: initialGameSession))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if lobbyViewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if lobbyViewModel.isConnected {
                    lobbyContent
                } else {
                    Text("Not connected to any game")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Game Lobby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        showingLeaveConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Leave Game", isPresented: $showingLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    lobbyViewModel.leaveGame()
                    shouldDismissToRoot = true
                }
            } message: {
                Text("Are you sure you want to leave this game?")
            }
            .alert("Error", isPresented: .constant(!lobbyViewModel.errorMessage.isEmpty)) {
                Button("OK") {
                    lobbyViewModel.errorMessage = ""
                }
            } message: {
                Text(lobbyViewModel.errorMessage)
            }
            .alert("Host Transfer", isPresented: .constant(!lobbyViewModel.hostTransferMessage.isEmpty)) {
                Button("OK") {
                    lobbyViewModel.hostTransferMessage = ""
                }
            } message: {
                Text(lobbyViewModel.hostTransferMessage)
            }
            .onChange(of: lobbyViewModel.gameStarted) { _, started in
                if started {
                    navigateToGameplay = true
                }
            }
            .onChange(of: shouldDismissToRoot) { _, shouldDismiss in
                if shouldDismiss {
                    onDismissToHome?()
                    dismiss()
                }
            }
            .fullScreenCover(isPresented: $navigateToGameplay) {
                if let gameSession = lobbyViewModel.gameSession {
                    GameplayView(user: user, gameSession: gameSession, onDismissToHome: onDismissToHome)
                }
            }
        }
    }
    
    @ViewBuilder
    private var lobbyContent: some View {
        VStack(spacing: 24) {
            // Game Code Section
            gameCodeSection
            
            // Players Section
            playersSection
            
            Spacer()
            
            // Start Game Button (Host Only)
            if lobbyViewModel.isHost {
                startGameButton
            }
        }
        .padding()
    }
    
    private var gameCodeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(lobbyViewModel.isHost ? "Your Game Code" : "Game Code")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                
                if lobbyViewModel.isHost {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(lobbyViewModel.gameCode)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .tracking(4)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .accessibilityLabel("Game code: \(lobbyViewModel.gameCode.map { String($0) }.joined(separator: " "))")
                    .accessibilityHint("Six character game code for others to join")
                
                HStack(spacing: 12) {
                    Button(action: {
                        UIPasteboard.general.string = lobbyViewModel.gameCode
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy game code")
                    .accessibilityHint("Copies the game code to clipboard")
                    
                    ShareLink(item: "Join my GuessingGame! Use code: \(lobbyViewModel.gameCode)") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share game code")
                    .accessibilityHint("Opens share sheet to invite friends")
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        lobbyViewModel.isHost ? Color(UIColor.systemBlue).opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: lobbyViewModel.isHost ? Color(UIColor.systemBlue).opacity(0.1) : Color.clear,
                radius: lobbyViewModel.isHost ? 4 : 0,
                x: 0,
                y: 2
            )
            
            Text(lobbyViewModel.isHost ? "Share this code with friends to join your game" : "Others can join using this code")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var playersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Players")
                    .font(.headline)
                
                Spacer()
                
                Text("\(lobbyViewModel.playerCount)/8")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("\(lobbyViewModel.playerCount) of 8 players")
            }
            
            LazyVStack(spacing: 12) {
                ForEach(lobbyViewModel.players, id: \.id) { player in
                    PlayerRowView(
                        player: player,
                        isHost: player.id == lobbyViewModel.gameSession?.hostId
                    )
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private var startGameButton: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            lobbyViewModel.startGame()
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Game")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                lobbyViewModel.playerCount < 2 ? 
                Color(UIColor.systemGray3) : 
                Color(UIColor.systemGreen)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .disabled(lobbyViewModel.playerCount < 2)
        .animation(.easeInOut(duration: 0.2), value: lobbyViewModel.playerCount)
        .accessibilityLabel("Start game")
        .accessibilityHint(lobbyViewModel.playerCount < 2 ? "Need at least 2 players to start" : "Starts the guessing game")
    }
}

struct PlayerRowView: View {
    let player: GamePlayer
    let isHost: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Text(player.avatar)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(UIColor.systemGray6))
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
            
            // Player Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if isHost {
                        Text("HOST")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.systemOrange))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            )
                    }
                }
                
                Text("Joined \(formatJoinTime(player.joinedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Indicator
            Circle()
                .fill(Color(UIColor.systemGreen))
                .frame(width: 8, height: 8)
                .shadow(color: Color.green.opacity(0.4), radius: 2, x: 0, y: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.displayName)\(isHost ? ", host" : ""), joined at \(formatJoinTime(player.joinedAt)), online")
        .accessibilityAddTraits(isHost ? .isHeader : [])
    }
    
    private func formatJoinTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews
#Preview("Empty Lobby - Host") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.emptyGameSession,
        onDismissToHome: {}
    )
}

#Preview("Two Players - Host") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.twoPlayerSession,
        onDismissToHome: {}
    )
}

#Preview("Full Lobby - Host") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.fullLobbySession,
        onDismissToHome: {}
    )
}

#Preview("Two Players - Guest") {
    GameLobbyView(
        user: PreviewData.player2.toUser(),
        initialGameSession: PreviewData.twoPlayerSession,
        onDismissToHome: {}
    )
}

#Preview("Long Names") {
    let session = GameSession(id: "LONG123", hostId: "4", hostPlayer: PreviewData.longNamePlayer)
    return GameLobbyView(
        user: PreviewData.longNameUser,
        initialGameSession: session,
        onDismissToHome: {}
    )
}

#Preview("Dark Mode") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.twoPlayerSession,
        onDismissToHome: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.fullLobbySession,
        onDismissToHome: {}
    )
    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    GameLobbyView(
        user: PreviewData.sampleUser,
        initialGameSession: PreviewData.twoPlayerSession,
        onDismissToHome: {}
    )
}

