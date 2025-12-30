//
//  SpeakingExerciseView.swift
//  Fluentry
//
//  Real speech recognition exercise using iOS Speech framework
//

import SwiftUI
import Speech
import AVFoundation

struct SpeakingExerciseView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var openAI = OpenAIService.shared
    @StateObject private var audioPlayer = MurfAudioPlayer()
    
    @State private var currentWordIndex = 0
    @State private var userTranscript = ""
    @State private var score = 0
    @State private var showResults = false
    @State private var isRecording = false
    @State private var feedback = ""
    @State private var aiSuggestions = ""
    @State private var pronunciationScore: Double = 0.0
    @State private var showPermissionAlert = false
    @State private var isLoadingAudio = false
    @State private var isAnalyzing = false
    @State private var targetWords: [Word] = []
    
    // Keep synthesizer alive
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private let allSampleWords: [Word] = [
        Word(term: "Beautiful", definition: "Pleasing the senses or mind aesthetically", example: "The sunset was beautiful.", pronunciation: "/ˈbjuː.tɪ.fəl/", difficulty: .easy, category: "Common"),
        Word(term: "Important", definition: "Of great significance or value", example: "This is an important meeting.", pronunciation: "/ɪmˈpɔː.tənt/", difficulty: .easy, category: "Common"),
        Word(term: "Different", definition: "Not the same as another", example: "They have different opinions.", pronunciation: "/ˈdɪf.ər.ənt/", difficulty: .easy, category: "Common"),
        Word(term: "Incredible", definition: "Impossible to believe; extraordinary", example: "The view was incredible.", pronunciation: "/ɪnˈkred.ə.bəl/", difficulty: .medium, category: "Common"),
        Word(term: "Understanding", definition: "The ability to comprehend something", example: "She has a good understanding of math.", pronunciation: "/ˌʌn.dəˈstæn.dɪŋ/", difficulty: .medium, category: "Common"),
        Word(term: "Serendipity", definition: "Finding something good without looking for it", example: "Meeting my best friend was pure serendipity.", pronunciation: "/ˌser.ənˈdɪp.ə.ti/", difficulty: .hard, category: "Advanced"),
        Word(term: "Ubiquitous", definition: "Present everywhere", example: "Smartphones are ubiquitous in modern society.", pronunciation: "/juːˈbɪk.wɪ.təs/", difficulty: .hard, category: "Advanced"),
        Word(term: "Ephemeral", definition: "Lasting for a very short time", example: "The beauty of cherry blossoms is ephemeral.", pronunciation: "/ɪˈfem.ər.əl/", difficulty: .hard, category: "Advanced"),
        Word(term: "Magnificent", definition: "Extremely beautiful or impressive", example: "The palace was magnificent.", pronunciation: "/mægˈnɪf.ɪ.sənt/", difficulty: .medium, category: "Common"),
        Word(term: "Extraordinary", definition: "Very unusual or remarkable", example: "She has extraordinary talent.", pronunciation: "/ɪkˈstrɔː.dɪn.er.i/", difficulty: .hard, category: "Advanced")
    ]
    
    private var currentWord: Word? {
        guard currentWordIndex < targetWords.count else { return nil }
        return targetWords[currentWordIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.05), Color.orange.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else {
                    speakingView
                }
            }
            .navigationTitle("Speaking Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        speechRecognizer.stopRecording()
                        dismiss()
                    }
                }
            }
            .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to use speaking exercises.")
            }
            .onAppear {
                // Shuffle words once when view appears
                if targetWords.isEmpty {
                    targetWords = Array(allSampleWords.shuffled().prefix(5))
                }
                requestPermissions()
                
                // Configure audio session for playback
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("⚠️ Failed to set up audio session: \(error)")
                }
            }
            .onDisappear {
                // Stop any playing audio
                speechSynthesizer.stopSpeaking(at: .immediate)
                audioPlayer.stop()
            }
        }
    }
    
    private var speakingView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Progress
                ProgressView(value: Double(currentWordIndex + 1), total: Double(targetWords.count))
                    .tint(.red)
                    .padding(.horizontal)
                
                Text("Word \(currentWordIndex + 1) of \(targetWords.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            
            // Word card
            if let word = currentWord {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .red.opacity(0.2), radius: 15, x: 0, y: 8)
                        
                        VStack(spacing: 15) {
                            Text("Say this word:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(word.term)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Display pronunciation - fallback to word if pronunciation is empty or seems wrong
                        Text(word.pronunciation.isEmpty || word.pronunciation.count > 50 
                             ? "Pronunciation: /\(word.term.lowercased())/"
                             : word.pronunciation)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Definition:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(word.definition)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Speak button
                        Button(action: speakWord) {
                            HStack {
                                if isLoadingAudio {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if audioPlayer.isPlaying {
                                    Image(systemName: "speaker.wave.3.fill")
                                        .symbolEffect(.variableColor)
                                } else {
                                    Image(systemName: "speaker.wave.2.fill")
                                }
                                Text(isLoadingAudio ? "Loading..." : audioPlayer.isPlaying ? "Playing..." : "Hear Pronunciation")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .disabled(isLoadingAudio || audioPlayer.isPlaying)
                    }
                    .padding(30)
                }
                .padding(.horizontal)
                
                // Recording button
                recordButton
                
                // Transcript display
                if !userTranscript.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You said:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(userTranscript)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Feedback with AI Analysis
                if !feedback.isEmpty {
                    VStack(spacing: 12) {
                        // Main feedback card
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(pronunciationScore >= 0.7 ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            
                            VStack(spacing: 10) {
                                // Score badge
                                if pronunciationScore > 0 && !isAnalyzing {
                                    HStack {
                                        Text("\(Int(pronunciationScore * 100))%")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(pronunciationScore >= 0.7 ? .green : .orange)
                                        
                                        Spacer()
                                        
                                        Image(systemName: pronunciationScore >= 0.9 ? "star.fill" : pronunciationScore >= 0.7 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(pronunciationScore >= 0.7 ? .green : .orange)
                                    }
                                }
                                
                                // Feedback text
                                Text(feedback)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // AI Suggestions
                                if !aiSuggestions.isEmpty && !isAnalyzing {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            Text("AI Coach Says:")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text(aiSuggestions)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                    }
                }
                }
            }
                
                // Next button inside ScrollView
                if !feedback.isEmpty {
                    Button(action: nextWord) {
                        HStack {
                            Text(currentWordIndex < targetWords.count - 1 ? "Next Word" : "See Results")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
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
    }
    
    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(
                        isRecording
                        ? LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.red.opacity(0.7), .orange.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .red.opacity(0.3), radius: isRecording ? 20 : 10, x: 0, y: 5)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                
                VStack(spacing: 8) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text(isRecording ? "Stop" : "Record")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
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
                            colors: [.red.opacity(0.7), .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                VStack {
                    Text("\(score)/\(targetWords.count)")
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
            
            Text("Great pronunciation practice!")
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
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
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
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func speakWord() {
        guard let word = currentWord else { return }
        
        // Try OpenAI TTS first (natural voice)
        if openAI.isConfigured {
            isLoadingAudio = true
            HapticFeedback.light()
            
            Task {
                do {
                    let audioData = try await openAI.textToSpeech(text: word.term, voice: "nova")
                    
                    // Save to temp file and play
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("mp3")
                    
                    try audioData.write(to: tempURL)
                    
                    await MainActor.run {
                        isLoadingAudio = false
                        audioPlayer.play(url: tempURL)
                        print("✅ Playing OpenAI TTS voice")
                    }
                } catch {
                    print("⚠️ OpenAI TTS failed: \(error), using iOS TTS fallback")
                    await MainActor.run {
                        isLoadingAudio = false
                        speakWithiOSVoice(word.term)
                    }
                }
            }
        } else {
            // No OpenAI API key - use iOS voices
            print("ℹ️ Using iOS TTS (OpenAI not configured)")
            speakWithiOSVoice(word.term)
        }
    }
    
    private func speakWithiOSVoice(_ text: String) {
        // Stop any current speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
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
        
        // Use best available voice
        utterance.voice = premiumVoice ?? enhancedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        
        // Natural speech settings - slower for pronunciation learning
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7 // Slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1
        
        // Use persistent synthesizer
        speechSynthesizer.speak(utterance)
        
        print("🔊 Speaking: \(text)")
        HapticFeedback.light()
    }
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
            checkPronunciation()
        } else {
            userTranscript = ""
            feedback = ""
            speechRecognizer.startRecording { transcript in
                userTranscript = transcript
            }
            isRecording = true
            HapticFeedback.medium()
        }
    }
    
    private func checkPronunciation() {
        guard let word = currentWord else { return }
        
        // Use OpenAI for intelligent accent analysis
        if openAI.isConfigured && !userTranscript.isEmpty {
            isAnalyzing = true
            feedback = "🤔 Analyzing your accent..."
            
            Task {
                do {
                    let analysis = try await openAI.analyzeAccent(
                        targetWord: word.term,
                        spokenTranscript: userTranscript,
                        pronunciation: word.pronunciation
                    )
                    
                    await MainActor.run {
                        isAnalyzing = false
                        pronunciationScore = analysis.score
                        feedback = analysis.feedback
                        aiSuggestions = analysis.suggestions
                        
                        // Update score
                        if analysis.score >= 0.7 {
                            score += 1
                            HapticFeedback.success()
                        } else if analysis.score >= 0.4 {
                            HapticFeedback.warning()
                        } else {
                            HapticFeedback.error()
                        }
                        
                        print("🎯 AI Accent Score: \(Int(analysis.score * 100))%")
                        print("💬 Feedback: \(analysis.feedback)")
                        print("💡 Suggestions: \(analysis.suggestions)")
                    }
                } catch {
                    print("⚠️ AI analysis failed: \(error)")
                    await MainActor.run {
                        isAnalyzing = false
                        // Fallback to basic checking
                        checkPronunciationBasic()
                    }
                }
            }
        } else {
            // Fallback to basic checking
            checkPronunciationBasic()
        }
    }
    
    private func checkPronunciationBasic() {
        guard let word = currentWord else { return }
        let targetWord = word.term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let transcript = userTranscript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic pronunciation checking
        let score = calculatePronunciationAccuracy(target: targetWord, spoken: transcript)
        pronunciationScore = score
        
        if score >= 0.9 {
            feedback = "✓ Perfect pronunciation! 🌟"
            aiSuggestions = "Excellent! Your pronunciation is spot on."
            self.score += 1
            HapticFeedback.success()
        } else if score >= 0.7 {
            feedback = "✓ Good! Close enough! 👍"
            aiSuggestions = "Nice work! Minor improvements possible."
            self.score += 1
            HapticFeedback.success()
        } else if score >= 0.4 {
            feedback = "⚠️ Almost! Try saying it more clearly"
            aiSuggestions = "Practice the syllables: \(word.term)"
            HapticFeedback.warning()
        } else {
            feedback = "❌ Try again! Say: \(word.term)"
            aiSuggestions = "Listen to the pronunciation and try again."
            HapticFeedback.error()
        }
    }
    
    // Calculate pronunciation accuracy using multiple methods
    private func calculatePronunciationAccuracy(target: String, spoken: String) -> Double {
        // Method 1: Exact word match
        if spoken.contains(target) {
            return 1.0
        }
        
        // Method 2: Fuzzy string matching (Levenshtein distance)
        let similarity = stringSimilarity(target, spoken)
        
        // Method 3: Phonetic similarity (check if sounds similar)
        let phoneticMatch = phoneticSimilarity(target, spoken)
        
        // Combine scores (weighted average)
        return (similarity * 0.6) + (phoneticMatch * 0.4)
    }
    
    // Calculate string similarity (0.0 to 1.0)
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        return maxLength > 0 ? 1.0 - (Double(distance) / Double(maxLength)) : 1.0
    }
    
    // Levenshtein distance (edit distance between two strings)
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)
        
        for i in 0...s1.count {
            matrix[i][0] = i
        }
        for j in 0...s2.count {
            matrix[0][j] = j
        }
        
        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return matrix[s1.count][s2.count]
    }
    
    // Check phonetic similarity (simplified soundex-like approach)
    private func phoneticSimilarity(_ target: String, _ spoken: String) -> Double {
        // Extract just the word that sounds most like target from spoken text
        let words = spoken.components(separatedBy: .whitespacesAndNewlines)
        
        var bestMatch = 0.0
        for word in words {
            let similarity = stringSimilarity(target, word)
            if similarity > bestMatch {
                bestMatch = similarity
            }
        }
        
        return bestMatch
    }
    
    private func nextWord() {
        if currentWordIndex < targetWords.count - 1 {
            currentWordIndex += 1
            userTranscript = ""
            feedback = ""
            aiSuggestions = ""
            pronunciationScore = 0.0
        } else {
            showResults = true
            onCompletion?()
        }
    }
    
    private func resetExercise() {
        currentWordIndex = 0
        score = 0
        userTranscript = ""
        feedback = ""
        aiSuggestions = ""
        pronunciationScore = 0.0
        showResults = false
    }
    
    private func getPerformanceMessage() -> String {
        let percentage = (Double(score) / Double(targetWords.count)) * 100
        
        if percentage >= 90 {
            return "Outstanding pronunciation!"
        } else if percentage >= 70 {
            return "Great speaking skills!"
        } else if percentage >= 50 {
            return "Good effort! Keep practicing!"
        } else {
            return "Keep practicing your pronunciation!"
        }
    }
}

// MARK: - Speech Recognizer
@MainActor
class SpeechRecognizer: ObservableObject {
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    @Published var isRecording = false
    
    func startRecording(onTranscript: @escaping (String) -> Void) {
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                onTranscript(transcript)
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
    }
}

#Preview {
    SpeakingExerciseView(words: [])
}
