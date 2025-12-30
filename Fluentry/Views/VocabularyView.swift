//
//  VocabularyView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct VocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @State private var searchText = ""
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var showingAddWord = false
    @State private var showingAIGenerator = false
    @State private var showingDictionary = false
    @State private var selectedCategory = "All"
    @State private var searchScope: SearchScope = .all
    @StateObject private var openAI = OpenAIService.shared
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case terms = "Terms"
        case definitions = "Definitions"
    }
    
    // Categories from existing words plus "All"
    private var categories: [String] {
        let wordCategories = Set(words.map { $0.category })
        return ["All"] + wordCategories.sorted()
    }
    
    private var filteredWords: [Word] {
        words.filter { word in
            let difficultyMatch = selectedDifficulty == nil || word.difficulty == selectedDifficulty
            let categoryMatch = selectedCategory == "All" || word.category == selectedCategory
            
            let searchMatch: Bool
            if searchText.isEmpty {
                searchMatch = true
            } else {
                switch searchScope {
                case .all:
                    searchMatch = word.term.localizedCaseInsensitiveContains(searchText) ||
                                word.definition.localizedCaseInsensitiveContains(searchText)
                case .terms:
                    searchMatch = word.term.localizedCaseInsensitiveContains(searchText)
                case .definitions:
                    searchMatch = word.definition.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return difficultyMatch && categoryMatch && searchMatch
        }
    }
    
    // Group words by first letter for alphabetical sectioning
    private var groupedWords: [String: [Word]] {
        Dictionary(grouping: filteredWords) { String($0.term.prefix(1).uppercased()) }
    }
    
    private var sortedKeys: [String] {
        groupedWords.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills (keep this for difficulty/category filtering)
                filterOptionsBar
                    .padding(.top, 8)
                
                // Word list with sections
                if filteredWords.isEmpty {
                    emptyStateView
                } else {
                    wordListView
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
            .sheet(isPresented: $showingAIGenerator) {
                AIVocabularyGeneratorView()
            }
            .sheet(isPresented: $showingDictionary) {
                DictionaryLookupView()
            }
            .navigationTitle("Vocabulary")
            .searchable(text: $searchText, prompt: "Search vocabulary")
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingDictionary = true }) {
                        Label("Dictionary", systemImage: "book.closed.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddWord = true }) {
                            Label("Add Manually", systemImage: "plus")
                        }
                        Button(action: { showingAIGenerator = true }) {
                            Label("AI Generate", systemImage: "sparkles")
                        }
                        Button(action: { showingDictionary = true }) {
                            Label("Dictionary Lookup", systemImage: "book.closed")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
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
    
    // MARK: - Search Bar
    private var searchFilterBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search words", text: $searchText)
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
    
    // MARK: - Filter Options
    private var filterOptionsBar: some View {
        VStack(spacing: 10) {
            // Difficulty Level
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    difficultyFilterPill(nil, label: "All Levels")
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        difficultyFilterPill(level, label: level.rawValue.capitalized)
                    }
                }
                .padding(.horizontal)
            }
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        categoryFilterPill(category)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
        }
    }
    
    private func difficultyFilterPill(_ difficulty: DifficultyLevel?, label: String) -> some View {
        Button(action: {
            withAnimation {
                selectedDifficulty = difficulty
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(selectedDifficulty == difficulty ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedDifficulty == difficulty
                    ? difficultyColor(difficulty)
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    private func categoryFilterPill(_ category: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
            }
        }) {
            Text(category)
                .font(.caption)
                .fontWeight(selectedCategory == category ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    selectedCategory == category
                    ? Color.indigo
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Word List View
    private var wordListView: some View {
        List {
            ForEach(sortedKeys, id: \.self) { key in
                Section(header: Text(key).textCase(.uppercase).font(.caption).foregroundColor(.secondary)) {
                    ForEach(groupedWords[key] ?? []) { word in
                        NavigationLink(destination: WordDetailView(word: word)) {
                            wordRowView(word)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticFeedback.heavy()
                                deleteWord(word)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                HapticFeedback.success()
                                markAsLearned(word)
                            } label: {
                                Label("Learned", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                HapticFeedback.light()
                                toggleFavorite(word)
                            } label: {
                                Label("Favorite", systemImage: word.isFavorited ? "heart.fill" : "heart")
                            }
                            .tint(.pink)
                        }
                        .contextMenu {
                            Button {
                                markAsLearned(word)
                            } label: {
                                Label("Mark as Learned", systemImage: "checkmark.circle")
                            }
                            
                            Button {
                                toggleFavorite(word)
                            } label: {
                                Label(word.isFavorited ? "Unfavorite" : "Favorite", 
                                     systemImage: word.isFavorited ? "heart.slash" : "heart")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteWord(word)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func wordRowView(_ word: Word) -> some View {
        HStack(spacing: 12) {
            // Icon with liquid glass effect
            ZStack {
                Circle()
                    .fill(difficultyColor(word.difficulty).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8)
                
                Image(systemName: "character.book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [difficultyColor(word.difficulty), difficultyColor(word.difficulty).opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: word.proficiencyLevel)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.term)
                        .font(.body) // 17pt - iOS standard
                        .fontWeight(.semibold)
                    
                    if word.isFavorited {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                            .symbolEffect(.pulse)
                    }
                }
                
                if !word.pronunciation.isEmpty {
                    Text(word.pronunciation)
                        .font(.caption) // 12pt - iOS standard
                        .foregroundColor(.secondary)
                }
                
                Text(word.definition)
                    .font(.subheadline) // 15pt - iOS standard
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Proficiency indicator with SF Symbol animation
            VStack(spacing: 4) {
                if word.proficiencyLevel >= 3 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce)
                } else {
                    ZStack {
                        Circle()
                            .stroke(difficultyColor(word.difficulty).opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        Text(String(word.proficiencyLevel))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(difficultyColor(word.difficulty))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Words Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your filters or add new words to your vocabulary.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button(action: { showingAddWord = true }) {
                Label("Add New Word", systemImage: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(.top, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    private func deleteWord(_ word: Word) {
        withAnimation {
            modelContext.delete(word)
            try? modelContext.save()
        }
    }
    
    private func markAsLearned(_ word: Word) {
        withAnimation {
            word.proficiencyLevel = 5
            try? modelContext.save()
        }
    }
    
    private func toggleFavorite(_ word: Word) {
        withAnimation {
            word.isFavorited.toggle()
            try? modelContext.save()
        }
    }
    
    private func difficultyColor(_ difficulty: DifficultyLevel?) -> Color {
        guard let difficulty = difficulty else { return .blue }
        
        switch difficulty {
        case .beginner:
            return .green
        case .easy:
            return .blue
        case .medium:
            return .orange
        case .hard:
            return .red
        case .advanced:
            return .purple
        }
    }
    
    // MARK: - Speech Functions (OpenAI TTS)
    private func speakWord(_ text: String) {
        guard openAI.isConfigured else {
            // Fallback to system TTS if no API key
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.4
            synthesizer.speak(utterance)
            return
        }
        
        Task {
            do {
                isPlayingAudio = true
                
                // Get audio from OpenAI TTS
                let audioData = try await openAI.textToSpeech(text: text, voice: "nova")
                
                // Play audio
                await MainActor.run {
                    do {
                        audioPlayer = try AVAudioPlayer(data: audioData)
                        audioPlayer?.play()
                        isPlayingAudio = false
                    } catch {
                        print("Audio playback error: \(error)")
                        isPlayingAudio = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("TTS error: \(error)")
                    isPlayingAudio = false
                    
                    // Fallback to system TTS
                    let synthesizer = AVSpeechSynthesizer()
                    let utterance = AVSpeechUtterance(string: text)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    utterance.rate = 0.4
                    synthesizer.speak(utterance)
                }
            }
        }
    }
}

// MARK: - Word Detail View
struct WordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var word: Word
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @StateObject private var openAI = OpenAIService.shared
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    @State private var showPronunciationPractice = false
    @State private var showSentenceBuilder = false
    @State private var showFlashcards = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word header
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(word.term)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Text(word.pronunciation)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        speakWord(word.term)
                                    }) {
                                        Image(systemName: "speaker.wave.2.circle")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Difficulty and proficiency badge
                            ZStack {
                                Circle()
                                    .fill(getDifficultyColor(word.difficulty).opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                VStack(spacing: 2) {
                                    Text("\(word.proficiencyLevel)/5")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Text(word.difficulty.rawValue.capitalized)
                                        .font(.caption)
                                }
                                .foregroundColor(getDifficultyColor(word.difficulty))
                            }
                        }
                        
                        // Category pill
                        HStack {
                            Text(word.category)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                    }
                    .padding()
                }
                
                // Definition
                VStack(alignment: .leading, spacing: 10) {
                    Text("Definition")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(word.definition)
                        .padding(.vertical, 5)
                }
                .padding(.horizontal)
                
                // Example
                VStack(alignment: .leading, spacing: 10) {
                    Text("Example")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.05))
                        
                        Text("\"" + word.example + "\"")
                            .padding()
                            .italic()
                    }
                }
                .padding(.horizontal)
                
                // Synonyms
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Synonyms")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(word.synonyms, id: \.self) { synonym in
                                    Text(synonym)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Practice buttons
                VStack(spacing: 12) {
                    practiceButton(
                        label: "Practice Pronunciation",
                        icon: "waveform.and.mic",
                        color: .purple,
                        action: { showPronunciationPractice = true }
                    )
                    
                    practiceButton(
                        label: "Create a Sentence",
                        icon: "text.quote",
                        color: .blue,
                        action: { showSentenceBuilder = true }
                    )
                    
                    practiceButton(
                        label: "Add to Flashcards",
                        icon: "rectangle.stack",
                        color: .orange,
                        action: { 
                            word.inFlashcardDeck.toggle()
                            HapticFeedback.success()
                        }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit Word", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Word", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditWordView(word: word)
        }
        .confirmationDialog(
            "Are you sure you want to delete this word?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWord()
            }
        }
        .sheet(isPresented: $showPronunciationPractice) {
            SpeakingExerciseView(words: [word])
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
    }
    
    private func practiceButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(label)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func deleteWord() {
        modelContext.delete(word)
    }
    
    private func getDifficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner:
            return .green
        case .easy:
            return .blue
        case .medium:
            return .orange
        case .hard:
            return .red
        case .advanced:
            return .purple
        }
    }
    
    // MARK: - Speech Functions (OpenAI TTS)
    private func speakWord(_ text: String) {
        guard openAI.isConfigured else {
            // Fallback to system TTS if no API key
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.4
            synthesizer.speak(utterance)
            return
        }
        
        Task {
            do {
                isPlayingAudio = true
                
                // Get audio from OpenAI TTS
                let audioData = try await openAI.textToSpeech(text: text, voice: "nova")
                
                // Play audio
                await MainActor.run {
                    do {
                        audioPlayer = try AVAudioPlayer(data: audioData)
                        audioPlayer?.play()
                        isPlayingAudio = false
                    } catch {
                        print("Audio playback error: \(error)")
                        isPlayingAudio = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("TTS error: \(error)")
                    isPlayingAudio = false
                    
                    // Fallback to system TTS
                    let synthesizer = AVSpeechSynthesizer()
                    let utterance = AVSpeechUtterance(string: text)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    utterance.rate = 0.4
                    synthesizer.speak(utterance)
                }
            }
        }
    }
}

// MARK: - Add Word View
struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var term = ""
    @State private var definition = ""
    @State private var example = ""
    @State private var pronunciation = ""
    @State private var difficulty: DifficultyLevel = .medium
    @State private var category = "General"
    @State private var synonyms: [String] = []
    @State private var isFetchingFromAPI = false
    @State private var fetchError: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Word Information")) {
                    HStack {
                        TextField("Term", text: $term)
                        
                        if !term.isEmpty {
                            Button(action: fetchFromDictionary) {
                                if isFetchingFromAPI {
                                    ProgressView()
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isFetchingFromAPI)
                        }
                    }
                    
                    TextField("Pronunciation", text: $pronunciation)
                    TextField("Category", text: $category)
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }
                
                Section(header: Text("Definition & Example")) {
                    TextField("Definition", text: $definition, axis: .vertical)
                        .lineLimit(3...5)
                    
                    TextField("Example", text: $example, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                if !synonyms.isEmpty {
                    Section(header: Text("Synonyms")) {
                        ForEach(synonyms, id: \.self) { synonym in
                            Text(synonym)
                        }
                    }
                }
                
                if let error = fetchError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: fetchRandomWord) {
                        HStack {
                            Image(systemName: "shuffle")
                            Text("Get Random Word")
                            Spacer()
                        }
                    }
                    .disabled(isFetchingFromAPI)
                }
            }
            .navigationTitle("Add New Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addWord()
                    }
                    .disabled(term.isEmpty || definition.isEmpty)
                }
            }
        }
    }
    
    private func fetchFromDictionary() {
        guard !term.isEmpty else { return }
        
        isFetchingFromAPI = true
        fetchError = nil
        
        Task {
            do {
                let dictWord = try await FreeDictionaryService.shared.fetchWord(term)
                
                await MainActor.run {
                    definition = FreeDictionaryService.shared.getPrimaryDefinition(from: dictWord)
                    example = FreeDictionaryService.shared.getExampleSentence(from: dictWord)
                    pronunciation = FreeDictionaryService.shared.getPronunciation(from: dictWord)
                    synonyms = FreeDictionaryService.shared.getAllSynonyms(from: dictWord)
                    isFetchingFromAPI = false
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    isFetchingFromAPI = false
                }
            }
        }
    }
    
    private func fetchRandomWord() {
        isFetchingFromAPI = true
        fetchError = nil
        
        Task {
            do {
                let dictWord = try await FreeDictionaryService.shared.fetchRandomWord()
                
                await MainActor.run {
                    term = dictWord.word
                    definition = FreeDictionaryService.shared.getPrimaryDefinition(from: dictWord)
                    example = FreeDictionaryService.shared.getExampleSentence(from: dictWord)
                    pronunciation = FreeDictionaryService.shared.getPronunciation(from: dictWord)
                    synonyms = FreeDictionaryService.shared.getAllSynonyms(from: dictWord)
                    isFetchingFromAPI = false
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    isFetchingFromAPI = false
                }
            }
        }
    }
    
    private func addWord() {
        let newWord = Word(
            term: term,
            definition: definition,
            example: example.isEmpty ? "No example provided." : example,
            pronunciation: pronunciation.isEmpty ? "N/A" : pronunciation,
            difficulty: difficulty,
            category: category.isEmpty ? "General" : category,
            synonyms: synonyms
        )
        
        modelContext.insert(newWord)
        dismiss()
    }
}

// MARK: - Edit Word View
struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var word: Word
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Word Information")) {
                    TextField("Term", text: $word.term)
                    TextField("Pronunciation", text: $word.pronunciation)
                    TextField("Category", text: $word.category)
                    
                    Picker("Difficulty", selection: $word.difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }
                
                Section(header: Text("Definition & Example")) {
                    TextField("Definition", text: $word.definition, axis: .vertical)
                        .lineLimit(3...5)
                    
                    TextField("Example", text: $word.example, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(header: Text("Progress")) {
                    Stepper("Proficiency Level: \(word.proficiencyLevel)/5", 
                            value: $word.proficiencyLevel, 
                            in: 0...5)
                }
            }
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                    .disabled(word.term.isEmpty || word.definition.isEmpty)
                }
            }
        }
    }
}

#Preview {
    VocabularyView()
        .modelContainer(for: Word.self, inMemory: true)
}
