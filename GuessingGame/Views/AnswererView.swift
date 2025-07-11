import SwiftUI

struct AnswererView: View {
    @ObservedObject var gameplayViewModel: GameplayViewModel
    @State private var selectedCategory = ""
    @State private var selectedWord = ""
    @State private var customWord = ""
    @State private var useCustomWord = false
    @State private var showingWordSelection = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("🎯")
                    .font(.system(size: 60))
                
                Text("You're the Answerer!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose a category and secret word for the guessers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Round \(gameplayViewModel.roundNumber)")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if !showingWordSelection {
                categorySelectionView
            } else {
                wordSelectionView
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Choose Secret Word")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            Text("Select a Category")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(GameCategory.predefinedCategories, id: \.name) { category in
                    Button(action: {
                        selectedCategory = category.name
                        showingWordSelection = true
                    }) {
                        VStack(spacing: 8) {
                            Text(categoryEmoji(for: category.name))
                                .font(.system(size: 30))
                            
                            Text(category.name)
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var wordSelectionView: some View {
        VStack(spacing: 20) {
            // Category header with back button
            HStack {
                Button("← Back") {
                    showingWordSelection = false
                    selectedWord = ""
                    customWord = ""
                    useCustomWord = false
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                VStack {
                    Text("Category: \(selectedCategory)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(categoryEmoji(for: selectedCategory))
                        .font(.title)
                }
                
                Spacer()
                
                // Invisible spacer for centering
                Button("← Back") {
                    // Placeholder
                }
                .opacity(0)
                .disabled(true)
            }
            
            // Word options
            if !useCustomWord {
                suggestedWordsView
            } else {
                customWordView
            }
            
            // Toggle between suggested and custom
            Button(action: {
                useCustomWord.toggle()
                selectedWord = ""
                customWord = ""
            }) {
                Text(useCustomWord ? "Choose from suggestions" : "Enter custom word")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // Confirm button
            Button(action: {
                let finalWord = useCustomWord ? customWord : selectedWord
                gameplayViewModel.setSecretWord(category: selectedCategory, word: finalWord)
            }) {
                Text("Confirm Secret Word")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canConfirm ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canConfirm)
        }
    }
    
    private var suggestedWordsView: some View {
        VStack(spacing: 16) {
            Text("Choose a word:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let category = GameCategory.predefinedCategories.first { $0.name == selectedCategory }
            let words = category?.suggestedWords ?? []
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(words, id: \.self) { word in
                    Button(action: {
                        selectedWord = word
                    }) {
                        Text(word)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(selectedWord == word ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(selectedWord == word ? .green : .primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedWord == word ? Color.green : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
        }
    }
    
    private var customWordView: some View {
        VStack(spacing: 16) {
            Text("Enter your own word:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Type your secret word...", text: $customWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
                .autocorrectionDisabled()
                .autocapitalization(.words)
            
            Text("Make sure it fits the \"\(selectedCategory)\" category!")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var canConfirm: Bool {
        if useCustomWord {
            return !customWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !selectedWord.isEmpty
        }
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category {
        case "People": return "👤"
        case "Places": return "🏛️"
        case "Animals": return "🦁"
        case "Movies": return "🎬"
        case "Food": return "🍕"
        case "Objects": return "📱"
        default: return "❓"
        }
    }
}

// MARK: - Previews
#Preview("Category Selection") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    return AnswererView(gameplayViewModel: viewModel)
}

#Preview("Word Selection - Animals") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    // Note: Would need to mock category selection state
    return AnswererView(gameplayViewModel: viewModel)
}

#Preview("Custom Word Entry") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    // Note: Would need to mock custom word state
    return AnswererView(gameplayViewModel: viewModel)
}

#Preview("Round 2") {
    var session = PreviewData.setupPhaseGameSession
    session.gameState?.roundNumber = 2
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: session)
    return AnswererView(gameplayViewModel: viewModel)
}

#Preview("Dark Mode") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    return AnswererView(gameplayViewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    return AnswererView(gameplayViewModel: viewModel)
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

#Preview("Small Screen") {
    let viewModel = GameplayViewModel(user: PreviewData.sampleUser, gameSession: PreviewData.setupPhaseGameSession)
    return AnswererView(gameplayViewModel: viewModel)
}