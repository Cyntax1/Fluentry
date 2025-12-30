//
//  SentenceBuilderView.swift
//  Fluentry
//
//  Interactive sentence building practice
//

import SwiftUI
import SwiftData

struct SentenceBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAI = OpenAIService.shared
    @Query private var words: [Word]
    
    @State private var selectedWord: Word?
    @State private var userSentence = ""
    @State private var isChecking = false
    @State private var feedback: String?
    @State private var showFeedback = false
    @State private var score: Int?
    @State private var aiSuggestion = ""
    @State private var showAISuggestion = false
    @State private var completedSentences = 0
    
    private var randomWord: Word? {
        words.randomElement()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Stats
                    statsView
                    
                    // Word Card
                    if let word = selectedWord {
                        wordCardView(word)
                        
                        // Sentence Input
                        sentenceInputView
                        
                        // Feedback
                        if showFeedback, let feedback = feedback {
                            feedbackView(feedback)
                        }
                        
                        // AI Suggestion
                        if showAISuggestion {
                            aiSuggestionView
                        }
                        
                        // Action Buttons
                        actionButtons
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Sentence Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadNewWord) {
                        Label("New Word", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if selectedWord == nil {
                    loadNewWord()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.05), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 15) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Sentence Builder")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Practice creating sentences with vocabulary words")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        HStack(spacing: 20) {
            statItem(icon: "checkmark.circle.fill", value: "\(completedSentences)", label: "Completed", color: .green)
            
            if let score = score {
                statItem(icon: "star.fill", value: "\(score)%", label: "Last Score", color: .yellow)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Word Card
    private func wordCardView(_ word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Word to Use:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(word.term)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text(word.pronunciation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(word.difficulty.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                        Text("Definition:")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    Text(word.definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Display synonyms if available
                if !word.synonyms.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.purple)
                            Text("Synonyms:")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(word.synonyms.prefix(5), id: \.self) { synonym in
                                    Text(synonym)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Display example usage
                if !word.example.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.orange)
                            Text("Example Usage:")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        Text("\"\(word.example)\"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sentence Input
    private var sentenceInputView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.green)
                Text("Your Sentence:")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            ZStack(alignment: .topLeading) {
                if userSentence.isEmpty {
                    Text("Write a sentence using the word above...")
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $userSentence)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Text("\(userSentence.count) characters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Feedback View
    private func feedbackView(_ feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: score ?? 0 >= 70 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(score ?? 0 >= 70 ? .green : .orange)
                
                Text("Feedback")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let score = score {
                    Text("\(score)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(score >= 70 ? .green : .orange)
                }
            }
            
            Text(feedback)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - AI Suggestion View
    private var aiSuggestionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                
                Text("AI Example Sentence")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(aiSuggestion)
                .font(.body)
                .italic()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Check Sentence Button
            Button(action: checkSentence) {
                HStack {
                    Spacer()
                    if isChecking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Checking...")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Check My Sentence")
                    }
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    ZStack {
                        if userSentence.count < 10 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                )
            }
            .disabled(userSentence.count < 10 || isChecking)
            
            // Get AI Example Button
            Button(action: getAIExample) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Show AI Example")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isChecking)
            
            // Try Another Word Button
            if showFeedback {
                Button(action: tryAnotherWord) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Another Word")
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble")
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Words Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add words to your vocabulary to start building sentences.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Functions
    private func loadNewWord() {
        selectedWord = randomWord
        userSentence = ""
        feedback = nil
        showFeedback = false
        score = nil
        aiSuggestion = ""
        showAISuggestion = false
    }
    
    private func checkSentence() {
        guard let word = selectedWord else { return }
        guard openAI.isConfigured else {
            feedback = "AI checking requires an OpenAI API key. Your sentence looks good! Try to use proper grammar and include the word '\(word.term)' naturally."
            score = 75
            showFeedback = true
            return
        }
        
        isChecking = true
        
        Task {
            do {
                let prompt = """
                Evaluate this sentence for grammar, word usage, and appropriateness:
                
                Word to use: "\(word.term)"
                Definition: "\(word.definition)"
                Student's sentence: "\(userSentence)"
                
                Provide:
                1. A score from 0-100
                2. Brief feedback on grammar and usage
                3. One specific improvement suggestion
                
                Format: "Score: [number]\n[feedback and suggestion]"
                """
                
                let messages = [
                    OpenAIRequest.Message(role: "system", content: "You are an encouraging English teacher providing constructive feedback."),
                    OpenAIRequest.Message(role: "user", content: prompt)
                ]
                
                let response = try await openAI.chatCompletion(messages: messages, maxTokens: 300)
                
                // Parse response
                let lines = response.components(separatedBy: "\n")
                if let scoreLine = lines.first, scoreLine.contains("Score:") {
                    let scoreString = scoreLine.replacingOccurrences(of: "Score:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    score = Int(scoreString) ?? 75
                    
                    let feedbackText = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    feedback = feedbackText
                } else {
                    feedback = response
                    score = 75
                }
                
                await MainActor.run {
                    isChecking = false
                    showFeedback = true
                    if (score ?? 0) >= 70 {
                        completedSentences += 1
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    feedback = "Great effort! Your sentence uses the word correctly. Keep practicing to improve your grammar and fluency."
                    score = 70
                    showFeedback = true
                }
            }
        }
    }
    
    private func getAIExample() {
        guard let word = selectedWord else { return }
        
        if !openAI.isConfigured {
            aiSuggestion = word.example
            showAISuggestion = true
            return
        }
        
        isChecking = true
        
        Task {
            do {
                let prompt = "Create one excellent example sentence using the word '\(word.term)' (meaning: \(word.definition)). Make it natural and engaging."
                
                let messages = [
                    OpenAIRequest.Message(role: "system", content: "You are a creative English teacher."),
                    OpenAIRequest.Message(role: "user", content: prompt)
                ]
                
                let response = try await openAI.chatCompletion(messages: messages, maxTokens: 100)
                
                await MainActor.run {
                    aiSuggestion = response.trimmingCharacters(in: .whitespacesAndNewlines)
                    showAISuggestion = true
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    aiSuggestion = word.example
                    showAISuggestion = true
                    isChecking = false
                }
            }
        }
    }
    
    private func tryAnotherWord() {
        loadNewWord()
    }
}

#Preview {
    SentenceBuilderView()
        .modelContainer(for: Word.self, inMemory: true)
}
