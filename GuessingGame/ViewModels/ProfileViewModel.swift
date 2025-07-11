import SwiftUI
import Combine

/// ViewModel for the Profile screen following MVVM architecture
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorAlert: ErrorAlert?
    @Published var showingSignOutConfirmation = false
    @Published var showingPrivacyPolicy = false
    @Published var showingTermsOfService = false
    
    private let authViewModel: AuthenticationViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
        observeAuthState()
    }
    
    // MARK: - Public Methods
    
    /// Present sign out confirmation
    func presentSignOutConfirmation() {
        showingSignOutConfirmation = true
    }
    
    /// Sign out the user
    func signOut() {
        isLoading = true
        
        Task {
            do {
                try await signOutUser()
                isLoading = false
            } catch {
                isLoading = false
                handleSignOutError(error)
            }
        }
    }
    
    /// Show Privacy Policy
    func showPrivacyPolicy() {
        showingPrivacyPolicy = true
    }
    
    /// Show Terms of Service
    func showTermsOfService() {
        showingTermsOfService = true
    }
    
    
    // MARK: - Private Methods
    
    private func observeAuthState() {
        authViewModel.$errorMessage
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .sink { [weak self] errorMessage in
                self?.errorAlert = ErrorAlert.standard(message: LocalizedStringKey(errorMessage))
            }
            .store(in: &cancellables)
    }
    
    private func signOutUser() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            authViewModel.signOut()
            
            // Check if sign out was successful
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.authViewModel.errorMessage.isEmpty {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AppError.unauthorized)
                }
            }
        }
    }
    
    private func handleSignOutError(_ error: Error) {
        let message = ErrorHandler.userFriendlyMessage(for: error)
        let isRetryable = ErrorHandler.isNetworkError(error)
        
        if isRetryable {
            errorAlert = ErrorAlert.withRetry(message: message) { [weak self] in
                self?.signOut()
            }
        } else {
            errorAlert = ErrorAlert.standard(message: message)
        }
    }
}