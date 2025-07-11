import SwiftUI

struct AvatarSelectionView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    let user: User
    @State private var selectedEmoji: String = "😀"
    
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
                Text(selectedEmoji)
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
                            selectedEmoji = emoji
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(emoji)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
            
            // Continue Button
            Button(action: {
                authViewModel.saveAvatar(selectedEmoji)
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
                            return "Continue"
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
                    return false
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
        .onAppear {
            selectedEmoji = user.avatar.isEmpty ? "😀" : user.avatar
        }
    }
}