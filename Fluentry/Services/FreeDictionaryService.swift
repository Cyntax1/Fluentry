//
//  FreeDictionaryService.swift
//  Fluentry
//
//  Free Dictionary API integration for fetching word definitions, synonyms, and examples
//

import Foundation

struct DictionaryWord: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]
    
    struct Phonetic: Codable {
        let text: String?
        let audio: String?
    }
    
    struct Meaning: Codable {
        let partOfSpeech: String
        let definitions: [Definition]
        let synonyms: [String]?
        let antonyms: [String]?
        
        struct Definition: Codable {
            let definition: String
            let example: String?
            let synonyms: [String]?
            let antonyms: [String]?
        }
    }
}

class FreeDictionaryService {
    static let shared = FreeDictionaryService()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    private init() {}
    
    /// Fetch word data from Free Dictionary API
    func fetchWord(_ word: String) async throws -> DictionaryWord {
        let urlString = baseURL + word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        
        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw DictionaryError.wordNotFound
        }
        
        // The API returns an array of results, we'll take the first one
        let results = try JSONDecoder().decode([DictionaryWord].self, from: data)
        
        guard let firstResult = results.first else {
            throw DictionaryError.wordNotFound
        }
        
        return firstResult
    }
    
    /// Extract primary definition from dictionary word
    func getPrimaryDefinition(from dictWord: DictionaryWord) -> String {
        dictWord.meanings.first?.definitions.first?.definition ?? "No definition available"
    }
    
    /// Extract example sentence from dictionary word
    func getExampleSentence(from dictWord: DictionaryWord) -> String {
        // Try to find an example from any meaning
        for meaning in dictWord.meanings {
            if let example = meaning.definitions.first(where: { $0.example != nil })?.example {
                return example
            }
        }
        return "No example available"
    }
    
    /// Extract all synonyms from dictionary word
    func getAllSynonyms(from dictWord: DictionaryWord) -> [String] {
        var synonyms = Set<String>()
        
        // Collect synonyms from all meanings
        for meaning in dictWord.meanings {
            if let meaningSynonyms = meaning.synonyms {
                synonyms.formUnion(meaningSynonyms)
            }
            // Also collect from individual definitions
            for definition in meaning.definitions {
                if let defSynonyms = definition.synonyms {
                    synonyms.formUnion(defSynonyms)
                }
            }
        }
        
        return Array(synonyms).sorted()
    }
    
    /// Get pronunciation text
    func getPronunciation(from dictWord: DictionaryWord) -> String {
        // Try phonetic from main level first
        if let phonetic = dictWord.phonetic, !phonetic.isEmpty {
            return phonetic
        }
        
        // Try from phonetics array
        if let phonetics = dictWord.phonetics, let firstPhonetic = phonetics.first?.text {
            return firstPhonetic
        }
        
        return ""
    }
    
    /// Fetch a random word from a predefined list and get its data
    func fetchRandomWord() async throws -> DictionaryWord {
        let randomWords = getComprehensiveWordList()
        
        guard let randomWord = randomWords.randomElement() else {
            throw DictionaryError.wordNotFound
        }
        
        return try await fetchWord(randomWord)
    }
    
    /// Get a comprehensive list of 350+ common English words for vocabulary building
    func getComprehensiveWordList() -> [String] {
        return [
            // Common & Useful Words (A-D)
            "able", "about", "above", "accept", "achieve", "across", "active", "actual", "adapt", "add",
            "admit", "adopt", "advance", "advice", "affect", "afford", "afraid", "after", "again", "against",
            "age", "agency", "agent", "agree", "ahead", "aid", "aim", "allow", "almost", "alone",
            "along", "already", "also", "alter", "always", "amaze", "among", "amount", "analyze", "ancient",
            "anger", "angle", "animal", "annual", "answer", "anxious", "apart", "appeal", "appear", "apply",
            "approach", "area", "argue", "arise", "arrange", "array", "arrive", "article", "artist", "aspect",
            "assess", "assign", "assist", "assume", "assure", "attach", "attack", "attempt", "attend", "attract",
            "author", "avoid", "award", "aware", "balance", "basic", "beauty", "become", "before", "begin",
            "behave", "behind", "belief", "believe", "benefit", "better", "between", "beyond", "border", "both",
            "bottom", "brief", "bright", "bring", "broad", "budget", "build", "burden", "bureau", "business",
            
            // Common & Useful Words (C-F)
            "calm", "camera", "cancel", "capable", "capacity", "capital", "capture", "career", "careful", "carry",
            "cause", "center", "central", "century", "certain", "challenge", "champion", "chance", "change", "chapter",
            "character", "charge", "chart", "chase", "cheap", "check", "chemical", "chief", "child", "choice",
            "choose", "circle", "citizen", "civil", "claim", "class", "classic", "clean", "clear", "client",
            "climate", "climb", "clinic", "close", "clothes", "cloud", "coach", "coast", "code", "cold",
            "collect", "college", "color", "column", "combine", "comfort", "command", "comment", "commit", "common",
            "compare", "compete", "complain", "complete", "complex", "compose", "concept", "concern", "conclude", "concrete",
            "conduct", "confirm", "conflict", "confront", "confuse", "connect", "consider", "consist", "constant", "construct",
            "consult", "consume", "contact", "contain", "content", "contest", "context", "continue", "contract", "contrast",
            "control", "convert", "convince", "cooperate", "coordinate", "correct", "cost", "council", "count", "country",
            "couple", "courage", "course", "court", "cover", "create", "creature", "credit", "crime", "crisis",
            "critic", "critical", "crop", "cross", "crowd", "crucial", "cruel", "cultural", "culture", "curious",
            "current", "custom", "cycle", "damage", "dance", "danger", "dark", "data", "debate", "decade",
            "decide", "declare", "decline", "decorate", "decrease", "deep", "defeat", "defend", "define", "degree",
            "delay", "deliver", "demand", "democracy", "demonstrate", "deny", "depend", "depict", "derive", "describe",
            "desert", "deserve", "design", "desire", "despite", "destroy", "detail", "detect", "determine", "develop",
            "device", "devote", "diagram", "dialogue", "differ", "difficult", "digital", "dilemma", "dimension", "direct",
            "disagree", "disappear", "disaster", "discover", "discuss", "disease", "dismiss", "display", "dispute", "distance",
            "distinct", "distribute", "district", "diverse", "divide", "document", "domestic", "dominate", "doubt", "draft",
            "drama", "dramatic", "draw", "dream", "dress", "drift", "drive", "drop", "during", "duty",
            
            // Common & Useful Words (E-H)
            "eager", "earn", "earth", "ease", "economic", "economy", "edge", "edit", "educate", "effect",
            "effective", "efficient", "effort", "either", "elect", "element", "elevate", "eliminate", "elite", "emerge",
            "emotion", "emphasis", "employ", "empty", "enable", "encounter", "encourage", "enemy", "energy", "enforce",
            "engage", "engine", "enhance", "enjoy", "enormous", "ensure", "enter", "entire", "environment", "equal",
            "equip", "era", "error", "escape", "especially", "essay", "essential", "establish", "estate", "estimate",
            "ethical", "evaluate", "event", "eventually", "evidence", "evil", "evolve", "exact", "examine", "example",
            "exceed", "excellent", "except", "excess", "exchange", "excite", "exclude", "excuse", "execute", "exercise",
            "exhibit", "exist", "expand", "expect", "expense", "experience", "experiment", "expert", "explain", "explode",
            "explore", "export", "expose", "express", "extend", "extent", "external", "extra", "extreme", "face",
            "facility", "factor", "factory", "fail", "fair", "faith", "fall", "false", "familiar", "family",
            "famous", "fancy", "far", "farm", "fashion", "fast", "fate", "father", "fault", "favor",
            "fear", "feature", "federal", "fee", "feed", "feel", "fellow", "female", "fence", "festival",
            "few", "field", "fight", "figure", "file", "fill", "film", "final", "finance", "find",
            "fine", "finger", "finish", "fire", "firm", "first", "fiscal", "fish", "fit", "fix",
            "flag", "flat", "flavor", "flee", "flexible", "flight", "float", "floor", "flow", "flower",
            "focus", "fold", "follow", "food", "foot", "force", "foreign", "forest", "forever", "forget",
            "form", "formal", "format", "former", "formula", "fortune", "forum", "forward", "found", "foundation",
            "frame", "free", "freedom", "freeze", "frequent", "fresh", "friend", "front", "fruit", "frustrate",
            "fuel", "fulfill", "full", "function", "fund", "fundamental", "funny", "furniture", "future", "gain",
            "gallery", "game", "gap", "garage", "garden", "gas", "gate", "gather", "gender", "general",
            "generate", "generous", "genius", "genre", "gentle", "genuine", "gesture", "gift", "girl", "give",
            "glad", "glance", "global", "glory", "goal", "gold", "good", "govern", "grace", "grade",
            "graduate", "grand", "grant", "graph", "grasp", "grateful", "grave", "great", "green", "greet",
            "grief", "ground", "group", "grow", "growth", "guarantee", "guard", "guess", "guest", "guide",
            "guilt", "habit", "habitat", "half", "hall", "hand", "handle", "hang", "happen", "happy",
            "hard", "harm", "harsh", "hate", "have", "hazard", "head", "heal", "health", "hear",
            "heart", "heat", "heavy", "height", "help", "hero", "hesitate", "hide", "high", "highlight",
            "hire", "history", "hold", "hole", "holiday", "home", "honest", "honor", "hope", "horizon",
            "horror", "horse", "host", "hot", "hotel", "hour", "house", "huge", "human", "humble",
            "humor", "hundred", "hungry", "hunt", "hurry", "hurt"
        ]
    }
}

enum DictionaryError: LocalizedError {
    case invalidURL
    case invalidResponse
    case wordNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for dictionary API"
        case .invalidResponse:
            return "Invalid response from dictionary API"
        case .wordNotFound:
            return "Word not found in dictionary"
        case .decodingError:
            return "Failed to decode dictionary data"
        }
    }
}
