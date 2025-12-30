//
//  AILessonGeneratorView.swift
//  Fluentry
//
//  AI-powered lesson generation view
//

import SwiftUI
import SwiftData

struct AILessonGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var openAI = OpenAIService.shared
    
    @State private var selectedCategory: LessonCategory = .vocabulary
    @State private var selectedDifficulty: DifficultyLevel = .medium
    @State private var customTopic = ""
    @State private var isGenerating = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Category Selection
                    categorySelectionView
                    
                    // Difficulty Selection
                    difficultySelectionView
                    
                    // Custom Topic (Optional)
                    customTopicView
                    
                    // Generate Button
                    generateButtonView
                }
                .padding()
            }
            .navigationTitle("AI Lesson Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("New lesson has been generated and added to your library!")
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
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("AI-Powered Lesson Creator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Generate personalized English lessons using AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Category Selection
    private var categorySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lesson Category")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LessonCategory.allCases, id: \.self) { category in
                        categoryPill(category)
                    }
                }
            }
        }
    }
    
    private func categoryPill(_ category: LessonCategory) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: getCategoryIcon(category))
                    .font(.title2)
                
                Text(category.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 90, height: 90)
            .background(
                selectedCategory == category
                ? getCategoryColor(category).opacity(0.2)
                : Color.gray.opacity(0.1)
            )
            .foregroundColor(
                selectedCategory == category
                ? getCategoryColor(category)
                : .primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedCategory == category ? getCategoryColor(category) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
    
    // MARK: - Difficulty Selection
    private var difficultySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty Level")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                    difficultyButton(difficulty)
                }
            }
        }
    }
    
    private func difficultyButton(_ difficulty: DifficultyLevel) -> some View {
        Button(action: {
            withAnimation {
                selectedDifficulty = difficulty
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue.capitalized)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(getDifficultyDescription(difficulty))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedDifficulty == difficulty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(getDifficultyColor(difficulty))
                }
            }
            .padding()
            .background(
                selectedDifficulty == difficulty
                ? getDifficultyColor(difficulty).opacity(0.1)
                : Color.gray.opacity(0.05)
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
        .buttonStyle(.plain)
    }
    
    // MARK: - Custom Topic
    private var customTopicView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Topic (Optional)")
                .font(.headline)
                .fontWeight(.bold)
            
            TextField("e.g., Business English, Travel Phrases", text: $customTopic)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Leave blank for a general lesson in the selected category")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Generate Button
    private var generateButtonView: some View {
        Button(action: generateLesson) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Generating...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate Lesson")
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
        .disabled(isGenerating)
        .padding(.top, 10)
    }
    
    // MARK: - Generate Lesson Function
    private func generateLesson() {
        isGenerating = true
        
        Task {
            do {
                let topic = customTopic.isEmpty ? nil : customTopic
                let result = try await openAI.generateLesson(
                    category: selectedCategory,
                    difficulty: selectedDifficulty,
                    topic: topic
                )
                
                // Create and save the lesson
                let newLesson = Lesson(
                    title: result.title,
                    lessonDescription: result.description,
                    content: result.content,
                    category: selectedCategory,
                    difficulty: selectedDifficulty
                )
                
                modelContext.insert(newLesson)
                try modelContext.save()
                
                await MainActor.run {
                    isGenerating = false
                    showSuccess = true
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
    private func getCategoryIcon(_ category: LessonCategory) -> String {
        switch category {
        case .vocabulary: return "character.book.closed"
        case .grammar: return "doc.text"
        case .pronunciation: return "waveform.and.mic"
        case .reading: return "book"
        case .writing: return "pencil"
        case .conversation: return "bubble.left.and.bubble.right"
        case .idioms: return "quote.bubble"
        case .slang: return "speaker.wave.2"
        }
    }
    
    private func getCategoryColor(_ category: LessonCategory) -> Color {
        switch category {
        case .vocabulary: return .blue
        case .grammar: return .green
        case .pronunciation: return .purple
        case .reading: return .orange
        case .writing: return .red
        case .conversation: return .indigo
        case .idioms: return .yellow
        case .slang: return .pink
        }
    }
    
    private func getDifficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .easy: return .blue
        case .medium: return .orange
        case .hard: return .red
        case .advanced: return .purple
        }
    }
    
    private func getDifficultyDescription(_ difficulty: DifficultyLevel) -> String {
        switch difficulty {
        case .beginner: return "Just starting out"
        case .easy: return "Basic concepts"
        case .medium: return "Intermediate learners"
        case .hard: return "Advanced topics"
        case .advanced: return "Expert level"
        }
    }
}

#Preview {
    AILessonGeneratorView()
        .modelContainer(for: Lesson.self, inMemory: true)
}
