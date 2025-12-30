//
//  MurfService.swift
//  Fluentry
//
//  Murf AI Text-to-Speech Integration
//  Ultra-realistic human voices for pronunciation
//

import Foundation
import AVFoundation

// MARK: - Murf Models
struct MurfRequest: Codable {
    let voiceId: String
    let text: String
    let rate: String?
    let pitch: String?
    let format: String?
    
    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case text
        case rate
        case pitch
        case format
    }
}

struct MurfResponse: Codable {
    let audioFile: String
    
    enum CodingKeys: String, CodingKey {
        case audioFile = "audio_file"
    }
}

// MARK: - Murf Service
@MainActor
class MurfService: ObservableObject {
    static let shared = MurfService()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://api.murf.ai/v1/speech/generate"
    private var apiKey: String {
        // Read from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let key = config["MURF_API_KEY"] as? String,
           !key.isEmpty && key != "YOUR_MURF_API_KEY_HERE" {
            return key
        }
        return ""
    }
    
    var isConfigured: Bool {
        !apiKey.isEmpty
    }
    
    private init() {}
    
    // MARK: - Generate Speech
    func generateSpeech(
        text: String,
        voiceId: String = "en-US-cooper", // Natural male voice
        completion: @escaping (URL?) -> Void
    ) async {
        guard !apiKey.isEmpty else {
            print("⚠️ Murf API key not configured - falling back to iOS TTS")
            completion(nil)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var request = URLRequest(url: URL(string: baseURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let murfRequest = MurfRequest(
                voiceId: voiceId,
                text: text,
                rate: "0",
                pitch: "0",
                format: "MP3"
            )
            
            request.httpBody = try JSONEncoder().encode(murfRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from Murf API")
                completion(nil)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Murf API Error (\(httpResponse.statusCode)): \(errorString)")
                }
                completion(nil)
                return
            }
            
            let murfResponse = try JSONDecoder().decode(MurfResponse.self, from: data)
            
            // Download the audio file
            guard let audioURL = URL(string: murfResponse.audioFile) else {
                print("❌ Invalid audio URL from Murf")
                completion(nil)
                return
            }
            
            // Download audio to temp file
            let (audioData, _) = try await URLSession.shared.data(from: audioURL)
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp3")
            
            try audioData.write(to: tempURL)
            
            print("✅ Murf audio generated successfully")
            completion(tempURL)
            
        } catch {
            print("❌ Murf error: \(error.localizedDescription)")
            self.error = error
            completion(nil)
        }
    }
    
    // MARK: - Available Voices
    enum MurfVoice: String {
        // US English voices
        case cooper = "en-US-cooper"        // Male, natural, friendly
        case natalie = "en-US-natalie"      // Female, warm, clear
        case terrell = "en-US-terrell"      // Male, professional
        case charlotte = "en-US-charlotte"  // Female, engaging
        case clint = "en-US-clint"          // Male, confident
        case liv = "en-US-liv"              // Female, youthful
        
        var displayName: String {
            switch self {
            case .cooper: return "Cooper (Male, Natural)"
            case .natalie: return "Natalie (Female, Warm)"
            case .terrell: return "Terrell (Male, Professional)"
            case .charlotte: return "Charlotte (Female, Engaging)"
            case .clint: return "Clint (Male, Confident)"
            case .liv: return "Liv (Female, Youthful)"
            }
        }
    }
}

// MARK: - Audio Player Helper
@MainActor
class MurfAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("❌ Failed to play Murf audio: \(error)")
            isPlaying = false
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
