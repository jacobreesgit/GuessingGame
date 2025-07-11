import SwiftUI

struct MainMenuView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    let user: User
    @State private var showingProfile = false
    @State private var showingCreateGame = false
    @State private var showingJoinGame = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header with User Info
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingProfile = true
                        }) {
                            HStack(spacing: 8) {
                                Text(user.avatar)
                                    .font(.title2)
                                
                                Text(user.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    
                    Text(Strings.appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Game Options
                VStack(spacing: 24) {
                    // Create Game Button
                    Button(action: {
                        showingCreateGame = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Game.createGame)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(Strings.Game.Create.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    
                    // Join Game Button
                    Button(action: {
                        showingJoinGame = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Game.joinGame)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(Strings.Game.Join.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                    
                    // Game History Button
                    Button(action: {
                        // TODO: Navigate to game history
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Game.gameHistory)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("View your past games")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingProfile) {
                ProfileView(authViewModel: authViewModel, user: user)
            }
            .fullScreenCover(isPresented: $showingCreateGame) {
                CreateGameView(user: user)
            }
            .fullScreenCover(isPresented: $showingJoinGame) {
                JoinGameView(user: user)
            }
        }
    }
}

// MARK: - Previews
#Preview("Default User") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "John Doe", email: "john@example.com", avatar: "😀")
    )
}

#Preview("Long Display Name") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Alexander Maximilian", email: "alex@example.com", avatar: "👑")
    )
}

#Preview("No Email") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Anonymous", email: nil, avatar: "🎭")
    )
}

#Preview("Different Avatars") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Gamer", email: "gamer@example.com", avatar: "🎮")
    )
}

#Preview("Dark Mode") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Night Owl", email: "night@example.com", avatar: "🦉")
    )
    .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Accessible User", email: "access@example.com", avatar: "♿️")
    )
    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Compact", email: "small@example.com", avatar: "📱")
    )
}

#Preview("Landscape") {
    MainMenuView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Landscape User", email: "wide@example.com", avatar: "📺")
    )
}

