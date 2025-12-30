//
//  WidgetDataManager.swift
//  Fluentry
//
//  Manages data sharing between app and widgets
//

import Foundation
import WidgetKit

// MARK: - Word of the Day Model
struct WordOfDay: Codable {
    let word: String
    let definition: String
    let example: String
    let pronunciation: String
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - CHANGE THIS to match your bundle ID
    private let appGroupID = "group.com.fluentry.app"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Save Data
    
    func updateWidgetData(streak: Int, todayPoints: Int, totalWords: Int, lessonsCompleted: Int) {
        userDefaults?.set(streak, forKey: "widget_streak")
        userDefaults?.set(todayPoints, forKey: "widget_todayPoints")
        userDefaults?.set(totalWords, forKey: "widget_totalWords")
        userDefaults?.set(lessonsCompleted, forKey: "widget_lessonsCompleted")
        userDefaults?.set(Date(), forKey: "widget_lastUpdate")
        
        // Tell widgets to reload
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateWordOfTheDay(_ word: WordOfDay) {
        if let encoded = try? JSONEncoder().encode(word) {
            userDefaults?.set(encoded, forKey: "widget_wordOfTheDay")
            userDefaults?.set(Date(), forKey: "widget_wordOfTheDayDate")
            WidgetCenter.shared.reloadTimelines(ofKind: "FluentryWordWidget")
        }
    }
    
    func setWordOfTheDayFromVocabulary(word: String, definition: String, example: String, pronunciation: String) {
        let wordOfDay = WordOfDay(
            word: word,
            definition: definition,
            example: example,
            pronunciation: pronunciation
        )
        updateWordOfTheDay(wordOfDay)
    }
    
    // MARK: - Load Data
    
    func getStreak() -> Int {
        userDefaults?.integer(forKey: "widget_streak") ?? 0
    }
    
    func getTodayPoints() -> Int {
        userDefaults?.integer(forKey: "widget_todayPoints") ?? 0
    }
    
    func getTotalWords() -> Int {
        userDefaults?.integer(forKey: "widget_totalWords") ?? 0
    }
    
    func getLessonsCompleted() -> Int {
        userDefaults?.integer(forKey: "widget_lessonsCompleted") ?? 0
    }
    
    func getLastUpdate() -> Date? {
        userDefaults?.object(forKey: "widget_lastUpdate") as? Date
    }
}

// MARK: - UserProgress Extension

extension UserProgress {
    /// Call this whenever user progress changes to update widgets
    func updateWidgets() {
        WidgetDataManager.shared.updateWidgetData(
            streak: self.streak,
            todayPoints: self.totalPoints, // or calculate today's points
            totalWords: self.vocabularyMastered,
            lessonsCompleted: self.lessonsCompleted
        )
    }
}
