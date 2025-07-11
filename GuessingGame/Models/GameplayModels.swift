import Foundation

// MARK: - Game State Models

enum PlayerRole: String, Codable, CaseIterable {
    case answerer = "answerer"
    case guesser = "guesser"
    
    var displayName: String {
        switch self {
        case .answerer:
            return "Answerer"
        case .guesser:
            return "Guesser"
        }
    }
}

enum GamePhase: String, Codable {
    case setup = "setup"           // Answerer selecting category/word
    case questioning = "questioning" // Guessers asking questions
    case gameOver = "gameOver"     // Game finished
    
    var displayName: String {
        switch self {
        case .setup:
            return "Game Setup"
        case .questioning:
            return "Questioning Phase"
        case .gameOver:
            return "Game Over"
        }
    }
}

struct GameState: Codable, Equatable {
    let answererID: String
    var category: String
    var secretWord: String
    var currentTurnPlayerID: String
    var phase: GamePhase
    var turnOrder: [String] // Array of guesser IDs in turn order
    var questions: [Question]
    var winnerID: String?
    var roundNumber: Int
    
    init(answererID: String, guesserIDs: [String]) {
        self.answererID = answererID
        self.category = ""
        self.secretWord = ""
        self.currentTurnPlayerID = guesserIDs.first ?? ""
        self.phase = .setup
        self.turnOrder = guesserIDs.shuffled()
        self.questions = []
        self.winnerID = nil
        self.roundNumber = 1
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "answererID": answererID,
            "category": category,
            "secretWord": secretWord,
            "currentTurnPlayerID": currentTurnPlayerID,
            "phase": phase.rawValue,
            "turnOrder": turnOrder,
            "questions": questions.map { $0.toDictionary() },
            "winnerID": winnerID ?? "",
            "roundNumber": roundNumber
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> GameState? {
        guard let answererID = dict["answererID"] as? String,
              let category = dict["category"] as? String,
              let secretWord = dict["secretWord"] as? String,
              let currentTurnPlayerID = dict["currentTurnPlayerID"] as? String,
              let phaseRaw = dict["phase"] as? String,
              let phase = GamePhase(rawValue: phaseRaw),
              let turnOrder = dict["turnOrder"] as? [String],
              let questionsData = dict["questions"] as? [[String: Any]],
              let roundNumber = dict["roundNumber"] as? Int else {
            return nil
        }
        
        let questions = questionsData.compactMap { Question.fromDictionary($0) }
        let winnerID = dict["winnerID"] as? String
        
        var gameState = GameState(answererID: answererID, guesserIDs: turnOrder)
        gameState.category = category
        gameState.secretWord = secretWord
        gameState.currentTurnPlayerID = currentTurnPlayerID
        gameState.phase = phase
        gameState.questions = questions
        gameState.winnerID = winnerID?.isEmpty == true ? nil : winnerID
        gameState.roundNumber = roundNumber
        
        return gameState
    }
}

struct Question: Codable, Identifiable, Equatable {
    let id: String
    let askerID: String
    let askerName: String
    let question: String
    var answer: String
    var isAnswered: Bool
    var timestamp: Date
    
    init(askerID: String, askerName: String, question: String) {
        self.id = UUID().uuidString
        self.askerID = askerID
        self.askerName = askerName
        self.question = question
        self.answer = ""
        self.isAnswered = false
        self.timestamp = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "askerID": askerID,
            "askerName": askerName,
            "question": question,
            "answer": answer,
            "isAnswered": isAnswered,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Question? {
        guard let id = dict["id"] as? String,
              let askerID = dict["askerID"] as? String,
              let askerName = dict["askerName"] as? String,
              let question = dict["question"] as? String,
              let answer = dict["answer"] as? String,
              let isAnswered = dict["isAnswered"] as? Bool,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        
        var q = Question(askerID: askerID, askerName: askerName, question: question)
        q.answer = answer
        q.isAnswered = isAnswered
        q.timestamp = Date(timeIntervalSince1970: timestamp)
        return q
    }
}

// MARK: - Categories

struct GameCategory {
    let name: String
    let suggestedWords: [String]
    
    static let predefinedCategories = [
        GameCategory(name: "People", suggestedWords: [
            "Albert Einstein", "Taylor Swift", "Leonardo da Vinci", "Oprah Winfrey",
            "Michael Jordan", "Marie Curie", "Steve Jobs", "Shakespeare"
        ]),
        GameCategory(name: "Places", suggestedWords: [
            "Paris", "Tokyo", "New York", "London", "Sydney", "Cairo",
            "Rome", "Barcelona", "Amsterdam", "Dubai"
        ]),
        GameCategory(name: "Animals", suggestedWords: [
            "Elephant", "Penguin", "Tiger", "Dolphin", "Giraffe", "Octopus",
            "Kangaroo", "Eagle", "Butterfly", "Whale"
        ]),
        GameCategory(name: "Movies", suggestedWords: [
            "Titanic", "Avatar", "The Lion King", "Star Wars", "Harry Potter",
            "The Avengers", "Frozen", "Jurassic Park", "The Matrix", "Toy Story"
        ]),
        GameCategory(name: "Food", suggestedWords: [
            "Pizza", "Sushi", "Chocolate", "Ice Cream", "Hamburger", "Pasta",
            "Tacos", "Apple Pie", "Sandwich", "Pancakes"
        ]),
        GameCategory(name: "Objects", suggestedWords: [
            "Smartphone", "Guitar", "Bicycle", "Camera", "Clock", "Umbrella",
            "Laptop", "Piano", "Telescope", "Backpack"
        ])
    ]
}

// MARK: - Game Flow Helpers

extension GameState {
    var currentTurnPlayer: GamePlayer? {
        // This would be resolved using the players from GameSession
        return nil
    }
    
    var isAnswererTurn: Bool {
        return phase == .setup
    }
    
    var latestQuestion: Question? {
        return questions.last
    }
    
    var unansweredQuestions: [Question] {
        return questions.filter { !$0.isAnswered }
    }
    
    mutating func nextTurn() {
        guard !turnOrder.isEmpty else { return }
        
        if let currentIndex = turnOrder.firstIndex(of: currentTurnPlayerID) {
            let nextIndex = (currentIndex + 1) % turnOrder.count
            currentTurnPlayerID = turnOrder[nextIndex]
        }
    }
    
    mutating func addQuestion(_ question: Question) {
        questions.append(question)
    }
    
    mutating func answerQuestion(questionID: String, answer: String) {
        if let index = questions.firstIndex(where: { $0.id == questionID }) {
            questions[index].answer = answer
            questions[index].isAnswered = true
        }
    }
    
    func isCorrectGuess(_ guess: String) -> Bool {
        return guess.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
               secretWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}