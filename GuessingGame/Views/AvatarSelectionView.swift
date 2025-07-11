import SwiftUI
import Combine

struct AvatarSelectionView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @StateObject private var avatarViewModel: AvatarSelectionViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    let user: User
    
    init(authViewModel: AuthenticationViewModel, user: User) {
        self.authViewModel = authViewModel
        self.user = user
        self._avatarViewModel = StateObject(wrappedValue: AvatarSelectionViewModel(initialAvatar: user.avatar.isEmpty ? "😀" : user.avatar))
    }
    
    private let emojis = [
        "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
        "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩",
        "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜",
        "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐",
        "🤨", "😐", "😑", "😶", "🙄", "😏", "😣", "😥",
        "😮", "😯", "😪", "😫", "😴", "😌", "😤", "😠",
        "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨",
        "😰", "😢", "😭", "😖", "😞", "😓", "😩", "🥱",
        "🤤", "🌛", "🌜", "🌚", "🌝", "🌞"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Text("Choose Your Avatar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Pick an emoji that represents you!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Selected Avatar Preview
            VStack(spacing: 12) {
                Text(avatarViewModel.selectedEmoji)
                    .font(.system(size: 80))
                    .padding()
                    .background(Circle().fill(Color.gray.opacity(0.1)))
                
                Text("Hello, \(user.displayName)!")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            // Emoji Grid
            ScrollView {
                let columns = Array(repeating: GridItem(.flexible()), count: 8)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            avatarViewModel.selectEmoji(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(avatarViewModel.selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(avatarViewModel.selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(emoji)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
            
            // Offline Warning
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                    Text(Strings.Error.Game.needInternetConnection)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Continue Button
            Button(action: {
                if networkMonitor.isConnected {
                    authViewModel.saveAvatar(avatarViewModel.selectedEmoji)
                } else {
                    avatarViewModel.showOfflineError()
                }
            }) {
                HStack {
                    if case .authenticating = authViewModel.authenticationState {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    
                    Text({
                        if case .authenticating = authViewModel.authenticationState {
                            return "Saving..."
                        } else {
                            return Strings.continue_
                        }
                    }())
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled({
                if case .authenticating = authViewModel.authenticationState {
                    return true
                } else {
                    return !networkMonitor.isConnected
                }
            }())
            
            // Error Message
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Previews
#Preview("Default State") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "John Doe", email: "john@example.com", avatar: "😀")
    )
}

#Preview("Long Name") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Alexander Maximilian Fitzgerald", email: "alexander.maximilian@example.com", avatar: "🎭")
    )
}

#Preview("No Email") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Anonymous User", email: nil, avatar: "🤔")
    )
}

#Preview("Different Avatar") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Cool User", email: "cool@example.com", avatar: "🚀")
    )
}

#Preview("Dark Mode") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Night User", email: "night@example.com", avatar: "🌙")
    )
    .preferredColorScheme(.dark)
}

#Preview("Small Screen") {
    AvatarSelectionView(
        authViewModel: AuthenticationViewModel(),
        user: User(id: "1", displayName: "Mobile User", email: "mobile@example.com", avatar: "📱")
    )
}