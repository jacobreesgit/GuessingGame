import SwiftUI
import Combine

/// ViewModel for the Avatar Selection screen following MVVM architecture
@MainActor
class AvatarSelectionViewModel: ObservableObject {
    @Published var selectedEmoji: String
    @Published var errorAlert: ErrorAlert?
    
    init(initialAvatar: String) {
        self.selectedEmoji = initialAvatar
    }
    
    // MARK: - Public Methods
    
    /// Select an emoji avatar
    func selectEmoji(_ emoji: String) {
        selectedEmoji = emoji
    }
    
    /// Show error when trying to save avatar offline
    func showOfflineError() {
        errorAlert = ErrorAlert.standard(message: Strings.Error.Game.needInternetConnection)
    }
    
    /// Handle avatar saving errors
    func handleAvatarSaveError(_ error: Error) {
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