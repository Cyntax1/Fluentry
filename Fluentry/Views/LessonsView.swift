//
//  LessonsView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData

struct LessonsView: View {
    @Query(sort: \Lesson.title) private var lessons: [Lesson]
    @State private var selectedCategory: LessonCategory?
    @State private var searchText = ""
    @State private var showAIGenerator = false
    
    private var filteredLessons: [Lesson] {
        lessons.filter { lesson in
            let categoryMatch = selectedCategory == nil || lesson.category == selectedCategory
            let searchMatch = searchText.isEmpty || 
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.lessonDescription.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && searchMatch
        }
    }
    
    private var groupedLessons: [DifficultyLevel: [Lesson]] {
        Dictionary(grouping: filteredLessons) { $0.difficulty }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search and filter
                searchFilterBar
                
                // Category filter pills
                categoryFilterBar
                
                // Lessons list
                ScrollView {
                    VStack(spacing: 30) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                            if let lessonsForDifficulty = groupedLessons[difficulty], !lessonsForDifficulty.isEmpty {
                                lessonGroupView(for: difficulty, lessons: lessonsForDifficulty)
                            }
                        }
                        
                        if filteredLessons.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Lessons")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAIGenerator = true }) {
                        Label("AI Generate", systemImage: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                AILessonGeneratorView()
            }
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
    
    // MARK: - Search and Filter Bar
    private var searchFilterBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search lessons", text: $searchText)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryFilterPill(nil, label: "All")
                
                ForEach(LessonCategory.allCases, id: \.self) { category in
                    categoryFilterPill(category, label: category.rawValue.capitalized)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
    }
    
    private func categoryFilterPill(_ category: LessonCategory?, label: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(selectedCategory == category ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedCategory == category
                    ? Color.blue
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Lesson Group View
    private func lessonGroupView(for difficulty: DifficultyLevel, lessons: [Lesson]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(difficulty.rawValue.capitalized)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 5)
            
            ForEach(lessons) { lesson in
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    lessonCardView(for: lesson)
                }
            }
        }
    }
    
    private func lessonCardView(for lesson: Lesson) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    // Category tag and completion status
                    HStack {
                        Text(lesson.category.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(categoryColor(for: lesson.category).opacity(0.1))
                            .foregroundColor(categoryColor(for: lesson.category))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        if lesson.completed {
                            HStack {
                                Text("Completed")
                                    .font(.caption)
                                
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .foregroundColor(.green)
                        } else {
                            HStack {
                                Text("In Progress")
                                    .font(.caption)
                                
                                Image(systemName: "ellipsis.circle")
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    // Lesson title
                    Text(lesson.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // Lesson description
                    Text(lesson.lessonDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Visual indicator based on lesson category
                categoryIcon(for: lesson.category)
                    .font(.title)
                    .foregroundColor(categoryColor(for: lesson.category))
                    .frame(width: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Category Helpers
    private func categoryIcon(for category: LessonCategory) -> some View {
        let iconName: String
        
        switch category {
        case .vocabulary:
            iconName = "character.book.closed"
        case .grammar:
            iconName = "doc.text"
        case .pronunciation:
            iconName = "waveform.and.mic"
        case .reading:
            iconName = "book"
        case .writing:
            iconName = "pencil"
        case .conversation:
            iconName = "bubble.left.and.bubble.right"
        case .idioms:
            iconName = "quote.bubble"
        case .slang:
            iconName = "speaker.wave.2"
        }
        
        return Image(systemName: iconName)
    }
    
    private func categoryColor(for category: LessonCategory) -> Color {
        switch category {
        case .vocabulary:
            return .blue
        case .grammar:
            return .green
        case .pronunciation:
            return .purple
        case .reading:
            return .orange
        case .writing:
            return .red
        case .conversation:
            return .indigo
        case .idioms:
            return .yellow
        case .slang:
            return .pink
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Lessons Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your filters or search terms to find what you're looking for.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding(.top, 50)
    }
}

// MARK: - Lesson Detail View
struct LessonDetailView: View {
    let lesson: Lesson
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title and category
                VStack(alignment: .leading, spacing: 10) {
                    // Category pill
                    Text(lesson.category.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(getCategoryColor(lesson.category).opacity(0.1))
                        .foregroundColor(getCategoryColor(lesson.category))
                        .clipShape(Capsule())
                    
                    // Title
                    Text(lesson.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Description
                    Text(lesson.lessonDescription)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
                
                Divider()
                
                // Content section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Lesson Content")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(lesson.content)
                        .padding(.vertical, 5)
                }
                
                Divider()
                
                // Exercises
                VStack(alignment: .leading, spacing: 15) {
                    Text("Exercises")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if !lesson.exercises.isEmpty {
                        ForEach(lesson.exercises) { exercise in
                            exerciseCardView(for: exercise)
                        }
                    } else {
                        Text("No exercises available for this lesson.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                // Mark as complete button
                Button(action: {
                    withAnimation {
                        lesson.completed.toggle()
                        try? modelContext.save()
                    }
                }) {
                    HStack {
                        Text(lesson.completed ? "Mark as Incomplete" : "Mark as Complete")
                        
                        Image(systemName: lesson.completed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(lesson.completed ? Color.gray.opacity(0.2) : Color.green)
                    .foregroundColor(lesson.completed ? .primary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    private func exerciseCardView(for exercise: Exercise) -> some View {
        NavigationLink(destination: ExerciseView(exercise: exercise)) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(exercise.type.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            if exercise.completed {
                                HStack {
                                    if let score = exercise.score {
                                        Text("\(score)%")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                .foregroundColor(.green)
                            }
                        }
                        
                        Text(exercise.title)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(exercise.instructions)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: getExerciseIcon(exercise.type))
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
    }
    
    private func getExerciseIcon(_ type: ExerciseType) -> String {
        switch type {
        case .multipleChoice:
            return "list.bullet.circle"
        case .fillInBlank:
            return "character.cursor.ibeam"
        case .matchingPairs:
            return "arrow.left.and.right"
        case .speaking:
            return "mic"
        case .listening:
            return "ear"
        case .translation:
            return "arrow.triangle.2.circlepath"
        case .scrambledWords:
            return "shuffle"
        case .writeAnswer:
            return "pencil"
        }
    }
    
    private func getCategoryColor(_ category: LessonCategory) -> Color {
        switch category {
        case .vocabulary:
            return .blue
        case .grammar:
            return .green
        case .pronunciation:
            return .purple
        case .reading:
            return .orange
        case .writing:
            return .red
        case .conversation:
            return .indigo
        case .idioms:
            return .yellow
        case .slang:
            return .pink
        }
    }
}

// MARK: - Exercise View Placeholder
struct ExerciseView: View {
    let exercise: Exercise
    
    var body: some View {
        Text("Exercise: \(exercise.title)")
            .navigationTitle(exercise.title)
    }
}

#Preview {
    let schema = Schema([
        Lesson.self,
        Exercise.self,
        Word.self,
        UserProgress.self,
        UserProfile.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return LessonsView()
        .modelContainer(container)
}
