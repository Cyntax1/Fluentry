//
//  FillInBlankView.swift
//  Fluentry
//
//  AI-generated fill in the blank exercises
//

import SwiftUI

struct FillInBlankView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAI = OpenAIService.shared
    
    @State private var questions: [FIBQuestion] = []
    @State private var currentQuestion = 0
    @State private var userAnswer = ""
    @State private var score = 0
    @State private var showResults = false
    @State private var isLoading = true
    @State private var feedback = ""
    @State private var showAnswer = false
    @State private var hasGenerated = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if showResults {
                    resultsView
                } else if !questions.isEmpty {
                    questionView
                }
            }
            .navigationTitle("Fill in the Blank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !hasGenerated {
                    hasGenerated = true
                    generateQuestions()
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("🤖 AI is creating sentences...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.cyan)
                .padding()
            
            Text("Sentence \(currentQuestion + 1) of \(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Sentence with blank
                    SentenceCard(
                        sentence: questions[currentQuestion].sentence,
                        blank: "______"
                    )
                    .padding(.horizontal)
                    
                    // Word bank
                    VStack(spacing: 10) {
                        Text("Word Bank:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(questions[currentQuestion].options, id: \.self) { option in
                                WordChip(
                                    word: option,
                                    isSelected: userAnswer == option,
                                    onTap: {
                                        userAnswer = option
                                        HapticFeedback.light()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Your answer
                    if !userAnswer.isEmpty {
                        VStack(spacing: 10) {
                            Text("Your Answer:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(questions[currentQuestion].sentence.replacingOccurrences(of: "_____", with: userAnswer))
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Feedback
                    if !feedback.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: feedback.contains("Correct") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(feedback.contains("Correct") ? .green : .red)
                                    .font(.title2)
                                Text(feedback)
                                    .font(.headline)
                                    .foregroundColor(feedback.contains("Correct") ? .green : .red)
                            }
                            
                            if showAnswer {
                                Text("Correct answer: \(questions[currentQuestion].correctAnswer)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: nextQuestion) {
                                Text(currentQuestion < questions.count - 1 ? "Next Sentence" : "See Results")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(feedback.contains("Correct") ? Color.green : Color.cyan)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        // Check button
                        Button(action: checkAnswer) {
                            Text("Check Answer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(userAnswer.isEmpty ? Color.gray : Color.cyan)
                                .cornerRadius(12)
                        }
                        .disabled(userAnswer.isEmpty)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text("Exercise Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                ResultRow(label: "Score", value: "\(score) / \(questions.count)")
                ResultRow(label: "Percentage", value: "\(Int(Double(score) / Double(questions.count) * 100))%")
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: resetExercise) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    onCompletion?()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func generateQuestions() {
        guard openAI.isConfigured else {
            generateSimpleQuestions()
            return
        }
        
        Task {
            do {
                let selectedWords = Array(words.shuffled().prefix(5))
                var generatedQuestions: [FIBQuestion] = []
                
                for word in selectedWords {
                    let prompt = """
                    Create a fill-in-the-blank sentence for the word: "\(word.term)"
                    Definition: \(word.definition)
                    
                    Return ONLY valid JSON:
                    {
                      "sentence": "Sentence with _____ where the word goes",
                      "options": ["correct word", "wrong word 1", "wrong word 2", "wrong word 3"],
                      "correctAnswer": "correct word"
                    }
                    
                    Make the sentence natural and contextual. Include 3 plausible wrong options.
                    """
                    
                    let response = try await openAI.chatCompletion(
                        messages: [
                            .init(role: "system", content: "You are a language exercise generator. Return only JSON."),
                            .init(role: "user", content: prompt)
                        ],
                        temperature: 0.7,
                        maxTokens: 300
                    )
                    
                    if let data = response.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let sentence = json["sentence"] as? String,
                       let options = json["options"] as? [String],
                       let correctAnswer = json["correctAnswer"] as? String {
                        generatedQuestions.append(FIBQuestion(
                            sentence: sentence,
                            options: options.shuffled(),
                            correctAnswer: correctAnswer
                        ))
                    }
                }
                
                await MainActor.run {
                    questions = generatedQuestions
                    isLoading = false
                }
            } catch {
                print("❌ Failed to generate questions: \(error)")
                generateSimpleQuestions()
            }
        }
    }
    
    private func generateSimpleQuestions() {
        let selectedWords = Array(words.shuffled().prefix(5))
        questions = selectedWords.map { word in
            let wrongOptions = words.filter { $0.term != word.term }
                .shuffled()
                .prefix(3)
                .map { $0.term }
            
            var options = [word.term] + wrongOptions
            options.shuffle()
            
            return FIBQuestion(
                sentence: "The \(word.definition.lowercased()) can be described as _____.",
                options: Array(options),
                correctAnswer: word.term
            )
        }
        isLoading = false
    }
    
    private func checkAnswer() {
        if userAnswer.lowercased() == questions[currentQuestion].correctAnswer.lowercased() {
            feedback = "Correct! 🎉"
            score += 1
            HapticFeedback.success()
        } else {
            feedback = "Incorrect"
            showAnswer = true
            HapticFeedback.error()
        }
    }
    
    private func nextQuestion() {
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
            userAnswer = ""
            feedback = ""
            showAnswer = false
        } else {
            showResults = true
        }
    }
    
    private func resetExercise() {
        currentQuestion = 0
        userAnswer = ""
        score = 0
        showResults = false
        feedback = ""
        showAnswer = false
        isLoading = true
        generateQuestions()
    }
}

// MARK: - Models
struct FIBQuestion {
    let sentence: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - Sentence Card
struct SentenceCard: View {
    let sentence: String
    let blank: String
    
    var body: some View {
        Text(sentence.replacingOccurrences(of: "_____", with: blank))
            .font(.title3)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .padding(25)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
}

// MARK: - Word Chip
struct WordChip: View {
    let word: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(word)
                .font(.body)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.white, .white], startPoint: .leading, endPoint: .trailing))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: isSelected ? .cyan.opacity(0.3) : .clear, radius: 5)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
