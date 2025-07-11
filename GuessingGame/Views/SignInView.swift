import SwiftUI
import AuthenticationServices
import Combine

struct SignInView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @StateObject private var signInViewModel = SignInViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingLegalDocument = false
    @State private var legalDocumentType: LegalDocumentType = .termsOfService
    
    enum LegalDocumentType {
        case termsOfService
        case privacyPolicy
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 16) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text(Strings.appName)
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
                    HStack {
                        Spacer()
                        ProgressView(Strings.Auth.signingIn)
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .frame(height: 50)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        if networkMonitor.isConnected {
                            authViewModel.signInWithApple()
                        } else {
                            signInViewModel.showOfflineError()
                        }
                    } onCompletion: { _ in
                        // Handled in AuthenticationViewModel
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    .disabled(!networkMonitor.isConnected)
                }
                
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
                    Button(Strings.Profile.termsOfService) {
                        legalDocumentType = .termsOfService
                        showingLegalDocument = true
                    }
                    .font(.caption)
                    
                    Button(Strings.Profile.privacyPolicy) {
                        legalDocumentType = .privacyPolicy
                        showingLegalDocument = true
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingLegalDocument) {
            switch legalDocumentType {
            case .termsOfService:
                LegalDocumentView(
                    title: Strings.Profile.termsOfService,
                    content: Strings.Profile.termsOfServicePlaceholder
                )
            case .privacyPolicy:
                LegalDocumentView(
                    title: Strings.Profile.privacyPolicy,
                    content: Strings.Profile.privacyPolicyPlaceholder
                )
            }
        }
    }
}

// MARK: - Previews
#Preview("Default State") {
    SignInView(authViewModel: AuthenticationViewModel())
}

#Preview("Authenticating State") {
    let authViewModel = AuthenticationViewModel()
    // Note: Would need to set authenticating state for preview
    return SignInView(authViewModel: authViewModel)
}

#Preview("With Error Message") {
    let authViewModel = AuthenticationViewModel()
    // Note: Would need to set error message for preview
    return SignInView(authViewModel: authViewModel)
}

#Preview("Dark Mode") {
    SignInView(authViewModel: AuthenticationViewModel())
        .preferredColorScheme(.dark)
}
