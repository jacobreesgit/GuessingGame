import SwiftUI

struct GameLobbyView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLeaveConfirmation = false
    
    init(user: User) {
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user))
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
                    dismiss()
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
            .onChange(of: lobbyViewModel.gameStarted) { _, started in
                if started {
                    // Navigate to game screen
                    // TODO: Navigate to actual game view
                    print("Game started! Navigate to game screen...")
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
            Text("Game Code")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(lobbyViewModel.gameCode)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .tracking(4)
                    .foregroundColor(.primary)
                
                Button(action: {
                    UIPasteboard.general.string = lobbyViewModel.gameCode
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Text("Share this code with friends to join")
                .font(.caption)
                .foregroundColor(.secondary)
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
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var startGameButton: some View {
        Button(action: {
            lobbyViewModel.startGame()
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Game")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(lobbyViewModel.playerCount < 2)
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
                .background(Circle().fill(Color.gray.opacity(0.1)))
            
            // Player Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if isHost {
                        Text("HOST")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text("Joined \(formatJoinTime(player.joinedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Indicator
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func formatJoinTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct GameLobbyView_Previews: PreviewProvider {
    static var previews: some View {
        GameLobbyView(user: User(id: "1", displayName: "Test User", avatar: "😀"))
    }
}