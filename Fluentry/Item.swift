//
//  LearningModels.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import Foundation
import SwiftData

// Word model for vocabulary
@Model
final class Word {
    @Attribute(.unique) var term: String
    var definition: String
    var example: String
    var pronunciation: String
    var difficulty: DifficultyLevel
    var category: String
    var lastReviewed: Date?
    var proficiencyLevel: Int // 0-5 scale
    var synonyms: [String]
    var isFavorited: Bool
    var mastered: Bool
    
    init(term: String, 
         definition: String, 
         example: String, 
         pronunciation: String, 
         difficulty: DifficultyLevel = .medium,
         category: String = "General",
         proficiencyLevel: Int = 0,
         synonyms: [String] = [],
         isFavorited: Bool = false,
         mastered: Bool = false) {
        self.term = term
        self.definition = definition
        self.example = example
        self.pronunciation = pronunciation
        self.difficulty = difficulty
        self.category = category
        self.proficiencyLevel = proficiencyLevel
        self.synonyms = synonyms
        self.isFavorited = isFavorited
        self.mastered = mastered
     }
}

// Lesson model
@Model
final class Lesson {
    @Attribute(.unique) var id: UUID
    var title: String
    var lessonDescription: String
    var content: String
    var category: LessonCategory
    var difficulty: DifficultyLevel
    var completed: Bool
    var dateCreated: Date
    var dateCompleted: Date?
    @Relationship(deleteRule: .cascade) var exercises: [Exercise] = []
    
    init(title: String, 
         lessonDescription: String, 
         content: String, 
         category: LessonCategory,
         difficulty: DifficultyLevel = .medium,
         completed: Bool = false) {
        self.id = UUID()
        self.title = title
        self.lessonDescription = lessonDescription
        self.content = content
        self.category = category
        self.difficulty = difficulty
        self.completed = completed
        self.dateCreated = Date()
        self.exercises = []
    }
}

// Exercise model
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var title: String
    var instructions: String
    var type: ExerciseType
    var content: String // JSON string to store exercise data
    var difficulty: DifficultyLevel
    var completed: Bool
    var score: Int?
    
    init(title: String,
         instructions: String,
         type: ExerciseType,
         content: String,
         difficulty: DifficultyLevel = .medium,
         completed: Bool = false) {
        self.id = UUID()
        self.title = title
        self.instructions = instructions
        self.type = type
        self.content = content
        self.difficulty = difficulty
        self.completed = completed
    }
}

// User progress model
@Model
final class UserProgress {
    @Attribute(.unique) var id: UUID
    var streak: Int
    var totalPoints: Int
    var vocabularyMastered: Int
    var lessonsCompleted: Int
    var lastActive: Date
    
    init() {
        self.id = UUID()
        self.streak = 0
        self.totalPoints = 0
        self.vocabularyMastered = 0
        self.lessonsCompleted = 0
        self.lastActive = Date()
    }
}

// User profile model
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int?
    var nativeLanguage: String
    var learningGoal: String
    var proficiencyLevel: String
    var interests: [String]
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    
    init(name: String = "",
         age: Int? = nil,
         nativeLanguage: String = "",
         learningGoal: String = "",
         proficiencyLevel: String = "Beginner",
         interests: [String] = [],
         hasCompletedOnboarding: Bool = false) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.nativeLanguage = nativeLanguage
        self.learningGoal = learningGoal
        self.proficiencyLevel = proficiencyLevel
        self.interests = interests
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
    }
}

// Enums for categorization
enum DifficultyLevel: String, Codable, Comparable, CaseIterable {
    case beginner
    case easy
    case medium
    case hard
    case advanced
    
    // Implement Comparable protocol
    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        let order: [DifficultyLevel] = [.beginner, .easy, .medium, .hard, .advanced]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

enum LessonCategory: String, Codable, CaseIterable {
    case vocabulary
    case grammar
    case pronunciation
    case reading
    case writing
    case conversation
    case idioms
    case slang
}

enum ExerciseType: String, Codable, CaseIterable {
    case multipleChoice
    case fillInBlank
    case matchingPairs
    case speaking
    case listening
    case translation
    case scrambledWords
    case writeAnswer
    
    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Multiple Choice"
        case .fillInBlank:
            return "Fill in the Blank"
        case .matchingPairs:
            return "Matching Pairs"
        case .speaking:
            return "Speaking"
        case .listening:
            return "Listening"
        case .translation:
            return "Translation"
        case .scrambledWords:
            return "Scrambled Words"
        case .writeAnswer:
            return "Write Answer"
        }
    }
}
