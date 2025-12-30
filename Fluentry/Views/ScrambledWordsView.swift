//
//  ScrambledWordsView.swift
//  Fluentry
//
//  Interactive word unscrambling game
//

import SwiftUI

struct ScrambledWordsView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var gameWords: [Word] = []
    @State private var currentWordIndex = 0
    @State private var scrambledLetters: [LetterTile] = []
    @State private var answerLetters: [LetterTile] = []
    @State private var score = 0
    @State private var showResults = false
    @State private var feedback = ""
    @State private var showHint = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.teal.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else {
                    gameView
                }
            }
            .navigationTitle("Unscramble Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupGame()
            }
        }
    }
    
    private var gameView: some View {
        VStack(spacing: 25) {
            if gameWords.isEmpty || currentWordIndex >= gameWords.count {
                ProgressView("Loading...")
                    .padding()
            } else {
                // Progress
                ProgressView(value: Double(currentWordIndex + 1), total: Double(gameWords.count))
                    .tint(.green)
                    .padding(.horizontal)
                
                Text("Word \(currentWordIndex + 1) of \(gameWords.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Definition clue
                VStack(spacing: 10) {
                    Text("Unscramble this word:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(gameWords[currentWordIndex].definition)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            
            // Hint button
            if !showHint {
                Button(action: {
                    showHint = true
                    HapticFeedback.light()
                }) {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("Show Hint")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orange)
                }
            } else {
                Text("First letter: \(String(gameWords[currentWordIndex].term.prefix(1)))")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Answer area - Show what user is building
            VStack(spacing: 15) {
                Text("Your Answer:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 5) {
                    if answerLetters.isEmpty {
                        Text("Tap letters below to build your answer")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(answerLetters) { letter in
                            Button(action: {
                                returnLetterToPool(letter)
                            }) {
                                Text(letter.letter.uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 45, height: 55)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Scrambled letters pool - Simpler grid layout
            VStack(spacing: 15) {
                Text("Available Letters:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 45))
                ], spacing: 10) {
                    ForEach(scrambledLetters) { letter in
                        Button(action: {
                            addLetterToAnswer(letter)
                        }) {
                            Text(letter.letter.uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 45, height: 55)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .teal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Feedback
            if !feedback.isEmpty {
                Text(feedback)
                    .font(.headline)
                    .foregroundColor(feedback.contains("✓") ? .green : .red)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            // Check button
            Button(action: checkAnswer) {
                Text("Check Answer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(answerLetters.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            .disabled(answerLetters.isEmpty)
            .padding(.horizontal)
            
            // Next button
            if feedback.contains("✓") {
                Button(action: nextWord) {
                    Text(currentWordIndex < gameWords.count - 1 ? "Next Word" : "See Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            }
        }
        .padding(.vertical)
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .teal], startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text("All Words Unscrambled!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                ResultRow(label: "Words Solved", value: "\(score) / \(gameWords.count)")
                ResultRow(label: "Success Rate", value: "\(Int(Double(score) / Double(gameWords.count) * 100))%")
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: resetGame) {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
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
    
    private func setupGame() {
        gameWords = Array(words.shuffled().prefix(5))
        setupWord()
    }
    
    private func setupWord() {
        let word = gameWords[currentWordIndex].term
        let letters = word.map { String($0) }
        let shuffled = letters.shuffled()
        
        scrambledLetters = shuffled.enumerated().map { index, letter in
            LetterTile(id: UUID(), letter: letter, originalIndex: index)
        }
        answerLetters = []
        feedback = ""
        showHint = false
    }
    
    private func addLetterToAnswer(_ letter: LetterTile) {
        HapticFeedback.light()
        answerLetters.append(letter)
        scrambledLetters.removeAll { $0.id == letter.id }
    }
    
    private func returnLetterToPool(_ letter: LetterTile) {
        HapticFeedback.light()
        scrambledLetters.append(letter)
        answerLetters.removeAll { $0.id == letter.id }
    }
    
    private func checkAnswer() {
        let userAnswer = answerLetters.map { $0.letter }.joined()
        let correct = gameWords[currentWordIndex].term
        
        if userAnswer.lowercased() == correct.lowercased() {
            feedback = "✓ Correct! Well done!"
            score += 1
            HapticFeedback.success()
        } else {
            feedback = "❌ Try again! The word is '\(correct)'"
            HapticFeedback.error()
        }
    }
    
    private func nextWord() {
        if currentWordIndex < gameWords.count - 1 {
            currentWordIndex += 1
            setupWord()
        } else {
            showResults = true
        }
    }
    
    private func resetGame() {
        currentWordIndex = 0
        score = 0
        showResults = false
        setupGame()
    }
}

// MARK: - Letter Tile Model
struct LetterTile: Identifiable {
    let id: UUID
    let letter: String
    let originalIndex: Int
}

