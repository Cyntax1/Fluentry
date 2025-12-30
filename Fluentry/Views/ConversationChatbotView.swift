//
//  ConversationChatbotView.swift
//  Fluentry
//
//  AI-powered conversational chatbot for practicing English
//

import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ConversationChatbotView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAI = OpenAIService.shared
    @Query private var profiles: [UserProfile]
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var selectedTopic = "General Conversation"
    @State private var showTopicPicker = false
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    let topics = [
        "General Conversation",
        "Travel & Tourism",
        "Business English",
        "Daily Life",
        "Food & Cooking",
        "Technology",
        "Health & Fitness",
        "Entertainment & Movies",
        "Sports",
        "Education",
        "Culture & Traditions",
        "Environment",
        "News & Current Events"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Topic selector
                topicSelector
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                typingIndicator
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                inputArea
            }
            .navigationTitle("AI Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: clearChat) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        Button(action: { showTopicPicker = true }) {
                            Label("Change Topic", systemImage: "tag")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showTopicPicker) {
                topicPickerSheet
            }
            .onAppear {
                if messages.isEmpty {
                    startConversation()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Topic Selector
    private var topicSelector: some View {
        Button(action: { showTopicPicker = true }) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                
                Text(selectedTopic)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Topic Picker Sheet
    private var topicPickerSheet: some View {
        NavigationStack {
            List(topics, id: \.self) { topic in
                Button(action: {
                    changeTopic(to: topic)
                    showTopicPicker = false
                }) {
                    HStack {
                        Text(topic)
                            .font(.headline)
                        
                        Spacer()
                        
                        if topic == selectedTopic {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Choose Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTopicPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isTyping ? 1 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isTyping
                        )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
            
            Button(action: {
                if inputText.isEmpty {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } else {
                    sendMessage()
                }
            }) {
                Image(systemName: inputText.isEmpty ? (isRecording ? "mic.fill" : "mic.fill") : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? (isRecording ? .red : .blue) : .blue)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)
            }
            .disabled(isTyping && !isRecording)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Functions
    private func startConversation() {
        let greeting = if let profile = userProfile {
            "Hello \(profile.name)! I'm your English conversation partner. I'm here to help you practice your English through natural conversation. What would you like to talk about today?"
        } else {
            "Hello! I'm your English conversation partner. I'm here to help you practice your English through natural conversation. What would you like to talk about today?"
        }
        
        messages.append(ChatMessage(content: greeting, isUser: false, timestamp: Date()))
    }
    
    private func changeTopic(to topic: String) {
        selectedTopic = topic
        messages.append(ChatMessage(
            content: "Great! Let's talk about \(topic.lowercased()). What interests you about this topic?",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = inputText
        messages.append(ChatMessage(content: userMessage, isUser: true, timestamp: Date()))
        inputText = ""
        
        getAIResponse(for: userMessage)
    }
    
    private func getAIResponse(for userMessage: String) {
        guard openAI.isConfigured else {
            // Fallback response without API key
            isTyping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let fallbackResponse = "That's interesting! I'd love to help you practice, but I need an OpenAI API key to have a real conversation. For now, keep practicing by writing sentences and I can help you improve your English skills!"
                messages.append(ChatMessage(content: fallbackResponse, isUser: false, timestamp: Date()))
                isTyping = false
            }
            return
        }
        
        isTyping = true
        
        Task {
            do {
                // Build context for the AI
                let systemPrompt = buildSystemPrompt()
                let conversationHistory = buildConversationHistory()
                
                var aiMessages = [OpenAIRequest.Message(role: "system", content: systemPrompt)]
                aiMessages.append(contentsOf: conversationHistory)
                
                let response = try await openAI.chatCompletion(
                    messages: aiMessages,
                    model: "gpt-4o-mini",
                    temperature: 0.8,
                    maxTokens: 300
                )
                
                await MainActor.run {
                    messages.append(ChatMessage(content: response, isUser: false, timestamp: Date()))
                    isTyping = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = "I'm having trouble connecting right now. Could you try again?"
                    messages.append(ChatMessage(content: errorMessage, isUser: false, timestamp: Date()))
                    isTyping = false
                }
            }
        }
    }
    
    private func buildSystemPrompt() -> String {
        var prompt = """
        You are a friendly and encouraging English conversation partner helping someone practice English.
        
        Topic: \(selectedTopic)
        
        Guidelines:
        - Keep responses conversational and natural (2-3 sentences)
        - Ask follow-up questions to keep the conversation going
        - Gently correct major grammar mistakes in a supportive way
        - Use vocabulary appropriate for the topic
        - Be encouraging and positive
        - Stay on the current topic
        """
        
        if let profile = userProfile {
            prompt += """
            
            
            Student Information:
            - Name: \(profile.name)
            - Native Language: \(profile.nativeLanguage)
            - English Level: \(profile.proficiencyLevel)
            - Learning Goal: \(profile.learningGoal)
            - Interests: \(profile.interests.joined(separator: ", "))
            
            Tailor your responses to their level and interests.
            """
        }
        
        return prompt
    }
    
    private func buildConversationHistory() -> [OpenAIRequest.Message] {
        // Only send last 10 messages to stay within token limits
        let recentMessages = messages.suffix(10)
        
        return recentMessages.map { message in
            OpenAIRequest.Message(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            )
        }
    }
    
    private func clearChat() {
        messages.removeAll()
        startConversation()
    }
    
    // MARK: - Speech Recognition
    private func startRecording() {
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.beginRecording()
                } else {
                    print("Speech recognition not authorized")
                }
            }
        }
    }
    
    private func beginRecording() {
        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.inputText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
        
        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        
        // If we have text, send it
        if !inputText.isEmpty {
            sendMessage()
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.15))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    ConversationChatbotView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
