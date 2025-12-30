//
//  ListeningExerciseView.swift
//  Fluentry
//
//  Real listening comprehension using iOS Text-to-Speech
//

import SwiftUI
import AVFoundation

struct ListeningExerciseView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var showResults = false
    @State private var hasPlayedAudio = false
    @State private var questions: [(sentence: String, question: String, options: [String], correctAnswer: Int)] = []
    
    private var sampleQuestions: [(sentence: String, question: String, options: [String], correctAnswer: Int)] {
        [
            (
                sentence: "The ephemeral beauty of cherry blossoms reminds us to appreciate fleeting moments.",
                question: "What does 'ephemeral' mean in this sentence?",
                options: ["Lasting forever", "Very short-lived", "Extremely beautiful", "Highly valuable"],
                correctAnswer: 1
            ),
            (
                sentence: "Her serendipitous discovery of the antique book led to a new career.",
                question: "What is 'serendipitous' describing?",
                options: ["A planned event", "A lucky accident", "A difficult task", "An expensive item"],
                correctAnswer: 1
            ),
            (
                sentence: "Smartphones have become ubiquitous in modern society.",
                question: "What does 'ubiquitous' mean?",
                options: ["Very expensive", "Found everywhere", "Technologically advanced", "Recently invented"],
                correctAnswer: 1
            )
        ]
    }
    
    private func generateQuestionsFromWords() -> [(sentence: String, question: String, options: [String], correctAnswer: Int)] {
        var generated: [(String, String, [String], Int)] = []
        let shuffled = words.shuffled()
        let count = min(5, shuffled.count)
        
        for i in 0..<count {
            let word = shuffled[i]
            let sentence = word.example.isEmpty ? "The word '\(word.term)' is commonly used in English." : word.example
            let question = "What does '\(word.term)' mean?"
            
            var options = [word.definition]
            let otherWords = shuffled.filter { $0.term != word.term }.shuffled()
            for j in 0..<min(3, otherWords.count) {
                options.append(otherWords[j].definition)
            }
            
            options.shuffle()
            let correctIndex = options.firstIndex(of: word.definition) ?? 0
            
            generated.append((sentence, question, options, correctIndex))
        }
        
        return generated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.yellow.opacity(0.1)]),
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
            .navigationTitle("Listening Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        speechSynthesizer.stop()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if questions.isEmpty {
                    if !words.isEmpty && words.count >= 3 {
                        questions = generateQuestionsFromWords()
                    } else {
                        questions = sampleQuestions
                    }
                }
            }
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 30) {
            // Progress
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.orange)
                .padding(.horizontal)
            
            Text("Question \(currentQuestion + 1) of \(questions.count)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Audio playback card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .orange.opacity(0.2), radius: 15, x: 0, y: 8)
                
                VStack(spacing: 25) {
                    // Animated speaker icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.2), .yellow.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 10)
                        
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: speechSynthesizer.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.variableColor, isActive: speechSynthesizer.isSpeaking)
                    }
                    
                    Text("Listen carefully")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // Play button
                    Button(action: playAudio) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text(hasPlayedAudio ? "Play Again" : "Play Audio")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(speechSynthesizer.isSpeaking)
                }
                .padding(30)
            }
            .padding(.horizontal)
            
            // Question after audio is played
            if hasPlayedAudio {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.1))
                        
                        Text(questions[currentQuestion].question)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
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
                }
            }
            
            Spacer()
            
            // Next button
            if selectedAnswer != nil {
                Button(action: nextQuestion) {
                    HStack {
                        Text(currentQuestion < questions.count - 1 ? "Next Question" : "See Results")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func answerButton(option: String, index: Int) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedAnswer = index
        }) {
            ZStack {
                if selectedAnswer == index {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.7), .yellow.opacity(0.7)],
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
            Spacer()
            
            // Score circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.7), .yellow.opacity(0.7)],
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
            
            Text(getPerformanceMessage())
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Excellent listening comprehension!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 15) {
                Button(action: resetExercise) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    onCompletion?()
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
    
    // MARK: - Functions
    
    private func playAudio() {
        let sentence = questions[currentQuestion].sentence
        speechSynthesizer.speak(sentence)
        hasPlayedAudio = true
        HapticFeedback.light()
    }
    
    private func nextQuestion() {
        if let selected = selectedAnswer {
            if selected == questions[currentQuestion].correctAnswer {
                score += 1
                HapticFeedback.success()
            } else {
                HapticFeedback.error()
            }
            
            selectedAnswer = nil
            hasPlayedAudio = false
            
            if currentQuestion + 1 < questions.count {
                currentQuestion += 1
            } else {
                showResults = true
                onCompletion?()
            }
        }
    }
    
    private func resetExercise() {
        currentQuestion = 0
        score = 0
        selectedAnswer = nil
        hasPlayedAudio = false
        showResults = false
    }
    
    private func getPerformanceMessage() -> String {
        let percentage = (Double(score) / Double(questions.count)) * 100
        
        if percentage >= 90 {
            return "Outstanding listening skills!"
        } else if percentage >= 70 {
            return "Great job comprehending!"
        } else if percentage >= 50 {
            return "Good effort! Keep listening!"
        } else {
            return "Keep practicing your listening!"
        }
    }
}

// MARK: - Speech Synthesizer
@MainActor
class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private let openAI = OpenAIService.shared
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, rate: Float = 0.5) {
        // Try OpenAI TTS first
        if openAI.isConfigured {
            isSpeaking = true
            Task {
                do {
                    let audioData = try await openAI.textToSpeech(text: text, voice: "nova")
                    
                    // Save to temp file and play
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mp3")
                    
                    try audioData.write(to: tempURL)
                    
                    await MainActor.run {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
                            audioPlayer?.delegate = self
                            audioPlayer?.play()
                            print("✅ Playing OpenAI TTS for listening")
                        } catch {
                            print("⚠️ Audio playback failed, using iOS TTS")
                            speakWithiOS(text, rate: rate)
                        }
                    }
                } catch {
                    print("⚠️ OpenAI TTS failed: \(error), using iOS TTS")
                    await MainActor.run {
                        speakWithiOS(text, rate: rate)
                    }
                }
            }
        } else {
            speakWithiOS(text, rate: rate)
        }
    }
    
    private func speakWithiOS(_ text: String, rate: Float) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Find the best premium voice (Siri-quality)
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Priority order: Premium > Enhanced > Default
        let premiumVoice = allVoices.first { voice in
            voice.language == "en-US" && 
            voice.quality == .premium
        }
        
        let enhancedVoice = allVoices.first { voice in
            voice.language == "en-US" && 
            voice.quality == .enhanced
        }
        
        // Use best available voice (Siri-quality)
        utterance.voice = premiumVoice ?? enhancedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        
        // Natural speech settings
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        isSpeaking = false
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

#Preview {
    ListeningExerciseView(words: [])
}
