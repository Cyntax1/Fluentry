//
//  PracticeView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    @Query private var exercises: [Exercise]
    @Query private var words: [Word]
    @Query private var progress: [UserProgress]
    @State private var showingExerciseDetail = false
    @State private var selectedExerciseType: ExerciseType?
    @State private var selectedExercise: Exercise?
    @State private var showWordOfTheDay = false
    @State private var showFlashcards = false
    @State private var showSentenceBuilder = false
    
    // Track daily challenge completion
    @AppStorage("lastWordOfDayDate") private var lastWordOfDayDate: Double = 0
    @AppStorage("lastListeningDate") private var lastListeningDate: Double = 0
    @AppStorage("lastGrammarDate") private var lastGrammarDate: Double = 0
    
    private var userProgress: UserProgress? {
        progress.first
    }
    
    private var completedToday: Bool {
        guard let lastActive = userProgress?.lastActive else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }
    
    private func isCompletedToday(_ storageDate: Double) -> Bool {
        let lastDate = Date(timeIntervalSince1970: storageDate)
        return Calendar.current.isDateInToday(lastDate)
    }
    
    private func markChallengeComplete(_ type: String) {
        let now = Date().timeIntervalSince1970
        switch type {
        case "word":
            lastWordOfDayDate = now
        case "listening":
            lastListeningDate = now
        case "grammar":
            lastGrammarDate = now
        default:
            break
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header with interactive 3D-like card
                    practiceBanner
                    
                    // Statistics Section
                    statisticsSection
                    
                    // Daily challenges
                    dailyChallengeSection
                    
                    // Exercise categories
                    exerciseCategoriesGrid
                    
                    // Practice modes
                    practiceModeSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("Practice")
            .sheet(isPresented: $showingExerciseDetail) {
                if let exercise = selectedExercise {
                    ExerciseDetailView(exercise: exercise)
                } else if let exerciseType = selectedExerciseType {
                    // Use specialized interactive views for each exercise type
                    switch exerciseType {
                    case .speaking:
                        SpeakingExerciseView(
                            words: words,
                            onCompletion: {
                                // Refresh data when complete
                            }
                        )
                    case .listening:
                        ListeningExerciseView(
                            words: words,
                            onCompletion: {
                                markChallengeComplete("listening")
                            }
                        )
                    case .matchingPairs:
                        MatchingPairsView(
                            words: words,
                            onCompletion: {
                                // Mark complete
                            }
                        )
                    case .multipleChoice:
                        MultipleChoiceView(
                            words: words,
                            onCompletion: {
                                // Mark complete
                            }
                        )
                    case .fillInBlank:
                        FillInBlankView(
                            words: words,
                            onCompletion: {
                                markChallengeComplete("grammar")
                            }
                        )
                    case .scrambledWords:
                        ScrambledWordsView(
                            words: words,
                            onCompletion: {
                                // Mark complete
                            }
                        )
                    case .translation, .writeAnswer:
                        // Fallback for exercises not yet implemented
                        QuickExerciseView(
                            exerciseType: exerciseType,
                            words: words,
                            onCompletion: {
                                // Mark complete
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $showWordOfTheDay) {
                WordOfTheDayView()
            }
            .onChange(of: showWordOfTheDay) { _, isShowing in
                if !isShowing {
                    // Mark word of day as viewed when sheet is dismissed
                    markChallengeComplete("word")
                }
            }
            .sheet(isPresented: $showFlashcards) {
                FlashcardsView()
            }
            .sheet(isPresented: $showSentenceBuilder) {
                SentenceBuilderView()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .onChange(of: showingExerciseDetail) { _, isShowing in
                if !isShowing {
                    // Refresh data when returning from exercise
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        HStack(spacing: 15) {
            statCard(
                icon: "checkmark.circle.fill",
                value: "\(completedExercisesCount)",
                label: "Completed",
                color: .green
            )
            
            statCard(
                icon: "flame.fill",
                value: "\(userProgress?.streak ?? 0)",
                label: "Day Streak",
                color: .orange
            )
            
            statCard(
                icon: "chart.bar.fill",
                value: "\(words.count)",
                label: "Words",
                color: .blue
            )
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        ZStack {
            // Liquid Glass effect with layered shadows
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            VStack(spacing: 8) {
                // Floating icon with glass effect
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var completedExercisesCount: Int {
        exercises.filter { $0.completed }.count
    }
    
    // MARK: - Practice Banner
    private var practiceBanner: some View {
        ZStack {
            // Liquid Glass hero card with depth
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Multi-layer gradient borders for depth
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.5),
                                    .purple.opacity(0.5),
                                    .blue.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(
                    // Inner glow
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                )
                .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
                .shadow(color: .purple.opacity(0.15), radius: 15, x: 0, y: 8)
                .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
            
            VStack(spacing: 15) {
                // Floating glass title effect
                Text("Interactive Practice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("Enhance your English skills through\ninteractive exercises and challenges")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Liquid Glass button
                Button(action: {
                    let availableExercises = ExerciseType.allCases.filter {
                        $0 != .translation && $0 != .writeAnswer
                    }
                    selectedExerciseType = availableExercises.randomElement()
                    showingExerciseDetail = true
                }) {
                    ZStack {
                        // Outer glow
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 12)
                        
                        // Glass button
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.headline)
                            
                            Text("Start Quick Practice")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(25)
        }
        .frame(height: 250)
        .padding(.top)
    }
    
    // MARK: - Daily Challenge Section
    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Daily Challenges")
                .font(.title2)
                .fontWeight(.bold)
            
            dailyChallengeCards
        }
    }
    
    private var dailyChallengeCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Word of the Day - opens special view
                Button(action: {
                    showWordOfTheDay = true
                }) {
                    dailyChallengeCardContent(
                        title: "Word of the Day",
                        description: "Learn a new advanced word each day",
                        icon: "character.book.closed.fill",
                        color: .blue,
                        progress: isCompletedToday(lastWordOfDayDate) ? 1.0 : 0.0
                    )
                }
                .buttonStyle(.plain)
                
                // Listening Challenge
                dailyChallengeCard(
                    title: "Listening Challenge",
                    description: "Test your listening comprehension",
                    icon: "ear.fill",
                    color: .green,
                    progress: isCompletedToday(lastListeningDate) ? 1.0 : 0.0,
                    exerciseType: .listening,
                    challengeType: "listening"
                )
                
                // Grammar Quiz
                dailyChallengeCard(
                    title: "Grammar Quiz",
                    description: "Practice your grammar skills",
                    icon: "text.book.closed.fill",
                    color: .orange,
                    progress: isCompletedToday(lastGrammarDate) ? 1.0 : 0.0,
                    exerciseType: .fillInBlank,
                    challengeType: "grammar"
                )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 1)
        }
    }
    
    private func dailyChallengeCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        progress: Double,
        exerciseType: ExerciseType,
        challengeType: String
    ) -> some View {
        Button(action: {
            selectedExerciseType = exerciseType
            showingExerciseDetail = true
            // Mark challenge as started (will be completed when user finishes)
        }) {
            dailyChallengeCardContent(
                title: title,
                description: description,
                icon: icon,
                color: color,
                progress: progress
            )
        }
        .buttonStyle(.plain)
    }
    
    private func dailyChallengeCardContent(
        title: String,
        description: String,
        icon: String,
        color: Color,
        progress: Double
    ) -> some View {
        ZStack {
            // Liquid Glass card with depth
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(progress >= 1.0 ? 0.5 : 0.3),
                                    color.opacity(progress >= 1.0 ? 0.3 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: color.opacity(0.2), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header with floating glass icon
                HStack {
                    ZStack {
                        // Floating glow effect
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 45, height: 45)
                            .blur(radius: 10)
                        
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.4), lineWidth: 1)
                            )
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Spacer()
                    
                    // Status with glow
                    if progress >= 1.0 {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .blur(radius: 6)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.title3)
                        }
                    }
                }
                
                // Title with gradient
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 40, maxHeight: 50, alignment: .topLeading)
                
                // Glass progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 190 * progress, height: 6)
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                }
                .frame(height: 6)
            }
            .padding()
        }
        .frame(width: 220)
        .frame(minHeight: 170, maxHeight: 190)
    }
    
    // MARK: - Exercise Categories Grid
    private var exerciseCategoriesGrid: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Exercise Types")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(ExerciseType.allCases.filter { 
                    // Only show fully implemented, truly different exercises
                    $0 != .translation && $0 != .writeAnswer
                }, id: \.self) { exerciseType in
                    exerciseCategoryCard(
                        type: exerciseType,
                        icon: getExerciseIcon(exerciseType),
                        color: getExerciseColor(exerciseType)
                    )
                }
            }
        }
    }
    
    private func exerciseCategoryCard(type: ExerciseType, icon: String, color: Color) -> some View {
        Button(action: {
            selectedExerciseType = type
            showingExerciseDetail = true
        }) {
            ZStack {
                // Liquid Glass effect with ambient lighting
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                VStack(spacing: 15) {
                    // Floating icon with glass sphere effect
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 65, height: 65)
                            .blur(radius: 12)
                        
                        Circle()
                            .fill(.thinMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [color.opacity(0.5), color.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    Text(type.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding()
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Practice Mode Section
    private var practiceModeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Practice Modes")
                .font(.title2)
                .fontWeight(.bold)
            
            // Practice Cards
            VStack(spacing: 15) {
                practiceModeCard(
                    title: "Word of the Day",
                    description: "Discover and learn a new vocabulary word",
                    icon: "calendar.badge.clock",
                    color: .orange,
                    action: { showWordOfTheDay = true }
                )
                
                practiceModeCard(
                    title: "Vocabulary Flashcards",
                    description: "Review vocabulary words using flashcards",
                    icon: "rectangle.stack.fill",
                    color: .purple,
                    action: { showFlashcards = true }
                )
                
                practiceModeCard(
                    title: "Sentence Builder",
                    description: "Practice creating sentences with vocabulary",
                    icon: "text.bubble.fill",
                    color: .green,
                    action: { showSentenceBuilder = true }
                )
            }
        }
        .padding(.bottom, 20)
    }
    
    private func practiceModeCard(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            ZStack {
                // Liquid Glass card
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.12), radius: 10, x: 0, y: 5)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 15) {
                    // Floating glass icon
                    ZStack {
                        // Outer glow
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.opacity(0.2))
                            .frame(width: 65, height: 65)
                            .blur(radius: 12)
                        
                        // Glass container
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.8), color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Glowing arrow
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Functions
    private func getExerciseIcon(_ type: ExerciseType) -> String {
        switch type {
        case .multipleChoice:
            return "list.bullet.circle.fill"
        case .fillInBlank:
            return "character.cursor.ibeam"
        case .matchingPairs:
            return "arrow.left.and.right.circle.fill"
        case .speaking:
            return "mic.circle.fill"
        case .listening:
            return "ear.fill"
        case .translation:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .scrambledWords:
            return "shuffle.circle.fill"
        case .writeAnswer:
            return "pencil.circle.fill"
        }
    }
    
    private func getExerciseColor(_ type: ExerciseType) -> Color {
        switch type {
        case .multipleChoice:
            return .blue
        case .fillInBlank:
            return .green
        case .matchingPairs:
            return .orange
        case .speaking:
            return .red
        case .listening:
            return .purple
        case .translation:
            return .indigo
        case .scrambledWords:
            return .pink
        case .writeAnswer:
            return .teal
        }
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int?
    @State private var userAnswers: [Int] = []
    @State private var score = 0
    @State private var showResults = false
    @State private var textAnswer = ""
    
    // Parse exercise content (expected as JSON with questions)
    private var questions: [(question: String, options: [String], correctAnswer: Int)] {
        // Try to parse JSON content
        guard let data = exercise.content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // Return default questions if parsing fails
            return generateDefaultQuestions()
        }
        
        return json.compactMap { dict in
            guard let question = dict["question"] as? String,
                  let options = dict["options"] as? [String],
                  let correctAnswer = dict["correctAnswer"] as? Int else {
                return nil
            }
            return (question, options, correctAnswer)
        }
    }
    
    private func generateDefaultQuestions() -> [(question: String, options: [String], correctAnswer: Int)] {
        // Generate contextual questions based on exercise type
        switch exercise.type {
        case .multipleChoice:
            return [
                ("What is the meaning of 'Eloquent'?", [
                    "Speaking or writing clearly and effectively",
                    "Being extremely quiet",
                    "Moving slowly",
                    "Making loud noises"
                ], 0),
                ("Choose the synonym of 'Diligent'", [
                    "Lazy",
                    "Hardworking",
                    "Confused",
                    "Angry"
                ], 1)
            ]
        case .fillInBlank:
            return [
                ("The student was ________ in completing all assignments on time.", [
                    "diligent",
                    "negligent",
                    "aggressive",
                    "passive"
                ], 0)
            ]
        case .translation:
            return [
                ("Which word means 'existing everywhere at once'?", [
                    "Ubiquitous",
                    "Rare",
                    "Specific",
                    "Limited"
                ], 0)
            ]
        case .matchingPairs:
            return [
                ("Match 'Happy' with its synonym:", [
                    "Joyful",
                    "Sad",
                    "Angry",
                    "Tired"
                ], 0)
            ]
        case .scrambledWords:
            return [
                ("Unscramble this word: TLOEUQEN", [
                    "Eloquent",
                    "Eloqunet",
                    "Eloqeunt",
                    "Elquoent"
                ], 0)
            ]
        case .listening:
            return [
                ("Listen carefully: What word describes 'speaking fluently'?", [
                    "Eloquent",
                    "Silent",
                    "Confused",
                    "Hesitant"
                ], 0)
            ]
        case .speaking:
            return [
                ("Pronounce and identify: Which is correct?", [
                    "/ˈɛləkwənt/",
                    "/ɪˈlɒkwənt/",
                    "/ˈɛlkwɒnt/",
                    "/əˈlɒkwənt/"
                ], 0)
            ]
        default:
            return [
                ("Practice your English skills", [
                    "Continue",
                    "Skip",
                    "Review",
                    "Finish"
                ], 0)
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else if currentQuestion < questions.count {
                    questionView
                } else {
                    emptyView
                }
            }
            .navigationTitle(exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 30) {
            // Progress
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.blue)
                .padding(.horizontal)
            
            Text("Question \(currentQuestion + 1) of \(questions.count)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Question card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 15) {
                    Image(systemName: getExerciseIcon(exercise.type))
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(questions[currentQuestion].question)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(30)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            // Answer options
            if exercise.type != .writeAnswer {
                VStack(spacing: 12) {
                    ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                        answerButton(
                            option: questions[currentQuestion].options[index],
                            index: index
                        )
                    }
                }
                .padding(.horizontal)
            } else {
                // Text input for write answer
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Answer:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Type your answer here...", text: $textAnswer)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                handleNextQuestion()
            }) {
                HStack {
                    Spacer()
                    Text(currentQuestion + 1 < questions.count ? "Next Question" : "Finish")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(
                    selectedAnswer != nil || !textAnswer.isEmpty
                    ? LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        gradient: Gradient(colors: [.gray, .gray]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedAnswer == nil && textAnswer.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private func answerButton(option: String, index: Int) -> some View {
        Button(action: {
            selectedAnswer = index
        }) {
            ZStack {
                if selectedAnswer == index {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                HStack {
                    Text(option)
                        .font(.headline)
                        .foregroundColor(selectedAnswer == index ? .white : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if selectedAnswer == index {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            // Trophy
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                VStack {
                    Text("\(score)/\(questions.count)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Correct")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Performance message
            Text(getPerformanceMessage())
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(exercise.instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: {
                    resetExercise()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    markAsCompleted()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Complete & Close")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No Questions Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This exercise doesn't have any questions yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func handleNextQuestion() {
        if let selected = selectedAnswer {
            if selected == questions[currentQuestion].correctAnswer {
                score += 1
            }
            userAnswers.append(selected)
        } else if !textAnswer.isEmpty {
            // For write answer type, give credit if something was written
            score += 1
            userAnswers.append(0)
        }
        
        selectedAnswer = nil
        textAnswer = ""
        
        if currentQuestion + 1 < questions.count {
            currentQuestion += 1
        } else {
            showResults = true
        }
    }
    
    private func resetExercise() {
        currentQuestion = 0
        selectedAnswer = nil
        userAnswers.removeAll()
        score = 0
        showResults = false
        textAnswer = ""
    }
    
    private func markAsCompleted() {
        exercise.completed = true
        let percentage = Double(score) / Double(questions.count)
        exercise.score = Int(percentage * 100)
        try? modelContext.save()
    }
    
    private func getPerformanceMessage() -> String {
        let percentage = (Double(score) / Double(questions.count)) * 100
        
        if percentage >= 90 {
            return "Outstanding! 🌟"
        } else if percentage >= 70 {
            return "Great Job! 👏"
        } else if percentage >= 50 {
            return "Good Effort! 💪"
        } else {
            return "Keep Practicing! 📚"
        }
    }
    
    private func getExerciseIcon(_ type: ExerciseType) -> String {
        switch type {
        case .multipleChoice:
            return "list.bullet.circle.fill"
        case .fillInBlank:
            return "character.cursor.ibeam"
        case .matchingPairs:
            return "arrow.left.and.right.circle.fill"
        case .speaking:
            return "mic.circle.fill"
        case .listening:
            return "ear.fill"
        case .translation:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .scrambledWords:
            return "shuffle.circle.fill"
        case .writeAnswer:
            return "pencil.circle.fill"
        }
    }
}

// MARK: - Quick Exercise View
struct QuickExerciseView: View {
    let exerciseType: ExerciseType
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var showResults = false
    
    // Generate questions dynamically from vocabulary words or use defaults
    private var questions: [(question: String, options: [String], correctAnswer: Int)] {
        // Try to generate from user's vocabulary first
        if !words.isEmpty && words.count >= 3 {
            return generateQuestionsFromWords()
        }
        
        // Fallback to sample questions
        switch exerciseType {
        case .multipleChoice:
            return [
                ("What is the definition of 'Serendipity'?", [
                    "The occurrence of events by chance in a happy way",
                    "A state of being angry or upset",
                    "A formal written agreement",
                    "A type of tropical fruit"
                ], 0),
                ("Choose the correct meaning of 'Ubiquitous'", [
                    "Very rare or uncommon",
                    "Present or found everywhere",
                    "Extremely large in size",
                    "Moving very quickly"
                ], 1),
                ("What does 'Ephemeral' mean?", [
                    "Lasting forever",
                    "Highly valuable",
                    "Lasting for a very short time",
                    "Causing great damage"
                ], 2)
            ]
        case .fillInBlank:
            return [
                ("The beauty of cherry blossoms is ________, lasting only a few days.", [
                    "ephemeral",
                    "permanent",
                    "ubiquitous",
                    "extravagant"
                ], 0),
                ("Finding this perfect apartment was pure ________.", [
                    "catastrophe",
                    "requirement",
                    "serendipity",
                    "obligation"
                ], 2),
                ("Mobile phones are now ________ in modern society.", [
                    "obsolete",
                    "ubiquitous",
                    "forbidden",
                    "expensive"
                ], 1)
            ]
        default:
            // Default to some basic questions
            return [
                ("Which word means 'happening by chance in a beneficial way'?", [
                    "Serendipity",
                    "Ubiquitous",
                    "Ephemeral",
                    "Quintessential"
                ], 0)
            ]
        }
    }
    
    private func generateQuestionsFromWords() -> [(question: String, options: [String], correctAnswer: Int)] {
        var generatedQuestions: [(question: String, options: [String], correctAnswer: Int)] = []
        let shuffledWords = words.shuffled()
        let questionCount = min(5, shuffledWords.count)
        
        for i in 0..<questionCount {
            let word = shuffledWords[i]
            
            switch exerciseType {
            case .multipleChoice:
                // Create definition question
                let question = "What is the definition of '\(word.term)'?"
                
                // Get wrong answers from other words
                var options = [word.definition]
                let otherWords = shuffledWords.filter { $0.term != word.term }.shuffled()
                for j in 0..<min(3, otherWords.count) {
                    options.append(otherWords[j].definition)
                }
                
                // Shuffle options and find correct answer index
                options.shuffle()
                let correctIndex = options.firstIndex(of: word.definition) ?? 0
                
                generatedQuestions.append((question, options, correctIndex))
                
            case .fillInBlank:
                // Use the word's example sentence
                if !word.example.isEmpty {
                    let question = word.example.replacingOccurrences(of: word.term.lowercased(), with: "________", options: .caseInsensitive)
                    
                    var options = [word.term]
                    let otherWords = shuffledWords.filter { $0.term != word.term }.shuffled()
                    for j in 0..<min(3, otherWords.count) {
                        options.append(otherWords[j].term)
                    }
                    
                    options.shuffle()
                    let correctIndex = options.firstIndex(of: word.term) ?? 0
                    
                    generatedQuestions.append((question, options, correctIndex))
                }
                
            case .matchingPairs:
                // Match term with definition
                let question = "Match '\(word.term)' with its meaning:"
                
                var options = [word.definition]
                let otherWords = shuffledWords.filter { $0.term != word.term }.shuffled()
                for j in 0..<min(3, otherWords.count) {
                    options.append(otherWords[j].definition)
                }
                
                options.shuffle()
                let correctIndex = options.firstIndex(of: word.definition) ?? 0
                
                generatedQuestions.append((question, options, correctIndex))
                
            case .translation, .scrambledWords:
                // Choose synonym or related word
                let question = "Which word is most similar to '\(word.term)'?"
                
                var correctOption: String
                if !word.synonyms.isEmpty {
                    correctOption = word.synonyms.first!
                } else {
                    correctOption = word.term
                }
                
                var options: [String] = [correctOption]
                let otherWords = shuffledWords.filter { $0.term != word.term }.shuffled()
                for j in 0..<min(3, otherWords.count) {
                    options.append(otherWords[j].term)
                }
                
                options.shuffle()
                let correctIndex = options.firstIndex(of: correctOption) ?? 0
                
                generatedQuestions.append((question, options, correctIndex))
                
            default:
                // Default question format
                let question = "What does '\(word.term)' mean?"
                let options = [word.definition, "Unknown meaning", "Not applicable", "None of the above"]
                generatedQuestions.append((question, options, 0))
            }
        }
        
        return generatedQuestions.isEmpty ? [(("Practice English", ["Start", "Continue", "Review", "Finish"], 0))] : generatedQuestions
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else if currentQuestion < questions.count {
                    questionView
                }
            }
            .navigationTitle(exerciseType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 30) {
            // Progress indicator
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.blue)
                .padding(.horizontal)
            
            // Question counter
            Text("Question \(currentQuestion + 1) of \(questions.count)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Question
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text(questions[currentQuestion].question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(30)
            }
            .frame(height: 150)
            .padding(.horizontal)
            
            // Answer options
            VStack(spacing: 12) {
                ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                    answerButton(
                        option: questions[currentQuestion].options[index],
                        index: index
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Next button
            Button(action: {
                if let selected = selectedAnswer {
                    if selected == questions[currentQuestion].correctAnswer {
                        score += 1
                    }
                    
                    // Move to next question or show results
                    selectedAnswer = nil
                    if currentQuestion + 1 < questions.count {
                        currentQuestion += 1
                    } else {
                        showResults = true
                        onCompletion?()
                    }
                }
            }) {
                HStack {
                    Spacer()
                    Text("Next Question")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(
                    ZStack {
                        if selectedAnswer == nil {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                )
            }
            .disabled(selectedAnswer == nil)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private func answerButton(option: String, index: Int) -> some View {
        Button(action: {
            selectedAnswer = index
        }) {
            ZStack {
                if selectedAnswer == index {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                HStack {
                    Text(option)
                        .font(.headline)
                        .foregroundColor(selectedAnswer == index ? .white : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if selectedAnswer == index {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            // Results header
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                VStack {
                    Text("\(score)/\(questions.count)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Performance message
            Text(getPerformanceMessage())
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Keep practicing to improve your skills!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: {
                    // Reset for new exercise
                    currentQuestion = 0
                    selectedAnswer = nil
                    score = 0
                    showResults = false
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Done")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
    }
    
    private func getPerformanceMessage() -> String {
        let percentage = (Double(score) / Double(questions.count)) * 100
        
        if percentage >= 90 {
            return "Excellent! You've mastered this!"
        } else if percentage >= 70 {
            return "Great job! You're doing well!"
        } else if percentage >= 50 {
            return "Good effort! Keep practicing!"
        } else {
            return "Keep learning! You'll improve with practice."
        }
    }
}

#Preview {
    PracticeView()
        .modelContainer(for: Exercise.self, inMemory: true)
        .modelContainer(for: Word.self, inMemory: true)
}
