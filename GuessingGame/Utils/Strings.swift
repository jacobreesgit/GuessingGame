import SwiftUI

/// Centralized string management for localization
struct Strings {
    
    // MARK: - Common
    static let appName = LocalizedStringKey("app_name")
    static let cancel = LocalizedStringKey("cancel")
    static let done = LocalizedStringKey("done")
    static let ok = LocalizedStringKey("ok")
    static let retry = LocalizedStringKey("retry")
    static let close = LocalizedStringKey("close")
    static let continue_ = LocalizedStringKey("continue")
    
    // MARK: - Authentication
    struct Auth {
        static let signInWithApple = LocalizedStringKey("sign_in_with_apple")
        static let signOut = LocalizedStringKey("sign_out")
        static let signOutConfirmationTitle = LocalizedStringKey("sign_out_confirmation_title")
        static let signOutConfirmationMessage = LocalizedStringKey("sign_out_confirmation_message")
        static let signingIn = LocalizedStringKey("signing_in")
        static let authenticationFailed = LocalizedStringKey("authentication_failed")
    }
    
    // MARK: - Profile
    struct Profile {
        static let profile = LocalizedStringKey("profile")
        static let tapAvatarToChange = LocalizedStringKey("tap_avatar_to_change")
        static let privacyPolicy = LocalizedStringKey("privacy_policy")
        static let termsOfService = LocalizedStringKey("terms_of_service")
        static let version = LocalizedStringKey("version")
        static let comingSoon = LocalizedStringKey("coming_soon")
        static let privacyPolicyPlaceholder = LocalizedStringKey("privacy_policy_placeholder")
        static let termsOfServicePlaceholder = LocalizedStringKey("terms_of_service_placeholder")
    }
    
    // MARK: - Game
    struct Game {
        static let createGame = LocalizedStringKey("create_game")
        static let joinGame = LocalizedStringKey("join_game")
        static let gameHistory = LocalizedStringKey("game_history")
        static let gameCode = LocalizedStringKey("game_code")
        static let yourGameCode = LocalizedStringKey("your_game_code")
        static let shareCodeMessage = LocalizedStringKey("share_code_message")
        static let players = LocalizedStringKey("players")
        static let startGame = LocalizedStringKey("start_game")
        static let leaveGame = LocalizedStringKey("leave_game")
        static let leaveGameConfirmation = LocalizedStringKey("leave_game_confirmation")
        
        struct Create {
            static let title = LocalizedStringKey("create_game_title")
            static let description = LocalizedStringKey("create_game_description")
            static let duration = LocalizedStringKey("duration")
            static let gameMode = LocalizedStringKey("game_mode")
            static let multiplayerGuessing = LocalizedStringKey("multiplayer_guessing")
            static let creating = LocalizedStringKey("creating")
        }
        
        struct Join {
            static let title = LocalizedStringKey("join_game_title")
            static let description = LocalizedStringKey("join_game_description")
            static let enterGameCode = LocalizedStringKey("enter_game_code")
            static let gameCodesSixCharacters = LocalizedStringKey("game_codes_six_characters")
            static let joining = LocalizedStringKey("joining")
        }
        
        struct Play {
            static let yourTurn = LocalizedStringKey("your_turn")
            static let waitForTurn = LocalizedStringKey("wait_for_turn")
            static let askQuestion = LocalizedStringKey("ask_question")
            static let makeGuess = LocalizedStringKey("make_guess")
            static let skipTurn = LocalizedStringKey("skip_turn")
            static let timeRemaining = LocalizedStringKey("time_remaining")
            static let hurryUp = LocalizedStringKey("hurry_up")
            static let gameOver = LocalizedStringKey("game_over")
            static let playAgain = LocalizedStringKey("play_again")
            static let backToLobby = LocalizedStringKey("back_to_lobby")
        }
    }
    
    // MARK: - Errors
    struct Error {
        static let error = LocalizedStringKey("error")
        static let networkError = LocalizedStringKey("network_error")
        static let connectionFailed = LocalizedStringKey("connection_failed")
        static let offlineMode = LocalizedStringKey("offline_mode")
        static let offlineMessage = LocalizedStringKey("offline_message")
        static let firebaseError = LocalizedStringKey("firebase_error")
        static let tryAgainLater = LocalizedStringKey("try_again_later")
        static let unknownError = LocalizedStringKey("unknown_error")
        
        struct Game {
            static let needInternetConnection = LocalizedStringKey("need_internet_connection")
            static let failedToCreateGame = LocalizedStringKey("failed_to_create_game")
            static let failedToJoinGame = LocalizedStringKey("failed_to_join_game")
            static let gameSessionNotFound = LocalizedStringKey("game_session_not_found")
            static let gameAlreadyStarted = LocalizedStringKey("game_already_started")
            static let alreadyInGame = LocalizedStringKey("already_in_game")
            static let onlyHostCanStart = LocalizedStringKey("only_host_can_start")
            static let needTwoPlayers = LocalizedStringKey("need_two_players")
        }
    }
    
