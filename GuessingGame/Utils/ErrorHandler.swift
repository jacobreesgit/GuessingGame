import SwiftUI
import FirebaseAuth

/// Centralized error handling and user-friendly error messages
struct ErrorHandler {
    
    /// Convert various error types to user-friendly messages
    static func userFriendlyMessage(for error: Error) -> LocalizedStringKey {
        if let authError = error as? AuthErrorCode {
            return handleAuthError(authError)
        } else if error.localizedDescription.contains("network") || 
                  error.localizedDescription.contains("internet") ||
                  error.localizedDescription.contains("connection") {
            return Strings.Error.connectionFailed
        } else {
            return Strings.Error.unknownError
        }
    }
    
    /// Handle Firebase Auth specific errors
    private static func handleAuthError(_ authError: AuthErrorCode) -> LocalizedStringKey {
        switch authError.code {
        case .networkError:
            return Strings.Error.connectionFailed
        case .userNotFound, .invalidCredential:
            return Strings.Auth.authenticationFailed
        case .tooManyRequests:
            return Strings.Error.tryAgainLater
        default:
            return Strings.Auth.authenticationFailed
        }
    }
    
    /// Check if error is network-related
    static func isNetworkError(_ error: Error) -> Bool {
        if let authError = error as? AuthErrorCode {
            return authError.code == .networkError
        }
        
        let errorString = error.localizedDescription.lowercased()
        return errorString.contains("network") || 
               errorString.contains("internet") || 
               errorString.contains("connection") ||
               errorString.contains("offline")
    }
}

/// Custom error types for the app
enum AppError: LocalizedError {
    case networkUnavailable
    case gameSessionNotFound
    case invalidGameCode
    case gameAlreadyStarted
    case insufficientPlayers
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return NSLocalizedString("need_internet_connection", comment: "")
        case .gameSessionNotFound:
            return NSLocalizedString("game_session_not_found", comment: "")
        case .invalidGameCode:
            return NSLocalizedString("game_session_not_found", comment: "")
        case .gameAlreadyStarted:
            return NSLocalizedString("game_already_started", comment: "")
        case .insufficientPlayers:
            return NSLocalizedString("need_two_players", comment: "")
        case .unauthorized:
            return NSLocalizedString("authentication_failed", comment: "")
        }
    }
}

/// Error state for ViewModels
struct ErrorState {
    let message: LocalizedStringKey
    let isRetryable: Bool
    let retryAction: (() -> Void)?
    
    init(message: LocalizedStringKey, isRetryable: Bool = false, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.isRetryable = isRetryable
        self.retryAction = retryAction
    }
}

/// Alert configuration for error display
struct ErrorAlert {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let primaryButton: Alert.Button?
    let secondaryButton: Alert.Button?
    
    init(
        title: LocalizedStringKey = Strings.Error.error,
        message: LocalizedStringKey,
        primaryButton: Alert.Button? = nil,
        secondaryButton: Alert.Button? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    /// Create a standard error alert
    static func standard(message: LocalizedStringKey) -> ErrorAlert {
        ErrorAlert(message: message)
    }
    
    /// Create an error alert with retry option
    static func withRetry(message: LocalizedStringKey, retryAction: @escaping () -> Void) -> ErrorAlert {
        ErrorAlert(
            message: message,
            primaryButton: .default(Text(Strings.retry), action: retryAction),
            secondaryButton: .cancel(Text(Strings.cancel))
        )
    }
    
    /// Create an Alert from ErrorAlert
    func toAlert() -> Alert {
        if let primary = primaryButton, let secondary = secondaryButton {
            return Alert(title: Text(title), message: Text(message), primaryButton: primary, secondaryButton: secondary)
        } else if let primary = primaryButton {
            return Alert(title: Text(title), message: Text(message), dismissButton: primary)
        } else {
            return Alert(title: Text(title), message: Text(message))
        }
    }
}