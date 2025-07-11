import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import Firebase
import FirebaseAuth
import FirebaseDatabase
import CryptoKit

@MainActor
class AuthenticationViewModel: NSObject, ObservableObject {
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var errorMessage: String = ""
    
    private var currentNonce: String?
    private let database = Database.database().reference()
    
    override init() {
        super.init()
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                self.loadUserProfile(for: user)
            } else {
                self.authenticationState = .unauthenticated
            }
        }
    }
    
    private func loadUserProfile(for firebaseUser: FirebaseAuth.User) {
        database.child("users").child(firebaseUser.uid).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if let userData = snapshot.value as? [String: Any],
               let user = User.fromDictionary(userData) {
                if user.avatar.isEmpty {
                    self.authenticationState = .needsAvatar(user)
                } else {
                    self.authenticationState = .authenticated(user)
                }
            } else {
                // User doesn't exist in database, create profile
                let displayName = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
                let email = firebaseUser.email
                let newUser = User(id: firebaseUser.uid, displayName: displayName, email: email)
                self.authenticationState = .needsAvatar(newUser)
            }
        } withCancel: { [weak self] error in
            print("Failed to load user profile: \(error.localizedDescription)")
            // Even if database fails, we can still proceed with basic user info
            let displayName = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
            let email = firebaseUser.email
            let newUser = User(id: firebaseUser.uid, displayName: displayName, email: email)
            self?.authenticationState = .needsAvatar(newUser)
        }
    }
    
    func signInWithApple() {
        print("Starting Sign In with Apple process...")
        errorMessage = "" // Clear any previous errors
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        print("Created Apple ID request with nonce")
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        print("About to perform Apple Sign In request...")
        authorizationController.performRequests()
    }
    
    func saveAvatar(_ emoji: String) {
        guard case .needsAvatar(var user) = authenticationState else { return }
        
        user.avatar = emoji
        authenticationState = .authenticating
        
        // Save to Firebase with error handling
        database.child("users").child(user.id).setValue(user.toDictionary()) { [weak self] error, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("Failed to save avatar to Firebase: \(error.localizedDescription)")
                    // Continue anyway - we can still use the app without Firebase persistence
                    self.authenticationState = .authenticated(user)
                } else {
                    print("Successfully saved user avatar to Firebase")
                    self.authenticationState = .authenticated(user)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            authenticationState = .unauthenticated
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                return
            }
            
            let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            authenticationState = .authenticating
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Authentication failed: \(error.localizedDescription)"
                    self.authenticationState = .unauthenticated
                    return
                }
                
                guard let user = result?.user else {
                    self.errorMessage = "Failed to get user information"
                    self.authenticationState = .unauthenticated
                    return
                }
                
                // Update user profile if we have new information from Apple
                let changeRequest = user.createProfileChangeRequest()
                var shouldUpdateProfile = false
                
                if let fullName = appleIDCredential.fullName {
                    let displayName = PersonNameComponentsFormatter().string(from: fullName)
                    if !displayName.isEmpty {
                        changeRequest.displayName = displayName
                        shouldUpdateProfile = true
                        print("Setting display name to: \(displayName)")
                    }
                }
                
                if shouldUpdateProfile {
                    changeRequest.commitChanges { [weak self] error in
                        if let error = error {
                            print("Failed to update profile: \(error.localizedDescription)")
                        } else {
                            print("Successfully updated Firebase user profile")
                        }
                        
                        // Reload the user to get updated information
                        user.reload { [weak self] error in
                            if let error = error {
                                print("Failed to reload user: \(error.localizedDescription)")
                            }
                            self?.loadUserProfile(for: user)
                        }
                    }
                } else {
                    self.loadUserProfile(for: user)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as? ASAuthorizationError
        switch authError?.code {
        case .canceled:
            errorMessage = "Sign in was canceled"
        case .failed:
            errorMessage = "Sign in failed. Please try again."
        case .invalidResponse:
            errorMessage = "Invalid response from Apple"
        case .notHandled:
            errorMessage = "Sign in not handled"
        case .unknown:
            errorMessage = "Unknown error occurred"
        default:
            errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
        }
        print("Sign In with Apple error: \(error)")
        authenticationState = .unauthenticated
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}