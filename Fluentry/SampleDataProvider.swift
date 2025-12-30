//
//  SampleDataProvider.swift
//  Fluentry
//
//  Sample data provider for testing and demonstration
//

import Foundation
import SwiftData

@MainActor
struct SampleDataProvider {
    
    // MARK: - Sample Words
    static func createSampleWords(context: ModelContext) {
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
                term: "Ambiguous",
                definition: "Open to more than one interpretation; not having one obvious meaning",
                example: "The contract contained ambiguous language that led to disputes.",
                pronunciation: "/æmˈbɪɡjuəs/",
                difficulty: .easy,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["unclear", "vague", "equivocal"]
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
            ),
            Word(
                term: "Meticulous",
                definition: "Showing great attention to detail; very careful and precise",
                example: "She is meticulous in her work, never missing even the smallest detail.",
                pronunciation: "/mɪˈtɪkjələs/",
                difficulty: .medium,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["careful", "thorough", "precise"]
            ),
            Word(
                term: "Nostalgic",
                definition: "Experiencing a sentimental longing for the past",
                example: "Looking at old photos always makes me feel nostalgic.",
                pronunciation: "/nɒˈstældʒɪk/",
                difficulty: .easy,
                category: "Emotion",
                proficiencyLevel: 0,
                synonyms: ["sentimental", "wistful", "reminiscent"]
            ),
            Word(
                term: "Quintessential",
                definition: "Representing the most perfect or typical example of a quality or class",
                example: "Paris is the quintessential romantic city.",
                pronunciation: "/ˌkwɪntɪˈsenʃəl/",
                difficulty: .hard,
                category: "General",
                proficiencyLevel: 0,
                synonyms: ["typical", "archetypal", "classic"]
            )
        ]
        
        for word in sampleWords {
            context.insert(word)
        }
        
        try? context.save()
    }
    
    // MARK: - Sample Exercises
    static func createSampleExercises(context: ModelContext) {
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
                        "question": "Choose the synonym of 'Diligent'",
                        "options": ["Lazy", "Hardworking", "Confused", "Angry"],
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
                        "question": "Finding this perfect apartment was pure ________.",
                        "options": ["catastrophe", "requirement", "serendipity", "obligation"],
                        "correctAnswer": 2
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
            context.insert(exercise)
        }
        
        try? context.save()
    }
    
    // MARK: - Sample Lessons
    static func createSampleLessons(context: ModelContext) {
        let lesson1 = Lesson(
            title: "Advanced Vocabulary Mastery",
            lessonDescription: "Learn sophisticated English words for professional communication",
            content: "This lesson introduces advanced vocabulary commonly used in business and academic settings.",
            category: .vocabulary,
            difficulty: .hard
        )
        
        let lesson2 = Lesson(
            title: "Common Idioms and Expressions",
            lessonDescription: "Master everyday English idioms",
            content: "Explore the most commonly used idioms in English conversation.",
            category: .idioms,
            difficulty: .medium
        )
        
        context.insert(lesson1)
        context.insert(lesson2)
        
        try? context.save()
    }
    
    // MARK: - User Progress
    static func createUserProgress(context: ModelContext) {
        let progress = UserProgress()
        context.insert(progress)
        try? context.save()
    }
    
    // MARK: - Load All Sample Data
    static func loadAllSampleData(context: ModelContext) {
        createSampleWords(context: context)
        createSampleExercises(context: context)
        createSampleLessons(context: context)
        createUserProgress(context: context)
    }
}
