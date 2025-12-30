//
//  MultipleChoiceView.swift
//  Fluentry
//
//  AI-generated multiple choice questions
//

import SwiftUI

struct MultipleChoiceView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAI = OpenAIService.shared
    
    @State private var questions: [MCQuestion] = []
    @State private var currentQuestion = 0
    @State private var selectedOption: Int?
    @State private var score = 0
    @State private var showResults = false
    @State private var isLoading = true
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var hasGenerated = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.red.opacity(0.1)],
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
            .navigationTitle("Multiple Choice")
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
            Text("🤖 AI is crafting your questions...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.orange)
                .padding()
            
            Text("Question \(currentQuestion + 1) of \(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Question card
                    VStack(spacing: 20) {
                        Text(questions[currentQuestion].question)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                            OptionButton(
                                text: questions[currentQuestion].options[index],
                                isSelected: selectedOption == index,
                                isCorrect: showFeedback && index == questions[currentQuestion].correctAnswer,
                                isWrong: showFeedback && selectedOption == index && index != questions[currentQuestion].correctAnswer,
                                onTap: {
                                    selectOption(index)
                                }
                            )
                            .disabled(showFeedback)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Feedback
                    if showFeedback {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                                    .font(.title2)
                                Text(isCorrect ? "Correct!" : "Incorrect")
                                    .font(.headline)
                                    .foregroundColor(isCorrect ? .green : .red)
                            }
                            
                            if !isCorrect {
                                Text("The correct answer was: \(questions[currentQuestion].options[questions[currentQuestion].correctAnswer])")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: nextQuestion) {
                                Text(currentQuestion < questions.count - 1 ? "Next Question" : "See Results")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isCorrect ? Color.green : Color.orange)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
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
                    .fill(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text("Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                ResultRow(label: "Score", value: "\(score) / \(questions.count)")
                ResultRow(label: "Percentage", value: "\(Int(Double(score) / Double(questions.count) * 100))%")
                ResultRow(label: "Grade", value: getGrade())
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    resetQuiz()
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
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
            // Fallback to simple questions
            generateSimpleQuestions()
            return
        }
        
        Task {
            do {
                let selectedWords = Array(words.shuffled().prefix(5))
                var generatedQuestions: [MCQuestion] = []
                
                for word in selectedWords {
                    let prompt = """
                    Create a multiple choice question for learning the word: "\(word.term)"
                    Definition: \(word.definition)
                    
                    Return ONLY valid JSON:
                    {
                      "question": "Question text here",
                      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
                      "correctAnswer": 0
                    }
                    
                    Make the question test understanding of the word. Include 3 plausible wrong answers.
                    """
                    
                    let response = try await openAI.chatCompletion(
                        messages: [
                            .init(role: "system", content: "You are a vocabulary test generator. Return only JSON."),
                            .init(role: "user", content: prompt)
                        ],
                        temperature: 0.7,
                        maxTokens: 300
                    )
                    
                    if let data = response.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let question = json["question"] as? String,
                       let options = json["options"] as? [String],
                       let correctAnswer = json["correctAnswer"] as? Int {
                        generatedQuestions.append(MCQuestion(
                            question: question,
                            options: options,
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
                .map { $0.definition }
            
            var options = [word.definition] + wrongOptions
            options.shuffle()
            let correctIndex = options.firstIndex(of: word.definition) ?? 0
            
            return MCQuestion(
                question: "What does '\(word.term)' mean?",
                options: Array(options),
                correctAnswer: correctIndex
            )
        }
        isLoading = false
    }
    
    private func selectOption(_ index: Int) {
        guard selectedOption == nil else { return }
        selectedOption = index
        isCorrect = index == questions[currentQuestion].correctAnswer
        
        if isCorrect {
            score += 1
            HapticFeedback.success()
        } else {
            HapticFeedback.error()
        }
        
        showFeedback = true
    }
    
    private func nextQuestion() {
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
            selectedOption = nil
            showFeedback = false
            isCorrect = false
        } else {
            showResults = true
        }
    }
    
    private func resetQuiz() {
        currentQuestion = 0
        selectedOption = nil
        score = 0
        showResults = false
        showFeedback = false
        isLoading = true
        generateQuestions()
    }
    
    private func getGrade() -> String {
        let percentage = Double(score) / Double(questions.count)
        if percentage >= 0.9 { return "A" }
        if percentage >= 0.8 { return "B" }
        if percentage >= 0.7 { return "C" }
        if percentage >= 0.6 { return "D" }
        return "F"
    }
}

// MARK: - Models
struct MCQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
}

// MARK: - Option Button
struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isCorrect || isWrong {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: isCorrect)
        .animation(.spring(response: 0.3), value: isWrong)
    }
    
    private var backgroundColor: Color {
        if isCorrect { return .green.opacity(0.2) }
        if isWrong { return .red.opacity(0.2) }
        if isSelected { return .orange.opacity(0.1) }
        return .white
    }
    
    private var borderColor: Color {
        if isCorrect { return .green }
        if isWrong { return .red }
        if isSelected { return .orange }
        return .gray.opacity(0.3)
    }
    
    private var textColor: Color {
        if isCorrect { return .green }
        if isWrong { return .red }
        return .primary
    }
}
