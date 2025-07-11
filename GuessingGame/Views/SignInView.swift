import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 16) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("GuessingGame")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Play and compete with friends!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Sign In Section
            VStack(spacing: 20) {
                if case .authenticating = authViewModel.authenticationState {
                    ProgressView("Signing in...")
                        .scaleEffect(1.2)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        authViewModel.signInWithApple()
                    } onCompletion: { _ in
                        // Handled in AuthenticationViewModel
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: 375)
                    .cornerRadius(8)
                }
                
                // Error Message
                if !authViewModel.errorMessage.isEmpty {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Terms and Privacy
            VStack(spacing: 8) {
                Text("By signing in, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button("Terms of Service") {
                        // Handle terms
                    }
                    .font(.caption)
                    
                    Button("Privacy Policy") {
                        // Handle privacy
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}