import SwiftUI

struct CreateGameView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLobby = false
    let user: User
    
    init(user: User) {
        self.user = user
        self._lobbyViewModel = StateObject(wrappedValue: GameLobbyViewModel(user: user))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Game")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start a new multiplayer guessing game and invite your friends to join")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Game Info
                VStack(spacing: 20) {
                    InfoRowView(
                        icon: "person.2.fill",
                        title: "Players",
                        description: "2-8 players",
                        color: .green
                    )
                    
                    InfoRowView(
                        icon: "clock.fill",
                        title: "Duration",
                        description: "5-15 minutes",
                        color: .orange
                    )
                    
                    InfoRowView(
                        icon: "gamecontroller.fill",
                        title: "Game Mode",
                        description: "Multiplayer Guessing",
                        color: .purple
                    )
                }
                
                Spacer()
                
                // Create Game Button
                Button(action: {
                    lobbyViewModel.createGame()
                }) {
                    HStack {
                        if lobbyViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(lobbyViewModel.isLoading ? "Creating..." : "Create Game")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(lobbyViewModel.isLoading)
                
                // Cancel Button
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Create Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(!lobbyViewModel.errorMessage.isEmpty)) {
                Button("OK") {
                    lobbyViewModel.errorMessage = ""
                }
            } message: {
                Text(lobbyViewModel.errorMessage)
            }
            .onChange(of: lobbyViewModel.isConnected) { _, connected in
                if connected {
                    navigateToLobby = true
                }
            }
            .fullScreenCover(isPresented: $navigateToLobby) {
                GameLobbyView(user: user)
            }
        }
    }
    
}

struct InfoRowView: View {
    let icon: String
    let title: String
    let description: String
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
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView(user: User(id: "1", displayName: "Test User", avatar: "😀"))
    }
}