//
//  FlashcardsView.swift
//  Fluentry
//
//  Interactive flashcard system for vocabulary practice
//

import SwiftUI
import SwiftData

struct FlashcardsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var knownWords: Set<PersistentIdentifier> = []
    @State private var learningWords: Set<PersistentIdentifier> = []
    @State private var showingResults = false
    @State private var selectedDifficulty: DifficultyLevel?
    
    private var filteredWords: [Word] {
        if let difficulty = selectedDifficulty {
            return words.filter { $0.difficulty == difficulty }
        }
        return words
    }
    
    private var currentWord: Word? {
        guard currentIndex < filteredWords.count else { return nil }
        return filteredWords[currentIndex]
    }
    
    private var progress: Double {
        guard !filteredWords.isEmpty else { return 0 }
        return Double(currentIndex) / Double(filteredWords.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if !showingResults {
                        // Progress Bar
                        progressBar
                        
                        // Difficulty Filter
                        difficultyFilter
                        
                        // Flashcard
                        if let word = currentWord {
                            flashcardView(word)
                        } else {
                            emptyStateView
                        }
                        
                        // Control Buttons
                        if currentWord != nil {
                            controlButtons
                        }
                        
                        // Instructions
                        instructionsView
                    } else {
                        resultsView
                    }
                }
                .padding()
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: resetSession) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(currentIndex + 1) / \(filteredWords.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Label("\(knownWords.count)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Label("\(learningWords.count)", systemImage: "arrow.clockwise.circle.fill")
                        .foregroundColor(.orange)
                }
                .font(.subheadline)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Difficulty Filter
    private var difficultyFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterPill(nil, label: "All")
                
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    filterPill(level, label: level.rawValue.capitalized)
                }
            }
        }
    }
    
    private func filterPill(_ difficulty: DifficultyLevel?, label: String) -> some View {
        Button(action: {
            withAnimation {
                selectedDifficulty = difficulty
                resetSession()
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(selectedDifficulty == difficulty ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedDifficulty == difficulty
                    ? Color.purple
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Flashcard View
    private func flashcardView(_ word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
            
            VStack(spacing: 30) {
                if !isFlipped {
                    // Front: Term
                    VStack(spacing: 20) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text(word.term)
                            .font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(word.pronunciation)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Tap to reveal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                } else {
                    // Back: Definition, Example, and Synonyms
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.purple)
                            Text("Definition")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text(word.definition)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(.blue)
                            Text("Example")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text("\"\(word.example)\"")
                            .font(.body)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Show synonyms if available
                        if !word.synonyms.isEmpty {
                            Divider()
                            
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.orange)
                                Text("Synonyms")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(word.synonyms.prefix(4), id: \.self) { synonym in
                                        Text(synonym)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("Tap to flip back")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .scaleEffect(x: -1, y: 1) // Flip text back to readable
                }
            }
            .padding(40)
        }
        .frame(height: 450)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 30)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    handleSwipe(gesture.translation)
                }
        )
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 30) {
            // Learning Button
            Button(action: { markAsLearning() }) {
                VStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Still Learning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Flip Button
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isFlipped.toggle()
                }
            }) {
                VStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Flip Card")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Known Button
            Button(action: { markAsKnown() }) {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("I Know This")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Instructions
    private var instructionsView: some View {
        HStack(spacing: 20) {
            instructionItem(icon: "hand.tap", text: "Tap to flip")
            instructionItem(icon: "hand.draw", text: "Swipe left/right")
            instructionItem(icon: "checkmark", text: "Mark known")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func instructionItem(icon: String, text: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Flashcards Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add words to your vocabulary to create flashcards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        VStack(spacing: 30) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow, .orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                resultRow(icon: "checkmark.circle.fill", color: .green, label: "Known", value: "\(knownWords.count)")
                resultRow(icon: "arrow.clockwise.circle.fill", color: .orange, label: "Still Learning", value: "\(learningWords.count)")
                resultRow(icon: "rectangle.stack.fill", color: .purple, label: "Total Cards", value: "\(filteredWords.count)")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button(action: resetSession) {
                Text("Study Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func resultRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(label)
                .font(.headline)
            
            Spacer()
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
    
    // MARK: - Functions
    private func handleSwipe(_ translation: CGSize) {
        if translation.width < -100 {
            // Swipe left - Still Learning
            markAsLearning()
        } else if translation.width > 100 {
            // Swipe right - Known
            markAsKnown()
        } else {
            // Return to center
            withAnimation(.spring()) {
                dragOffset = .zero
            }
        }
    }
    
    private func markAsKnown() {
        guard let word = currentWord else { return }
        
        withAnimation {
            knownWords.insert(word.persistentModelID)
            nextCard()
        }
    }
    
    private func markAsLearning() {
        guard let word = currentWord else { return }
        
        withAnimation {
            learningWords.insert(word.persistentModelID)
            nextCard()
        }
    }
    
    private func nextCard() {
        dragOffset = .zero
        isFlipped = false
        
        if currentIndex < filteredWords.count - 1 {
            currentIndex += 1
        } else {
            showingResults = true
        }
    }
    
    private func resetSession() {
        withAnimation {
            currentIndex = 0
            isFlipped = false
            dragOffset = .zero
            knownWords.removeAll()
            learningWords.removeAll()
            showingResults = false
        }
    }
}

#Preview {
    FlashcardsView()
        .modelContainer(for: Word.self, inMemory: true)
}