    // MARK: - Gameplay
    struct Gameplay {
        static let loading = LocalizedStringKey("loading")
        static let leave = LocalizedStringKey("leave")
        static let leaveGame = LocalizedStringKey("leave_game")
        static let leaveGameConfirmation = LocalizedStringKey("leave_game_confirmation")
        static let waitingForSecretWord = LocalizedStringKey("waiting_for_secret_word")
        static let answererChoosingWord = LocalizedStringKey("answerer_choosing_word")
        static let isTheAnswerer = LocalizedStringKey("is_the_answerer")
        static let round = LocalizedStringKey("round")
        static let pleaseWait = LocalizedStringKey("please_wait")
        static let yourTurn = LocalizedStringKey("your_turn")
        static let wait = LocalizedStringKey("wait")
        static let gameOver = LocalizedStringKey("game_over")
        static let wins = LocalizedStringKey("wins")
        static let congratulations = LocalizedStringKey("congratulations")
        static let betterLuckNextTime = LocalizedStringKey("better_luck_next_time")
        static let gameEnded = LocalizedStringKey("game_ended")
        static let playerLeftGame = LocalizedStringKey("player_left_game")
        static let gameSummary = LocalizedStringKey("game_summary")
        static let category = LocalizedStringKey("category")
        static let secretWord = LocalizedStringKey("secret_word")
        static let questionsAsked = LocalizedStringKey("questions_asked")
        static let startingNewGame = LocalizedStringKey("starting_new_game")
        static let backToLobby = LocalizedStringKey("back_to_lobby")
        static let waitingForHost = LocalizedStringKey("waiting_for_host")
    }
    
    // MARK: - Game Lobby
    struct Lobby {
        static let notConnectedToGame = LocalizedStringKey("not_connected_to_game")
        static let gameLobby = LocalizedStringKey("game_lobby")
        static let hostTransfer = LocalizedStringKey("host_transfer")
        static let shareCodeMessage = LocalizedStringKey("share_code_message")
        static let shareInstructionsSimple = LocalizedStringKey("share_instructions_simple")
        static let shareInstructionsDetailed = LocalizedStringKey("share_instructions_detailed")
        static let hostBadge = LocalizedStringKey("host_badge")
        static let joinedPrefix = LocalizedStringKey("joined_prefix")
    }
    
    // MARK: - Answerer
    struct Answerer {
        static let youreTheAnswerer = LocalizedStringKey("youre_the_answerer")
        static let chooseCategoryAndWord = LocalizedStringKey("choose_category_and_word")
        static let chooseSecretWord = LocalizedStringKey("choose_secret_word")
        static let selectCategory = LocalizedStringKey("select_category")
        static let back = LocalizedStringKey("back")
        static let categoryPrefix = LocalizedStringKey("category_prefix")
        static let chooseFromSuggestions = LocalizedStringKey("choose_from_suggestions")
        static let enterCustomWord = LocalizedStringKey("enter_custom_word")
        static let confirmSecretWord = LocalizedStringKey("confirm_secret_word")
        static let chooseWordPrompt = LocalizedStringKey("choose_word_prompt")
        static let enterOwnWordPrompt = LocalizedStringKey("enter_own_word_prompt")
        static let typeSecretWordPlaceholder = LocalizedStringKey("type_secret_word_placeholder")
        static let categoryValidationPrefix = LocalizedStringKey("category_validation_prefix")
        static let categoryValidationSuffix = LocalizedStringKey("category_validation_suffix")
    }
    
    // MARK: - Guesser
    struct Guesser {
        static let guessingGame = LocalizedStringKey("guessing_game")
        static let makeYourGuess = LocalizedStringKey("make_your_guess")
        static let enterGuessPlaceholder = LocalizedStringKey("enter_guess_placeholder")
        static let submitGuess = LocalizedStringKey("submit_guess")
        static let guessInstruction = LocalizedStringKey("guess_instruction")
        static let turnSuffix = LocalizedStringKey("turn_suffix")
        static let timeRemaining = LocalizedStringKey("time_remaining")
        static let secondsSuffix = LocalizedStringKey("seconds_suffix")
        static let hurryUp = LocalizedStringKey("hurry_up")
        static let categoryLabel = LocalizedStringKey("category_label")
        static let questionsAndAnswers = LocalizedStringKey("questions_and_answers")
        static let askQuestionPlaceholder = LocalizedStringKey("ask_question_placeholder")
        static let ask = LocalizedStringKey("ask")
        static let askInstruction = LocalizedStringKey("ask_instruction")
        static let makeGuess = LocalizedStringKey("make_guess")
        static let skipTurn = LocalizedStringKey("skip_turn")
        static let reactLabel = LocalizedStringKey("react_label")
        static let more = LocalizedStringKey("more")
        static let pickEmoji = LocalizedStringKey("pick_emoji")
        static let questionPrefix = LocalizedStringKey("question_prefix")
        static let answerPrefix = LocalizedStringKey("answer_prefix")
        static let waitingForAnswer = LocalizedStringKey("waiting_for_answer")
        static let answerQuestionHeader = LocalizedStringKey("answer_question_header")
        static let askedByPrefix = LocalizedStringKey("asked_by_prefix")
        static let yes = LocalizedStringKey("yes")
        static let no = LocalizedStringKey("no")
        static let customAnswerPrompt = LocalizedStringKey("custom_answer_prompt")
        static let typeAnswerPlaceholder = LocalizedStringKey("type_answer_placeholder")
        static let submit = LocalizedStringKey("submit")
    }
}