//
//  ContentView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var userProgress: UserProgress?
    @State private var showOnboarding = false
    @State private var showChatbot = false
    
    // For demo purposes, we'll pre-populate with sample data if none exists
    @Query private var lessons: [Lesson]
    @Query private var words: [Word]
    @Query private var progress: [UserProgress]
    @Query private var profiles: [UserProfile]
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    private var needsOnboarding: Bool {
        userProfile == nil || !userProfile!.hasCompletedOnboarding
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                userProgress: userProgress ?? UserProgress(),
                userProfile: userProfile
            )
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(0)
            
            LessonsView()
                .tabItem {
                    Label("Lessons", systemImage: "book")
                }
                .tag(1)
            
            VocabularyView()
                .tabItem {
                    Label("Vocabulary", systemImage: "character.book.closed")
                }
                .tag(2)
                
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "gamecontroller")
                }
                .tag(3)
        }
        .tint(.indigo)
        .onAppear {
            initializeDataIfNeeded()
            userProgress = progress.first
            
            // Update widget data
            if let progress = userProgress {
                progress.updateWidgets()
            }
            
            // Set Word of the Day
            setWordOfTheDayIfNeeded()
            
            if needsOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showChatbot) {
            ConversationChatbotView()
        }
        // Apply the glass-like appearance
        .background(Material.ultraThinMaterial)
    }
    
    private func initializeDataIfNeeded() {
        // Initialize user progress if needed
        if progress.isEmpty {
            let newProgress = UserProgress()
            modelContext.insert(newProgress)
        }
        
        // Check if initial data has already been added
        let hasInitialized = UserDefaults.standard.bool(forKey: "hasInitializedData")
        
        if !hasInitialized {
            // Add sample lessons
            addSampleLessons()
            
            // Add sample vocabulary words for practice
            addSampleVocabulary()
            
            // Add sample exercises for practice
            addSampleExercises()
            
            // Start loading vocabulary in background
            Task {
                await loadVocabularyFromAPI()
            }
            
            // Mark as initialized
            UserDefaults.standard.set(true, forKey: "hasInitializedData")
        }
    }
    
    private func addSampleLessons() {
        let sampleLessons = [
            Lesson(
                title: "Basic Greetings",
                lessonDescription: "Learn common English greetings for everyday situations",
                content: "In this lesson, we'll explore various ways to greet people in English, from formal to casual contexts.",
                category: .conversation,
                difficulty: .beginner
            ),
            Lesson(
                title: "Present Simple Tense",
                lessonDescription: "Master the foundational tense of English",
                content: "The present simple tense is used to describe habits, unchanging situations, general truths, and fixed arrangements.",
                category: .grammar,
                difficulty: .beginner
            ),
            Lesson(
                title: "Mastering Phrasal Verbs",
                lessonDescription: "Understanding and using common phrasal verbs",
                content: "Phrasal verbs are combinations of words that when used together, have a different meaning to the original verb.",
                category: .vocabulary,
                difficulty: .medium
            )
        ]
        
        for lesson in sampleLessons {
            modelContext.insert(lesson)
        }
    }
    
    private func addSampleVocabulary() {
        let sampleWords = [
            Word(
                term: "Serendipity",
                definition: "The occurrence of events by chance in a happy or beneficial way",
                example: "Finding this beautiful park while lost was pure serendipity.",
                pronunciation: "/ˌserənˈdɪpɪti/",
                difficulty: .medium,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["fortune", "luck", "chance"]
            ),
            Word(
                term: "Ubiquitous",
                definition: "Present, appearing, or found everywhere",
                example: "Smartphones have become ubiquitous in modern society.",
                pronunciation: "/juːˈbɪkwɪtəs/",
                difficulty: .medium,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["omnipresent", "pervasive", "universal"]
            ),
            Word(
                term: "Ephemeral",
                definition: "Lasting for a very short time",
                example: "The beauty of cherry blossoms is ephemeral, lasting only a few days.",
                pronunciation: "/ɪˈfemərəl/",
                difficulty: .hard,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["transient", "fleeting", "temporary"]
            ),
            Word(
                term: "Eloquent",
                definition: "Fluent or persuasive in speaking or writing",
                example: "The speaker delivered an eloquent speech that moved the audience.",
                pronunciation: "/ˈeləkwənt/",
                difficulty: .medium,
                category: "Communication",
                proficiencyLevel: 0,
                synonyms: ["articulate", "expressive", "fluent"]
            ),
            Word(
                term: "Pragmatic",
                definition: "Dealing with things sensibly and realistically",
                example: "We need a pragmatic approach to solve this problem.",
                pronunciation: "/præɡˈmætɪk/",
                difficulty: .medium,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["practical", "realistic", "sensible"]
            ),
            Word(
                term: "Resilient",
                definition: "Able to withstand or recover quickly from difficult conditions",
                example: "Children are remarkably resilient and adapt quickly to change.",
                pronunciation: "/rɪˈzɪliənt/",
                difficulty: .easy,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["tough", "strong", "hardy"]
            )
        ]
        
        for word in sampleWords {
            modelContext.insert(word)
        }
        
        try? modelContext.save()
    }
    
    private func addSampleExercises() {
        let exercises = [
            Exercise(
                title: "Vocabulary Quiz: Advanced Words",
                instructions: "Test your knowledge of advanced English vocabulary",
                type: .multipleChoice,
                content: """
                [
                    {
                        "question": "What is the meaning of 'Eloquent'?",
                        "options": ["Speaking or writing clearly and effectively", "Being extremely quiet", "Moving slowly", "Making loud noises"],
                        "correctAnswer": 0
                    },
                    {
                        "question": "Choose the synonym of 'Resilient'",
                        "options": ["Weak", "Tough", "Confused", "Angry"],
                        "correctAnswer": 1
                    },
                    {
                        "question": "What does 'Ephemeral' mean?",
                        "options": ["Lasting forever", "Highly valuable", "Lasting for a very short time", "Causing great damage"],
                        "correctAnswer": 2
                    }
                ]
                """,
                difficulty: .medium
            ),
            Exercise(
                title: "Fill in the Blanks: Context Practice",
                instructions: "Complete the sentences with the correct words",
                type: .fillInBlank,
                content: """
                [
                    {
                        "question": "The beauty of cherry blossoms is ________, lasting only a few days.",
                        "options": ["ephemeral", "permanent", "ubiquitous", "extravagant"],
                        "correctAnswer": 0
                    },
                    {
                        "question": "Smartphones have become ________ in modern society.",
                        "options": ["obsolete", "ubiquitous", "forbidden", "expensive"],
                        "correctAnswer": 1
                    }
                ]
                """,
                difficulty: .medium
            ),
            Exercise(
                title: "Word Matching Challenge",
                instructions: "Match words with their correct definitions",
                type: .matchingPairs,
                content: """
                [
                    {
                        "question": "Match 'Ubiquitous' with its definition:",
                        "options": ["Present everywhere", "Rare and uncommon", "Very expensive", "Difficult to understand"],
                        "correctAnswer": 0
                    },
                    {
                        "question": "Match 'Resilient' with its meaning:",
                        "options": ["Weak", "Able to recover quickly", "Very old", "Complicated"],
                        "correctAnswer": 1
                    }
                ]
                """,
                difficulty: .easy
            )
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        
        try? modelContext.save()
    }
    
    private func loadVocabularyFromAPI() async {
        let wordList = FreeDictionaryService.shared.getComprehensiveWordList()
        var loadedCount = 0
        
        for wordTerm in wordList {
            // Add small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            do {
                let dictWord = try await FreeDictionaryService.shared.fetchWord(wordTerm)
                
                await MainActor.run {
                    let newWord = Word(
                        term: dictWord.word,
                        definition: FreeDictionaryService.shared.getPrimaryDefinition(from: dictWord),
                        example: FreeDictionaryService.shared.getExampleSentence(from: dictWord),
                        pronunciation: FreeDictionaryService.shared.getPronunciation(from: dictWord),
                        difficulty: determineDifficulty(for: dictWord.word),
                        category: "General",
                        synonyms: FreeDictionaryService.shared.getAllSynonyms(from: dictWord)
                    )
                    
                    modelContext.insert(newWord)
                    loadedCount += 1
                    
                    // Save periodically to avoid memory issues
                    if loadedCount % 20 == 0 {
                        try? modelContext.save()
                    }
                }
            } catch {
                // Skip words that fail to load
                continue
            }
        }
        
        // Final save
        await MainActor.run {
            try? modelContext.save()
        }
    }
    
    private func determineDifficulty(for word: String) -> DifficultyLevel {
        let length = word.count
        if length <= 4 {
            return .beginner
        } else if length <= 6 {
            return .easy
        } else if length <= 8 {
            return .medium
        } else if length <= 10 {
            return .hard
        } else {
            return .advanced
        }
    }
    
    private func setWordOfTheDayIfNeeded() {
        let calendar = Calendar.current
        let lastUpdateKey = "lastWordOfTheDayUpdate"
        
        // Check if we've already set a word today
        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            if calendar.isDateInToday(lastUpdate) {
                return // Already set today's word
            }
        }
        
        // Pick a random word from vocabulary
        if !words.isEmpty {
            let randomWord = words.randomElement()!
            WidgetDataManager.shared.setWordOfTheDayFromVocabulary(
                word: randomWord.term,
                definition: randomWord.definition,
                example: randomWord.example,
                pronunciation: randomWord.pronunciation
            )
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
        }
    }
}

#Preview {
    let schema = Schema([
        Word.self,
        Lesson.self,
        Exercise.self,
        UserProgress.self,
        UserProfile.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return ContentView()
        .modelContainer(container)
}
