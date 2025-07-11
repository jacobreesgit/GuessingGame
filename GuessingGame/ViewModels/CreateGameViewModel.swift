import SwiftUI
import Combine

/// ViewModel for the Create Game screen following MVVM architecture
@MainActor
class CreateGameViewModel: ObservableObject {
    @Published var errorAlert: ErrorAlert?
    
    // MARK: - Public Methods
    
    /// Show error when trying to create game offline
    func showOfflineError() {
        errorAlert = ErrorAlert.standard(message: Strings.Error.Game.needInternetConnection)
    }
    
    /// Handle game creation errors
    func handleGameCreationError(_ error: Error) {
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