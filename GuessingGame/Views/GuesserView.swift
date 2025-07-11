import SwiftUI

struct GuesserView: View {
    @ObservedObject var gameplayViewModel: GameplayViewModel
    @State private var questionText = ""
    @State private var guessText = ""
    @State private var showingGuessDialog = false
    @State private var answerText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Game info
            gameInfoView
            
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
            } else {
                Text("Wait for your turn")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
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
            .background(Color.gray.opacity(0.1))
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
        .background(Color.gray.opacity(0.05))
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
                    .background(Color.blue.opacity(0.1))
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
        .background(Color.green.opacity(0.1))
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