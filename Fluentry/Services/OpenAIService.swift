//
//  OpenAIService.swift
//  Fluentry
//
//  OpenAI API Integration Service
//

import Foundation

// MARK: - OpenAI Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - OpenAI Service
@MainActor
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String {
        // Read from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let key = config["OPENAI_API_KEY"] as? String,
           !key.isEmpty && key != "YOUR_API_KEY_HERE" {
            return key
        }
        return ""
    }
    
    var isConfigured: Bool {
        !apiKey.isEmpty
    }
    
    private init() {}
    
    // MARK: - Generic Chat Completion
    func chatCompletion(
        messages: [OpenAIRequest.Message],
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let openAIRequest = OpenAIRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        request.httpBody = try JSONEncoder().encode(openAIRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("OpenAI API Error: \(errorString)")
            }
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        return content
    }
    
    // MARK: - Lesson Generation
    func generateLesson(
        category: LessonCategory,
        difficulty: DifficultyLevel,
        topic: String? = nil
    ) async throws -> (title: String, description: String, content: String) {
        let topicPrompt = topic.map { " about '\($0)'" } ?? ""
        
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: """
            You are an expert English language teacher. Generate comprehensive, engaging lessons \
            for English learners. Structure your response as JSON with keys: title, description, content.
            """
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Create a \(difficulty.rawValue) level \(category.rawValue) lesson\(topicPrompt). 
            
            Requirements:
            - Title: Engaging and descriptive (max 60 characters)
            - Description: Brief overview (max 150 characters)
            - Content: Detailed lesson content with examples, explanations, and tips (500-1000 words)
            
            Return ONLY valid JSON in this exact format:
            {
              "title": "lesson title",
              "description": "brief description",
              "content": "detailed lesson content"
            }
            """
        )
        
        let response = try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.8,
            maxTokens: 2000
        )
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let title = json["title"],
              let description = json["description"],
              let content = json["content"] else {
            throw OpenAIError.invalidJSONResponse
        }
        
        return (title, description, content)
    }
    
    // MARK: - Vocabulary Generation
    func generateVocabularyWord(
        difficulty: DifficultyLevel,
        category: String = "General"
    ) async throws -> (term: String, definition: String, example: String, pronunciation: String) {
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: """
            You are an expert English vocabulary teacher. Generate vocabulary words appropriate \
            for the specified difficulty level. Return responses as JSON.
            """
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Generate a \(difficulty.rawValue) level English vocabulary word in the \(category) category.
            
            Return ONLY valid JSON in this exact format:
            {
              "term": "the word",
              "definition": "clear definition",
              "example": "example sentence using the word",
              "pronunciation": "IPA pronunciation"
            }
            """
        )
        
        let response = try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.7,
            maxTokens: 500
        )
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let term = json["term"],
              let definition = json["definition"],
              let example = json["example"],
              let pronunciation = json["pronunciation"] else {
            throw OpenAIError.invalidJSONResponse
        }
        
        return (term, definition, example, pronunciation)
    }
    
    // MARK: - Exercise Generation
    func generateExercise(
        type: ExerciseType,
        difficulty: DifficultyLevel,
        topic: String? = nil
    ) async throws -> (title: String, instructions: String, content: String) {
        let topicPrompt = topic.map { " about '\($0)'" } ?? ""
        
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: """
            You are an expert English language teacher creating interactive exercises. \
            Generate exercises as JSON with structured content.
            """
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Create a \(difficulty.rawValue) level \(type.rawValue) exercise\(topicPrompt).
            
            Return ONLY valid JSON in this exact format:
            {
              "title": "exercise title",
              "instructions": "clear instructions",
              "content": "exercise data as JSON string"
            }
            
            For the content field, structure it based on exercise type:
            - multipleChoice: {"questions": [{"question": "...", "options": [...], "correct": 0}]}
            - fillInBlank: {"sentences": [{"text": "...", "blank": "...", "answer": "..."}]}
            - Other types: appropriate JSON structure
            """
        )
        
        let response = try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.8,
            maxTokens: 1500
        )
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let title = json["title"],
              let instructions = json["instructions"],
              let content = json["content"] else {
            throw OpenAIError.invalidJSONResponse
        }
        
        return (title, instructions, content)
    }
    
    // MARK: - Grammar Check
    func checkGrammar(text: String) async throws -> String {
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: "You are an expert English grammar checker. Provide corrections and explanations."
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Check the following text for grammar errors and provide corrections with explanations:
            
            "\(text)"
            
            Format: List each error with its correction and a brief explanation.
            """
        )
        
        return try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.3,
            maxTokens: 800
        )
    }
    
    // MARK: - Pronunciation Guide
    func getPronunciationGuide(word: String) async throws -> String {
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: "You are an expert English pronunciation teacher."
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Provide a detailed pronunciation guide for the word: "\(word)"
            
            Include:
            1. IPA notation
            2. Simple phonetic spelling
            3. Tips for proper pronunciation
            4. Common mistakes to avoid
            """
        )
        
        return try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.5,
            maxTokens: 500
        )
    }
    
    // MARK: - Accent Analysis
    func analyzeAccent(
        targetWord: String,
        spokenTranscript: String,
        pronunciation: String
    ) async throws -> (score: Double, feedback: String, suggestions: String) {
        let systemMessage = OpenAIRequest.Message(
            role: "system",
            content: """
            You are an expert English pronunciation and accent coach. Analyze the speaker's pronunciation 
            and provide constructive feedback. Be encouraging but accurate.
            """
        )
        
        let userMessage = OpenAIRequest.Message(
            role: "user",
            content: """
            Target word: "\(targetWord)"
            Correct pronunciation: \(pronunciation)
            What the speaker said: "\(spokenTranscript)"
            
            Analyze the pronunciation and provide:
            1. Score (0-100): How accurate was the pronunciation?
            2. Feedback: Brief encouraging feedback (1-2 sentences)
            3. Suggestions: Specific tips to improve (if score < 90)
            
            Return ONLY valid JSON:
            {
              "score": 85,
              "feedback": "Good attempt! Your pronunciation is clear.",
              "suggestions": "Try emphasizing the first syllable more."
            }
            """
        )
        
        let response = try await chatCompletion(
            messages: [systemMessage, userMessage],
            temperature: 0.3,
            maxTokens: 300
        )
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let score = json["score"] as? Double,
              let feedback = json["feedback"] as? String,
              let suggestions = json["suggestions"] as? String else {
            // Fallback if JSON parsing fails
            return (score: 50.0, feedback: "Good try! Keep practicing.", suggestions: "Focus on clear pronunciation.")
        }
        
        return (score: score / 100.0, feedback: feedback, suggestions: suggestions)
    }
    
    // MARK: - Text-to-Speech
    func textToSpeech(text: String, voice: String = "nova") async throws -> Data {
        guard isConfigured else {
            throw OpenAIError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": "alloy", // Natural, neutral voice
            "speed": 0.9 // Slightly slower for learning
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return data
    }
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    case noContent
    case invalidJSONResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not configured. Please add your API key to Config.plist"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let statusCode):
            return "OpenAI API error: HTTP \(statusCode)"
        case .noContent:
            return "No content received from OpenAI"
        case .invalidJSONResponse:
            return "Could not parse JSON response from OpenAI"
        }
    }
}
