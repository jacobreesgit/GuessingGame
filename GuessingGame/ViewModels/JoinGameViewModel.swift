import SwiftUI
import Combine

/// ViewModel for the Join Game screen following MVVM architecture
@MainActor
class JoinGameViewModel: ObservableObject {
    @Published var errorAlert: ErrorAlert?
    @Published var gameCode = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe game code changes to validate format
        $gameCode
            .map { code in
                let filtered = code.uppercased().filter { $0.isLetter || $0.isNumber }
                return String(filtered.prefix(6))
            }
            .removeDuplicates()
            .assign(to: &$gameCode)
    }
    
    // MARK: - Public Methods
    
    /// Validate game code format
    var isValidGameCode: Bool {
        gameCode.count == 6
    }
    
    /// Show error when trying to join game offline
    func showOfflineError() {
        errorAlert = ErrorAlert.standard(message: Strings.Error.Game.needInternetConnection)
    }
    
    /// Handle game joining errors
    func handleGameJoinError(_ error: Error) {
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