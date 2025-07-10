import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
