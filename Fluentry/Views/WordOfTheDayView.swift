//
//  WordOfTheDayView.swift
//  Fluentry
//
//  Word of the Day feature with AI generation
//

import SwiftUI
import SwiftData
import AVFoundation

struct WordOfTheDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var openAI = OpenAIService.shared
    
    @State private var currentWord: Word?
    @State private var isGenerating = false
    @State private var showDefinition = false
    @State private var showExample = false
    @State private var isSaved = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerView
                    
                    if let word = currentWord {
                        // Word Card
                        wordCardView(word)
                        
                        // Interactive Sections
                        definitionSection(word)
                        exampleSection(word)
                        usageSection(word)
                        
                        // Actions
                        actionButtons(word)
                    } else {
                        loadingOrEmptyView
                    }
                }
                .padding()
            }
            .navigationTitle("Word of the Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generateNewWord) {
                        Label("New Word", systemImage: "arrow.clockwise")
                    }
                    .disabled(isGenerating)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if currentWord == nil {
                    loadOrGenerateWord()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.yellow.opacity(0.1)]),
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
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Daily Vocabulary")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Expand your English vocabulary daily")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Word Card
    private func wordCardView(_ word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 20) {
                // Word Term
                Text(word.term)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Pronunciation with speaker
                HStack(spacing: 10) {
                    Text(word.pronunciation)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        speakWord(word.term)
                    }) {
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
                
                // Difficulty Badge
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(getDifficultyColor(word.difficulty))
                    
                    Text(word.difficulty.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(getDifficultyColor(word.difficulty).opacity(0.1))
                .foregroundColor(getDifficultyColor(word.difficulty))
                .clipShape(Capsule())
            }
            .padding(30)
        }
    }
    
    // MARK: - Definition Section
    private func definitionSection(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    showDefinition.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.orange)
                    
                    Text("Definition")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image(systemName: showDefinition ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            if showDefinition {
                Text(word.definition)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Example Section
    private func exampleSection(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    showExample.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Example Sentence")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image(systemName: showExample ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            if showExample {
                Text("\"\(word.example)\"")
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Usage Section
    private func usageSection(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                
                Text("Usage Tips")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                tipItem(icon: "1.circle.fill", text: "Use in formal writing and conversation")
                tipItem(icon: "2.circle.fill", text: "Practice using it 3 times today")
                tipItem(icon: "3.circle.fill", text: "Create your own example sentence")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func tipItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.orange)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Buttons
    private func actionButtons(_ word: Word) -> some View {
        VStack(spacing: 12) {
            if !isSaved {
                Button(action: {
                    saveWord(word)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to My Vocabulary")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Saved to Vocabulary")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: {
                shareWord(word)
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Word")
                }
                .font(.headline)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingOrEmptyView: some View {
        VStack(spacing: 20) {
            if isGenerating {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Generating Word of the Day...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Tap refresh to get your word!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Functions
    private func loadOrGenerateWord() {
        // Check if we already generated a word today
        let calendar = Calendar.current
        let _ = calendar.startOfDay(for: Date())
        
        // For demo, just generate a new word
        generateNewWord()
    }
    
    private func generateNewWord() {
        isGenerating = true
        
        Task {
            do {
                let result = try await openAI.generateVocabularyWord(
                    difficulty: [.medium, .hard, .advanced].randomElement()!,
                    category: "General"
                )
                
                let word = Word(
                    term: result.term,
                    definition: result.definition,
                    example: result.example,
                    pronunciation: result.pronunciation,
                    difficulty: [.medium, .hard, .advanced].randomElement()!,
                    category: "Daily Word"
                )
                
                await MainActor.run {
                    currentWord = word
                    isGenerating = false
                    showDefinition = false
                    showExample = false
                    isSaved = false
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
    
    private func saveWord(_ word: Word) {
        modelContext.insert(word)
        try? modelContext.save()
        
        withAnimation {
            isSaved = true
        }
    }
    
    private func speakWord(_ text: String) {
        print("🎤 speakWord called with: \(text)")
        print("🔑 OpenAI configured: \(openAI.isConfigured)")
        
        guard openAI.isConfigured else {
            print("⚠️ No API key - using system TTS")
            // Fallback to system TTS if no API key
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.4
            synthesizer.speak(utterance)
            return
        }
        
        print("🚀 Calling OpenAI TTS API...")
        Task {
            do {
                isPlayingAudio = true
                
                // Get audio from OpenAI TTS
                let audioData = try await openAI.textToSpeech(text: text, voice: "nova")
                print("✅ Got audio data: \(audioData.count) bytes")
                
                // Play audio
                await MainActor.run {
                    do {
                        audioPlayer = try AVAudioPlayer(data: audioData)
                        audioPlayer?.prepareToPlay()
                        let success = audioPlayer?.play() ?? false
                        print("🔊 Audio playing: \(success)")
                        isPlayingAudio = false
                    } catch {
                        print("❌ Audio playback error: \(error)")
                        isPlayingAudio = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ OpenAI TTS error: \(error)")
                    isPlayingAudio = false
                    
                    // Fallback to system TTS
                    print("⚠️ Falling back to system TTS")
                    let synthesizer = AVSpeechSynthesizer()
                    let utterance = AVSpeechUtterance(string: text)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    utterance.rate = 0.4
                    synthesizer.speak(utterance)
                }
            }
        }
    }
    
    private func shareWord(_ word: Word) {
        let text = "\(word.term) - \(word.definition)\n\nExample: \(word.example)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
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
}

#Preview {
    WordOfTheDayView()
        .modelContainer(for: Word.self, inMemory: true)
}
