import SwiftUI
import Combine

/// ViewModel for the Sign In screen following MVVM architecture
@MainActor
class SignInViewModel: ObservableObject {
    @Published var errorAlert: ErrorAlert?
    
    // MARK: - Public Methods
    
    /// Show error when trying to sign in offline
    func showOfflineError() {
        errorAlert = ErrorAlert.standard(message: Strings.Error.Game.needInternetConnection)
    }
    
    /// Handle sign in errors
    func handleSignInError(_ error: Error) {
        let message = ErrorHandler.userFriendlyMessage(for: error)
        let isRetryable = ErrorHandler.isNetworkError(error)
        
        if isRetryable {
            errorAlert = ErrorAlert.withRetry(message: message) {
                // Retry logic would be handled by the calling view
            }
        } else {
            errorAlert = ErrorAlert.standard(message: message)
        }
    }
}