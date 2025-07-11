import SwiftUI

struct GuesserView: View {
    @ObservedObject var gameplayViewModel: GameplayViewModel
    @State private var questionText = ""
    @State private var guessText = ""
    @State private var showingGuessDialog = false
    @State private var answerText = ""
    @State private var showingEmojiPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Timer (for current player's turn)
            if gameplayViewModel.isMyTurn && gameplayViewModel.isGuesser {
                timerView
            }
            
            // Game info
            gameInfoView
            
            // Reactions display
            reactionsView
            
            // Questions and answers
            questionsView
            
            Spacer()
            
            // Action buttons
            actionButtonsView
        }
        .padding()
        .navigationTitle("Guessing Game")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Make Your Guess", isPresented: $showingGuessDialog) {
            TextField("Enter your guess...", text: $guessText)
            Button("Cancel", role: .cancel) {
                guessText = ""
            }
            Button("Submit Guess") {
                gameplayViewModel.makeGuess(guessText)
                guessText = ""
            }
            .disabled(guessText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Think you know the secret word? Enter your guess below!")
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView { emoji in
                gameplayViewModel.addEmojiReaction(emoji)
                showingEmojiPicker = false
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("🕵️")
                .font(.system(size: 50))
            
            if gameplayViewModel.isMyTurn {
                Text("Your Turn!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Your turn to ask a question or make a guess")
            } else {
                Text("Wait for your turn")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Waiting for your turn")
            }
            
            if let currentPlayer = gameplayViewModel.currentTurnPlayer {
                Text("\(currentPlayer.displayName)'s turn")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Text("Round \(gameplayViewModel.roundNumber)")
                .font(.headline)
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(gameplayViewModel.timeRemaining <= 10 ? .red : .orange)
                
                Text("Time Remaining")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(gameplayViewModel.timeRemaining)s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(gameplayViewModel.timeRemaining <= 10 ? .red : .primary)
                    .accessibilityLabel("\(gameplayViewModel.timeRemaining) seconds remaining")
            }
            
            ProgressView(value: Double(gameplayViewModel.timeRemaining), total: 30.0)
                .progressViewStyle(LinearProgressViewStyle(tint: gameplayViewModel.timeRemaining <= 10 ? .red : .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .accessibilityLabel("Time remaining progress")
                .accessibilityValue("\(Int((Double(gameplayViewModel.timeRemaining) / 30.0) * 100)) percent")
            
            if gameplayViewModel.timeRemaining <= 10 {
                Text("Hurry up!")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(UIColor.systemOrange).opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(gameplayViewModel.timeRemaining <= 10 ? Color.red : Color.orange, lineWidth: 2)
        )
    }
    
    @ViewBuilder
    private var reactionsView: some View {
        if !gameplayViewModel.recentReactions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(gameplayViewModel.recentReactions) { reaction in
                        VStack(spacing: 4) {
                            Text(reaction.emoji)
                                .font(.title2)
                            
                            Text(reaction.playerName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 60)
        }
    }
    
    private var gameInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Category:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(gameplayViewModel.category)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            // Answerer info
            if let answerer = gameplayViewModel.gameSession?.players[gameplayViewModel.gameSession?.gameState?.answererID ?? ""] {
                HStack {
                    Text(answerer.avatar)
                        .font(.title2)
                    
                    Text("\(answerer.displayName) is the Answerer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var questionsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Questions & Answers")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(gameplayViewModel.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(gameplayViewModel.questions) { question in
                        QuestionRowView(question: question)
                    }
                    
                    // Show unanswered question for answerer
                    if gameplayViewModel.isAnswerer,
                       let unanswered = gameplayViewModel.latestUnansweredQuestion {
                        AnswerInputView(
                            question: unanswered,
                            answerText: $answerText,
                            onSubmit: { answer in
                                gameplayViewModel.answerQuestion(questionID: unanswered.id, answer: answer)
                                answerText = ""
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if gameplayViewModel.isMyTurn && gameplayViewModel.isGuesser {
                // Question input
                VStack(spacing: 8) {
                    HStack {
                        TextField("Ask a yes/no question...", text: $questionText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityLabel("Question input")
                            .accessibilityHint("Enter a yes or no question about the secret word")
                        
                        Button("Ask") {
                            gameplayViewModel.askQuestion(questionText)
                            questionText = ""
                        }
                        .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .accessibilityLabel("Ask question")
                        .accessibilityHint("Submits your question to the answerer")
                    }
                    
                    Text("Ask questions that can be answered with Yes or No")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Guess button
                Button(action: {
                    showingGuessDialog = true
                }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Make a Guess")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Skip turn button
                if gameplayViewModel.isMyTurn && gameplayViewModel.isGuesser {
                    Button(action: {
                        gameplayViewModel.skipTurn()
                    }) {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Turn")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            
            // Emoji reactions
            HStack {
                Text("React:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("😀") { gameplayViewModel.addEmojiReaction("😀") }
                    .accessibilityLabel("React with happy face")
                Button("👍") { gameplayViewModel.addEmojiReaction("👍") }
                    .accessibilityLabel("React with thumbs up")
                Button("👎") { gameplayViewModel.addEmojiReaction("👎") }
                    .accessibilityLabel("React with thumbs down")
                Button("😮") { gameplayViewModel.addEmojiReaction("😮") }
                    .accessibilityLabel("React with surprise")
                Button("🤔") { gameplayViewModel.addEmojiReaction("🤔") }
                    .accessibilityLabel("React with thinking")
                
                Spacer()
                
                Button("More") {
                    showingEmojiPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .accessibilityLabel("More emoji reactions")
                .accessibilityHint("Opens emoji picker with more reaction options")
            }
        }
    }
}

struct EmojiPickerView: View {
    let onEmojiSelected: (String) -> Void
    
    private let emojis = [
        "😀", "😃", "😄", "😁", "😊", "😍", "🤩", "😘", "😗", "😙",
        "😚", "🙂", "🤗", "🤔", "🤨", "😐", "😑", "😶", "🙄", "😏",
        "😣", "😥", "😮", "🤐", "😯", "😪", "😫", "🥱", "😴", "😌",
        "😛", "😜", "😝", "🤤", "😒", "😓", "😔", "😕", "🙃", "🤑",
        "😲", "☹️", "🙁", "😖", "😞", "😟", "😤", "😢", "😭", "😦",
        "😧", "😨", "😩", "🤯", "😬", "😰", "😱", "🥵", "🥶", "😳",
        "🤪", "😵", "🥴", "😠", "😡", "🤬", "😷", "🤒", "🤕", "🤢",
        "🤮", "🤧", "😇", "🥳", "🥺", "🤠", "🤡", "🤥", "🤫", "🤭",
        "👍", "👎", "👌", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉",
        "👆", "🖕", "👇", "☝️", "👋", "🤚", "🖐", "✋", "🖖", "👏"
    ]
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 16) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(emoji) {
                        onEmojiSelected(emoji)
                    }
                    .font(.title)
                    .frame(width: 40, height: 40)
                }
            }
            .padding()
            .navigationTitle("Pick an Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onEmojiSelected("")
                    }
                }
            }
        }
    }
}

struct QuestionRowView: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(question.askerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(formatTime(question.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Q: \(question.question)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if question.isAnswered {
                Text("A: \(question.answer)")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            } else {
                Text("Waiting for answer...")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .italic()
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AnswerInputView: View {
    let question: Question
    @Binding var answerText: String
    let onSubmit: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 Answer this question:")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Q: \(question.question)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding()
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(8)
                
                Text("Asked by \(question.askerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick Yes/No buttons
            HStack(spacing: 12) {
                Button("Yes") {
                    onSubmit("Yes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("No") {
                    onSubmit("No")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Custom answer option
            VStack(spacing: 8) {
                Text("Or provide a custom answer:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Type your answer...", text: $answerText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Submit") {
                        onSubmit(answerText)
                    }
                    .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGreen).opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 2)
        )
    }
}

struct GuesserView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(id: "1", displayName: "Test User", avatar: "😀")
        let session = GameSession(id: "ABC123", hostId: "1", hostPlayer: GamePlayer(id: "1", displayName: "Test User", avatar: "😀"))
        let viewModel = GameplayViewModel(user: user, gameSession: session)
        
        GuesserView(gameplayViewModel: viewModel)
    }
}