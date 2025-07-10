import SwiftUI

struct MainMenuView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    let user: User
    @State private var showingProfile = false
    
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
                    
                    Text("GuessingGame")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Game Options
                VStack(spacing: 24) {
                    // Create Game Button
                    Button(action: {
                        // TODO: Navigate to create game
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create Game")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Start a new guessing game")
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
                        // TODO: Navigate to join game
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Join Game")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Enter a game code to join")
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
                                Text("Game History")
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
                
                // App Info
                VStack(spacing: 8) {
                    Text("GuessingGame v1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Made with ❤️ for fun!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .sheet(isPresented: $showingProfile) {
                ProfileView(authViewModel: authViewModel, user: user)
            }
        }
    }
}

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showingAvatarSelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Avatar and Name
                VStack(spacing: 16) {
                    Button(action: {
                        showingAvatarSelection = true
                    }) {
                        Text(user.avatar)
                            .font(.system(size: 80))
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    
                    Text(user.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Tap avatar to change")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Sign Out Button
                Button(action: {
                    authViewModel.signOut()
                    dismiss()
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAvatarSelection) {
                AvatarSelectionView(authViewModel: authViewModel, user: user)
            }
        }
    }
}