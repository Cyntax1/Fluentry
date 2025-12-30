//
//  FluentryWidget.swift
//  FluentryWidget
//
//  Modern, customizable widgets following Apple HIG
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Configuration Intent
struct WidgetStyleIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Style"
    static var description = IntentDescription("Customize your widget")
    
    @Parameter(title: "Show Streak", default: true)
    var showStreak: Bool
    
    @Parameter(title: "Show Stats", default: true)
    var showStats: Bool
}

// MARK: - Models
struct FluentryWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayPoints: Int
    let totalWords: Int
    let lessonsCompleted: Int
    let wordOfTheDay: WordOfDay?
    let configuration: WidgetStyleIntent
}

struct WordOfDay: Codable {
    let word: String
    let definition: String
    let example: String
    let pronunciation: String
}

// MARK: - Timeline Provider
struct FluentryWidgetProvider: AppIntentTimelineProvider {
    private let appGroupID = "group.com.fluentry.app"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func placeholder(in context: Context) -> FluentryWidgetEntry {
        FluentryWidgetEntry(
            date: Date(),
            streak: 7,
            todayPoints: 120,
            totalWords: 150,
            lessonsCompleted: 5,
            wordOfTheDay: WordOfDay(
                word: "Serendipity",
                definition: "The occurrence of events by chance in a happy way",
                example: "Finding this park was pure serendipity.",
                pronunciation: "/ˌserənˈdɪpɪti/"
            ),
            configuration: WidgetStyleIntent()
        )
    }
    
    func snapshot(for configuration: WidgetStyleIntent, in context: Context) async -> FluentryWidgetEntry {
        loadCurrentData(configuration: configuration)
    }
    
    func timeline(for configuration: WidgetStyleIntent, in context: Context) async -> Timeline<FluentryWidgetEntry> {
        let entry = loadCurrentData(configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadCurrentData(configuration: WidgetStyleIntent) -> FluentryWidgetEntry {
        let streak = userDefaults?.integer(forKey: "widget_streak") ?? 0
        let todayPoints = userDefaults?.integer(forKey: "widget_todayPoints") ?? 0
        let totalWords = userDefaults?.integer(forKey: "widget_totalWords") ?? 0
        let lessonsCompleted = userDefaults?.integer(forKey: "widget_lessonsCompleted") ?? 0
        let wordData = userDefaults?.data(forKey: "widget_wordOfTheDay")
        
        var wordOfTheDay: WordOfDay?
        if let data = wordData {
            wordOfTheDay = try? JSONDecoder().decode(WordOfDay.self, from: data)
        }
        
        return FluentryWidgetEntry(
            date: Date(),
            streak: streak,
            todayPoints: todayPoints,
            totalWords: totalWords,
            lessonsCompleted: lessonsCompleted,
            wordOfTheDay: wordOfTheDay,
            configuration: configuration
        )
    }
}

// MARK: - Stats Widget Views

struct SmallStatsView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("\(entry.streak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                
                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Spacer()
        }
    }
}

struct MediumStatsView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            if entry.configuration.showStreak {
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.orange)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text("\(entry.streak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    
                    Text("day streak")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
                .frame(maxWidth: .infinity)
            }
            
            if entry.configuration.showStats {
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(icon: "star.fill", value: "\(entry.todayPoints)", label: "points", color: .blue)
                    StatRow(icon: "book.fill", value: "\(entry.lessonsCompleted)", label: "lessons", color: .purple)
                    StatRow(icon: "character.book.closed.fill", value: "\(entry.totalWords)", label: "words", color: .green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct LargeStatsView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Your Progress")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.streak) day streak")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(streakMessage(entry.streak))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            HStack(spacing: 12) {
                CompactStatCard(icon: "star.fill", value: "\(entry.todayPoints)", label: "points", color: .blue)
                CompactStatCard(icon: "book.fill", value: "\(entry.lessonsCompleted)", label: "lessons", color: .purple)
            }
            
            HStack(spacing: 12) {
                CompactStatCard(icon: "character.book.closed.fill", value: "\(entry.totalWords)", label: "words", color: .green)
                CompactStatCard(icon: "chart.line.uptrend.xyaxis", value: "\(entry.todayPoints * 7)", label: "week pts", color: .orange)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    func streakMessage(_ streak: Int) -> String {
        if streak == 0 { return "Start your learning journey" }
        else if streak < 7 { return "Keep going! 💪" }
        else if streak < 30 { return "Amazing progress! 🎉" }
        return "Incredible dedication! 🏆"
    }
}

// MARK: - Word of the Day Views

struct SmallWordView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if let word = entry.wordOfTheDay {
                VStack(spacing: 8) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.blue)
                    Text(word.word)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text("Word of the Day")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("No word yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct MediumWordView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        if let word = entry.wordOfTheDay {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text("Word of the Day")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.word)
                        .font(.system(size: 26, weight: .bold))
                    Text(word.pronunciation)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Text(word.definition)
                    .font(.system(size: 14, weight: .regular))
                    .lineLimit(2)
                
                Spacer(minLength: 0)
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "book.pages")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Check back tomorrow!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct LargeWordView: View {
    let entry: FluentryWidgetEntry
    
    var body: some View {
        if let word = entry.wordOfTheDay {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text("Word of the Day")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(entry.date, style: .date)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 36, weight: .bold))
                    Text(word.pronunciation)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    LabeledSection(label: "DEFINITION", text: word.definition, isItalic: false)
                    LabeledSection(label: "EXAMPLE", text: "\"\(word.example)\"", isItalic: true)
                }
                
                Spacer(minLength: 0)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: "book.pages")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("No word available")
                    .font(.system(size: 18, weight: .semibold))
                Text("Open the app to set today's word")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Reusable Components

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

struct CompactStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct LabeledSection: View {
    let label: String
    let text: String
    let isItalic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(text)
                .font(.system(size: isItalic ? 14 : 15, weight: .regular))
                .foregroundStyle(isItalic ? .secondary : .primary)
                .italic(isItalic)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Widget Entry Views

struct StatsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: FluentryWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall: SmallStatsView(entry: entry)
        case .systemMedium: MediumStatsView(entry: entry)
        case .systemLarge: LargeStatsView(entry: entry)
        default: SmallStatsView(entry: entry)
        }
    }
}

struct WordWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: FluentryWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall: SmallWordView(entry: entry)
        case .systemMedium: MediumWordView(entry: entry)
        case .systemLarge: LargeWordView(entry: entry)
        default: SmallWordView(entry: entry)
        }
    }
}

// MARK: - Widgets

struct FluentryStatsWidget: Widget {
    let kind: String = "FluentryStatsWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetStyleIntent.self, provider: FluentryWidgetProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Learning Stats")
        .description("Track your progress and streak")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FluentryWordWidget: Widget {
    let kind: String = "FluentryWordWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetStyleIntent.self, provider: FluentryWidgetProvider()) { entry in
            WordWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Word of the Day")
        .description("Learn a new word every day")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
