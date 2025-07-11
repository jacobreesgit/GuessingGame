import SwiftUI

/// Enhanced Profile screen with legal links and proper error handling
struct ProfileView: View {
    @StateObject private var profileViewModel: ProfileViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAvatarSelection = false
    
    let user: User
    let authViewModel: AuthenticationViewModel
    
    init(authViewModel: AuthenticationViewModel, user: User) {
        self.user = user
        self.authViewModel = authViewModel
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if profileViewModel.isLoading {
                    ProgressView(Strings.Auth.signOut)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    profileContent
                }
            }
            .navigationTitle(Strings.Profile.profile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.done) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingAvatarSelection) {
            AvatarSelectionView(authViewModel: authViewModel, user: user)
        }
        .sheet(isPresented: $profileViewModel.showingPrivacyPolicy) {
            LegalDocumentView(
                title: Strings.Profile.privacyPolicy,
                content: Strings.Profile.privacyPolicyPlaceholder
            )
        }
        .sheet(isPresented: $profileViewModel.showingTermsOfService) {
            LegalDocumentView(
                title: Strings.Profile.termsOfService,
                content: Strings.Profile.termsOfServicePlaceholder
            )
        }
        .confirmationDialog(
            Strings.Auth.signOutConfirmationTitle,
            isPresented: $profileViewModel.showingSignOutConfirmation
        ) {
            Button(Strings.Auth.signOut, role: .destructive) {
                profileViewModel.signOut()
            }
            Button(Strings.cancel, role: .cancel) { }
        } message: {
            Text(Strings.Auth.signOutConfirmationMessage)
        }
    }
    
    @ViewBuilder
    private var profileContent: some View {
        VStack {
            ScrollView {
                VStack(spacing: 32) {
                    // User Info Section
                    userInfoSection
                    
                    // Legal & Info Section
                    legalSection
                }
                .padding()
            }
            
            // Sign Out Section at bottom
            VStack {
                Divider()
                signOutSection
                    .padding()
            }
            .background(Color(UIColor.systemBackground))
        }
    }
    
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingAvatarSelection = true
            }) {
                Text(user.avatar)
                    .font(.system(size: 80))
                    .padding()
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBlue), lineWidth: 3)
                    )
            }
            .accessibilityLabel("Change avatar")
            .accessibilityHint("Tap to select a new avatar")
            
            VStack(spacing: 8) {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(Strings.Profile.tapAvatarToChange)
                .font(.caption)
                .foregroundColor(Color(UIColor.systemBlue))
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: 12) {
            MenuButton(
                title: Strings.Profile.privacyPolicy,
                icon: "hand.raised",
                action: profileViewModel.showPrivacyPolicy
            )
            
            MenuButton(
                title: Strings.Profile.termsOfService,
                icon: "doc.text",
                action: profileViewModel.showTermsOfService
            )
        }
    }
    
    
    private var signOutSection: some View {
        VStack(spacing: 16) {
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                    Text(Strings.Error.offlineMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            Button(action: profileViewModel.presentSignOutConfirmation) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(Strings.Auth.signOut)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemRed).opacity(0.1))
                .foregroundColor(Color(UIColor.systemRed))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.systemRed).opacity(0.3), lineWidth: 1)
                )
            }
            .accessibilityLabel("Sign out")
            .accessibilityHint("Signs you out of your account")
        }
    }
}

/// Reusable menu button component
private struct MenuButton: View {
    let title: LocalizedStringKey
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(UIColor.systemBlue))
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Legal document placeholder view
struct LegalDocumentView: View {
    let title: LocalizedStringKey
    let content: LocalizedStringKey
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(Color(UIColor.systemBlue))
                
                VStack(spacing: 16) {
                    Text(Strings.Profile.comingSoon)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.done) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Default User") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "John Doe", email: "john@example.com", avatar: "😀")
    )
}

#Preview("Long Name & Email") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Alexander Maximilian Fitzgerald III", email: "alexander.maximilian.fitzgerald@verylongdomain.com", avatar: "👑")
    )
}

#Preview("No Email") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Anonymous User", email: nil, avatar: "🎭")
    )
}

#Preview("Special Characters") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "José María García-López", email: "josé@example.com", avatar: "🌟")
    )
}

#Preview("Different Avatars") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Cool Gamer", email: "gamer@example.com", avatar: "🚀")
    )
}

#Preview("Dark Mode") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Night User", email: "night@example.com", avatar: "🌙")
    )
    .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Accessible User", email: "access@example.com", avatar: "♿️")
    )
    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Compact", email: "small@example.com", avatar: "📱")
    )
}

#Preview("Landscape") {
    ProfileView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Wide User", email: "wide@example.com", avatar: "📺")
    )
}