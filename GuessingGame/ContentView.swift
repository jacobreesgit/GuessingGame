import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var contentViewModel = ContentViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        ZStack {
            // Main Content
            Group {
                switch authViewModel.authenticationState {
                case .unauthenticated, .authenticating:
                    SignInView(authViewModel: authViewModel)
                    
                case .needsAvatar(let user):
                    AvatarSelectionView(authViewModel: authViewModel, user: user)
                    
                case .authenticated(let user):
                    MainMenuView(authViewModel: authViewModel, user: user)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.authenticationState)
            
            // Offline Overlay
            if !networkMonitor.isConnected {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.white)
                        Text(Strings.Error.offlineMessage)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: networkMonitor.isConnected)
            }
        }
        .onReceive(authViewModel.$errorMessage) { errorMessage in
            if !errorMessage.isEmpty {
                contentViewModel.handleAuthError(errorMessage)
            }
        }
    }
}

#Preview("Default State") {
    ContentView()
}

#Preview("With Offline Overlay") {
    let _ = NetworkMonitor.shared
    // Note: In real usage, would need to mock NetworkMonitor for offline state
    return ContentView()
}
