import SwiftUI
import Combine

struct CreateGameView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @StateObject private var createGameViewModel: CreateGameViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLobby = false
    @State private var shouldDismissToHome = false
    let user: User
    
    init(user: User) {
        self.user = user
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user))
        self._createGameViewModel = StateObject(wrappedValue: CreateGameViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor.systemBlue))
                    
                    Text(Strings.Game.Create.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(Strings.Game.Create.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Game Info
                VStack(spacing: 20) {
                    InfoRowView(
                        icon: "person.2.fill",
                        title: Strings.Game.players,
                        description: "2-8 players",
                        color: Color(UIColor.systemGreen)
                    )
                    
                    InfoRowView(
                        icon: "clock.fill",
                        title: Strings.Game.Create.duration,
                        description: "5-15 minutes",
                        color: Color(UIColor.systemOrange)
                    )
                    
                    InfoRowView(
                        icon: "gamecontroller.fill",
                        title: Strings.Game.Create.gameMode,
                        description: Strings.Game.Create.multiplayerGuessing,
                        color: Color(UIColor.systemPurple)
                    )
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
                
                // Create Game Button
                Button(action: {
                    if networkMonitor.isConnected {
                        lobbyViewModel.createGame()
                    } else {
                        createGameViewModel.showOfflineError()
                    }
                }) {
                    HStack {
                        if lobbyViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(lobbyViewModel.isLoading ? Strings.Game.Create.creating : Strings.Game.createGame)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(lobbyViewModel.isLoading || !networkMonitor.isConnected)
                
                // Cancel Button
                Button(Strings.cancel) {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationTitle(Strings.Game.Create.title)
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

struct InfoRowView: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Previews
#Preview("Default State") {
    CreateGameView(user: User(id: "1", displayName: "John Doe", email: "john@example.com", avatar: "😀"))
}

#Preview("Long Display Name") {
    CreateGameView(user: User(id: "1", displayName: "Alexander Maximilian", email: "alex@example.com", avatar: "👑"))
}

#Preview("Different Avatar") {
    CreateGameView(user: User(id: "1", displayName: "Gamer Pro", email: "pro@example.com", avatar: "🎮"))
}

#Preview("Dark Mode") {
    CreateGameView(user: User(id: "1", displayName: "Night Player", email: "night@example.com", avatar: "🌙"))
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    CreateGameView(user: User(id: "1", displayName: "Accessible User", email: "access@example.com", avatar: "♿️"))
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    CreateGameView(user: User(id: "1", displayName: "Compact", email: "small@example.com", avatar: "📱"))
}

#Preview("Loading State") {
    // Note: Would need to mock loading state in real implementation
    CreateGameView(user: User(id: "1", displayName: "Loading User", email: "load@example.com", avatar: "⏳"))
}