//
//  AIVocabularyGeneratorView.swift
//  Fluentry
//
//  AI-powered vocabulary generation view
//

import SwiftUI
import SwiftData

struct AIVocabularyGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var openAI = OpenAIService.shared
    
    @State private var selectedDifficulty: DifficultyLevel = .medium
    @State private var category = "General"
    @State private var isGenerating = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var generatedWord: Word?
    
    let suggestedCategories = [
        "General", "Business", "Academic", "Technology",
        "Medical", "Legal", "Travel", "Food & Dining",
        "Entertainment", "Sports", "Science", "Arts"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Difficulty Selection
                    difficultySelectionView
                    
                    // Category Selection
                    categorySelectionView
                    
                    // Generated Word Preview
                    if let word = generatedWord {
                        generatedWordPreview(word)
                    }
                    
                    // Generate Button
                    generateButtonView
                }
                .padding()
            }
            .navigationTitle("AI Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Generate Another") {
                    generatedWord = nil
                }
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("New word has been added to your vocabulary!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isGenerating)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
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
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("AI Vocabulary Builder")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Discover new words tailored to your level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Difficulty Selection
    private var difficultySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty Level")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        difficultyPill(difficulty)
                    }
                }
            }
        }
    }
    
    private func difficultyPill(_ difficulty: DifficultyLevel) -> some View {
        Button(action: {
            withAnimation {
                selectedDifficulty = difficulty
            }
        }) {
            VStack(spacing: 6) {
                Text(difficulty.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(width: 100, height: 60)
            .background(
                selectedDifficulty == difficulty
                ? getDifficultyColor(difficulty).opacity(0.2)
                : Color.gray.opacity(0.1)
            )
            .foregroundColor(
                selectedDifficulty == difficulty
                ? getDifficultyColor(difficulty)
                : .primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedDifficulty == difficulty ? getDifficultyColor(difficulty) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .fontWeight(.bold)
            
            TextField("Enter category", text: $category)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Suggestions:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedCategories, id: \.self) { suggested in
                        Button(action: {
                            category = suggested
                        }) {
                            Text(suggested)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    category == suggested
                                    ? Color.blue.opacity(0.2)
                                    : Color.gray.opacity(0.1)
                                )
                                .foregroundColor(
                                    category == suggested ? .blue : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Generated Word Preview
    private func generatedWordPreview(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Generated Word")
                .font(.headline)
                .fontWeight(.bold)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Term and pronunciation
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.term)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(word.pronunciation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Definition
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Definition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(word.definition)
                            .font(.body)
                    }
                    
                    // Example
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\"\(word.example)\"")
                            .font(.body)
                            .italic()
                    }
                    
                    // Category and difficulty
                    HStack {
                        Text(word.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        Text(word.difficulty.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getDifficultyColor(word.difficulty).opacity(0.1))
                            .foregroundColor(getDifficultyColor(word.difficulty))
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Generate Button
    private var generateButtonView: some View {
        Button(action: generateWord) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Generating...")
                } else {
                    Image(systemName: "sparkles")
                    Text(generatedWord == nil ? "Generate Word" : "Save & Generate Another")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .disabled(isGenerating || category.isEmpty)
        .padding(.top, 10)
    }
    
    // MARK: - Generate Word Function
    private func generateWord() {
        // Save previous word if exists
        if let word = generatedWord {
            modelContext.insert(word)
            try? modelContext.save()
        }
        
        isGenerating = true
        
        Task {
            do {
                let result = try await openAI.generateVocabularyWord(
                    difficulty: selectedDifficulty,
                    category: category
                )
                
                // Create the word
                let newWord = Word(
                    term: result.term,
                    definition: result.definition,
                    example: result.example,
                    pronunciation: result.pronunciation,
                    difficulty: selectedDifficulty,
                    category: category
                )
                
                await MainActor.run {
                    isGenerating = false
                    generatedWord = newWord
                    
                    // If first generation, just show the word
                    // If subsequent generation, show success and save
                    if generatedWord != nil {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getDifficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .easy: return .blue
        case .medium: return .orange
        case .hard: return .red
        case .advanced: return .purple
        }
    }
}

#Preview {
    AIVocabularyGeneratorView()
        .modelContainer(for: Word.self, inMemory: true)
}
