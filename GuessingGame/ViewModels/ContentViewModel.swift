import SwiftUI
import Combine

/// ViewModel for the main ContentView following MVVM architecture
@MainActor
class ContentViewModel: ObservableObject {
    @Published var errorAlert: ErrorAlert?
    
    // MARK: - Public Methods
    
    /// Handle authentication errors from AuthenticationViewModel
    func handleAuthError(_ errorMessage: String) {
        guard !errorMessage.isEmpty else { return }
        
        let localizedMessage = LocalizedStringKey(errorMessage)
        errorAlert = ErrorAlert.standard(message: localizedMessage)
    }
    
    /// Handle general app errors
    func handleGeneralError(_ error: Error) {
        let message = ErrorHandler.userFriendlyMessage(for: error)
        let isRetryable = ErrorHandler.isNetworkError(error)
        
        if isRetryable {
            errorAlert = ErrorAlert.withRetry(message: message) { [weak self] in
                // Retry logic would be handled by the calling view
            }
        } else {
            errorAlert = ErrorAlert.standard(message: message)
        }
    }
}