import SwiftUI

struct JoinGameView: View {
    @StateObject private var lobbyViewModel: GameLobbyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var gameCode = ""
    @State private var navigateToLobby = false
    @State private var shouldDismissToHome = false
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
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor.systemGreen))
                    
                    Text("Join Game")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter the 6-character game code to join a multiplayer game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Game Code Input
                VStack(spacing: 16) {
                    Text("Game Code")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("Enter game code", text: $gameCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .frame(height: 50)
                        .onChange(of: gameCode) { _, newValue in
                            // Limit to 6 characters and make uppercase
                            let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                            if filtered.count <= 6 {
                                gameCode = filtered
                            } else {
                                gameCode = String(filtered.prefix(6))
                            }
                        }
                    
                    Text("Game codes are 6 characters long")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Join Button
                Button(action: {
                    lobbyViewModel.joinGame(code: gameCode)
                }) {
                    HStack {
                        if lobbyViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(lobbyViewModel.isLoading ? "Joining..." : "Join Game")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gameCode.count == 6 ? Color(UIColor.systemGreen) : Color(UIColor.systemGray3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(gameCode.count != 6 || lobbyViewModel.isLoading)
                
                // Cancel Button
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Join Game")
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

struct JoinGameView_Previews: PreviewProvider {
    static var previews: some View {
        JoinGameView(user: User(id: "1", displayName: "Test User", avatar: "😀"))
    }
}