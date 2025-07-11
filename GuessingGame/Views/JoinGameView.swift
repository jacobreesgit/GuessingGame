import SwiftUI
import Combine

struct JoinGameView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @StateObject private var joinGameViewModel: JoinGameViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLobby = false
    @State private var shouldDismissToHome = false
    let user: User
    
    init(user: User) {
        self.user = user
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user))
        self._joinGameViewModel = StateObject(wrappedValue: JoinGameViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor.systemGreen))
                    
                    Text(Strings.Game.Join.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(Strings.Game.Join.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Game Code Input
                VStack(spacing: 16) {
                    Text(Strings.Game.gameCode)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField(Strings.Game.Join.enterGameCode, text: $joinGameViewModel.gameCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .frame(height: 50)
                    
                    Text(Strings.Game.Join.gameCodesSixCharacters)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Offline Warning
                if !networkMonitor.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        Text(Strings.Error.Game.needInternetConnection)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Join Button
                Button(action: {
                    if networkMonitor.isConnected {
                        lobbyViewModel.joinGame(code: joinGameViewModel.gameCode)
                    } else {
                        joinGameViewModel.showOfflineError()
                    }
                }) {
                    HStack {
                        if lobbyViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(lobbyViewModel.isLoading ? Strings.Game.Join.joining : Strings.Game.joinGame)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(joinGameViewModel.isValidGameCode && networkMonitor.isConnected ? Color(UIColor.systemGreen) : Color(UIColor.systemGray3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(!joinGameViewModel.isValidGameCode || lobbyViewModel.isLoading || !networkMonitor.isConnected)
                
                // Cancel Button
                Button(Strings.cancel) {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationTitle(Strings.Game.Join.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.cancel) {
                        dismiss()
                    }
                }
            }
            .onChange(of: lobbyViewModel.isConnected) { _, connected in
                if connected {
                    navigateToLobby = true
                }
            }
            .fullScreenCover(isPresented: $navigateToLobby, onDismiss: {
                if shouldDismissToHome {
                    dismiss()
                }
            }) {
                if let gameSession = lobbyViewModel.gameSession {
                    GameLobbyView(user: user, initialGameSession: gameSession) {
                        shouldDismissToHome = true
                    }
                }
            }
        }
    }
    
}

// MARK: - Previews
#Preview("Default State") {
    JoinGameView(user: User(id: "1", displayName: "John Doe", email: "john@example.com", avatar: "😀"))
}

#Preview("Long Display Name") {
    JoinGameView(user: User(id: "1", displayName: "Alexander Maximilian", email: "alex@example.com", avatar: "👑"))
}

#Preview("Different Avatar") {
    JoinGameView(user: User(id: "1", displayName: "Player Two", email: "player2@example.com", avatar: "🎯"))
}

#Preview("Dark Mode") {
    JoinGameView(user: User(id: "1", displayName: "Night Joiner", email: "night@example.com", avatar: "🌙"))
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    JoinGameView(user: User(id: "1", displayName: "Accessible User", email: "access@example.com", avatar: "♿️"))
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    JoinGameView(user: User(id: "1", displayName: "Compact", email: "small@example.com", avatar: "📱"))
}

#Preview("Code Partially Entered") {
    // Note: Would need to pre-populate game code for this preview
    JoinGameView(user: User(id: "1", displayName: "Typing User", email: "type@example.com", avatar: "⌨️"))
}

#Preview("Loading State") {
    // Note: Would need to mock loading state in real implementation
    JoinGameView(user: User(id: "1", displayName: "Joining User", email: "join@example.com", avatar: "⏳"))
}