//
//  DashboardView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct DashboardView: View {
    var userProgress: UserProgress
    var userProfile: UserProfile?
    @Query private var lessons: [Lesson]
    @Query(sort: \Word.lastReviewed) private var recentWords: [Word]
    @State private var showWordOfTheDay = false
    @State private var showFlashcards = false
    @State private var showSentenceBuilder = false
    @State private var showChatbot = false
    @State private var showProfile = false
    @State private var showAllVocabulary = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header with user stats
                    userStatsCard
                    
                    // Word of the Day
                    wordOfTheDaySection
                    
                    // Continue Learning Section
                    continueLearningSectionView
                    
                    // Quick Practice Features
                    quickPracticeSection
                    
                    // Today's Practice Section
                    practiceSessionView
                    
                    // Vocabulary Review
                    vocabularyReviewView
                }
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Text(getInitials())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showWordOfTheDay) {
                WordOfTheDayView()
            }
            .sheet(isPresented: $showFlashcards) {
                FlashcardsView()
            }
            .sheet(isPresented: $showSentenceBuilder) {
                SentenceBuilderView()
            }
            .sheet(isPresented: $showChatbot) {
                ConversationChatbotView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(
                    userProgress: userProgress,
                    userProfile: userProfile
                )
            }
            .sheet(isPresented: $showAllVocabulary) {
                VocabularyView()
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
    
    // MARK: - User Stats Card
    private var userStatsCard: some View {
        VStack(spacing: 0) {
            ZStack {
                // Blurred background
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 20) {
                    // User greeting
                    HStack {
                        VStack(alignment: .leading) {
                            Text(getGreeting())
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Continue your learning journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Text("\(userProgress.streak)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Divider()
                    
                    // Progress stats
                    HStack(spacing: 20) {
                        statItem(
                            value: "\(userProgress.vocabularyMastered)",
                            label: "Words",
                            icon: "character.book.closed",
                            color: .blue
                        )
                        
                        statItem(
                            value: "\(userProgress.lessonsCompleted)",
                            label: "Lessons",
                            icon: "book.closed",
                            color: .purple
                        )
                        
                        statItem(
                            value: "\(userProgress.totalPoints)",
                            label: "Points",
                            icon: "star.fill",
                            color: .yellow
                        )
                    }
                }
                .padding()
            }
            .frame(height: 200)
        }
        .padding(.top)
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Continue Learning Section
    private var continueLearningSectionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Continue Learning")
                .font(.title3)
                .fontWeight(.bold)
            
            if let nextLesson = lessons.first(where: { !$0.completed }) {
                continueCard(for: nextLesson)
            } else {
                Text("No lessons in progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private func continueCard(for lesson: Lesson) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(lesson.category.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            
                            Text("10 min")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Text(lesson.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(lesson.lessonDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
            .padding()
        }
    }
    
    // MARK: - Practice Session View
    private var practiceSessionView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Practice")
                .font(.title3)
                .fontWeight(.bold)
            
            practiceCard()
        }
    }
    
    private func practiceCard() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.indigo.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Challenge")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete a 5-minute practice session")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    
                    HStack(spacing: 15) {
                        practiceButton(label: "Quick Quiz", icon: "questionmark.circle")
                        practiceButton(label: "Listening", icon: "ear")
                    }
                }
                .padding()
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 5)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(.white, lineWidth: 5)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("70%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.trailing)
            }
            .padding()
        }
    }
    
    private func practiceButton(label: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
            
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.2))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
    
    // MARK: - Vocabulary Review
    private var vocabularyReviewView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Vocabulary Review")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showAllVocabulary = true
                }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(recentWords.prefix(5)) { word in
                        vocabularyCard(for: word)
                    }
                    
                    if recentWords.isEmpty {
                        emptyVocabCard()
                    }
                }
            }
        }
    }
    
    private func vocabularyCard(for word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(word.term)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(word.pronunciation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(word.definition)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(height: 60, alignment: .topLeading)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        speakWord(word.term)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        markWordAsMastered(word)
                    }) {
                        Image(systemName: word.mastered ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
        }
        .frame(width: 200, height: 200)
    }
    
    private func emptyVocabCard() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(spacing: 15) {
                Image(systemName: "plus.circle")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Add New Words")
                    .font(.headline)
                
                Text("Build your vocabulary")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(width: 200, height: 200)
    }
    
    // MARK: - Word of the Day Section
    private var wordOfTheDaySection: some View {
        Button(action: { showWordOfTheDay = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.yellow.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title)
                            
                            Text("Word of the Day")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        
                        Text("Discover a new vocabulary word")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.trailing)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Practice Section
    private var quickPracticeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Practice")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    quickPracticeCard(
                        title: "Flashcards",
                        icon: "rectangle.stack.fill",
                        color: .purple,
                        action: { showFlashcards = true }
                    )
                    
                    quickPracticeCard(
                        title: "Sentences",
                        icon: "text.bubble.fill",
                        color: .green,
                        action: { showSentenceBuilder = true }
                    )
                }
                
                // AI Chatbot Card
                Button(action: { showChatbot = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        HStack(spacing: 15) {
                            Image(systemName: "message.badge.waveform.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("AI Conversation")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Practice English with AI chatbot")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func quickPracticeCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 15) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 30)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func speakWord(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        HapticFeedback.light()
    }
    
    private func markWordAsMastered(_ word: Word) {
        word.mastered.toggle()
        HapticFeedback.success()
    }
    
    private func getGreeting() -> String {
        if let name = userProfile?.name, !name.isEmpty {
            return "Hi \(name)!"
        }
        return "Welcome back!"
    }
    
    private func getInitials() -> String {
        if let name = userProfile?.name, !name.isEmpty {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                // First and last name
                let first = String(components.first?.prefix(1) ?? "")
                let last = String(components.last?.prefix(1) ?? "")
                return "\(first)\(last)".uppercased()
            } else {
                // Single name - take first 2 letters
                return String(name.prefix(2)).uppercased()
            }
        }
        return "FL"  // Fluentry Logo
    }
}

#Preview {
    DashboardView(userProgress: UserProgress(), userProfile: nil)
        .modelContainer(for: Word.self, inMemory: true)
        .modelContainer(for: Lesson.self, inMemory: true)
}
