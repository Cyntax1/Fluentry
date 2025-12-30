//
//  ProfileView.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    var userProgress: UserProgress
    var userProfile: UserProfile?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var lessons: [Lesson]
    @Query private var words: [Word]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showEditProfile = false
    @State private var showNotificationSettings = false
    
    // Sample weekly progress data
    private let weeklyData: [ProgressPoint] = [
        ProgressPoint(day: "Mon", points: 120),
        ProgressPoint(day: "Tue", points: 85),
        ProgressPoint(day: "Wed", points: 200),
        ProgressPoint(day: "Thu", points: 150),
        ProgressPoint(day: "Fri", points: 60),
        ProgressPoint(day: "Sat", points: 180),
        ProgressPoint(day: "Sun", points: 110)
    ]
    
    // Sample monthly progress data
    private let monthlyData: [ProgressPoint] = [
        ProgressPoint(day: "Week 1", points: 450),
        ProgressPoint(day: "Week 2", points: 520),
        ProgressPoint(day: "Week 3", points: 380),
        ProgressPoint(day: "Week 4", points: 600)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    profileHeader
                    
                    statsGridView
                    
                    progressChartSection
                    
                    achievementsSection
                    
                    settingsSection
                }
                .padding(.horizontal)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            HStack(spacing: 20) {
                // Profile avatar with gradient border
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 85, height: 85)
                    
                    Text(getInitials())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // User info
                VStack(alignment: .leading, spacing: 5) {
                    Text(userProfile?.name ?? "User Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(getUserTitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(userProgress.streak) Day Streak", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Text(userProfile?.proficiencyLevel ?? "Beginner")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
        .padding(.top)
    }
    
    // MARK: - Stats Grid View
    private var statsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            statsCard(
                title: "Vocabulary",
                value: "\(words.count)",
                icon: "character.book.closed",
                color: .blue
            )
            
            statsCard(
                title: "Lessons",
                value: "\(lessons.count)",
                icon: "book.closed",
                color: .purple
            )
            
            statsCard(
                title: "Points",
                value: "\(userProgress.totalPoints)",
                icon: "star.fill",
                color: .yellow
            )
            
            statsCard(
                title: "Completed",
                value: "\(lessons.filter { $0.completed }.count)",
                icon: "checkmark.circle",
                color: .green
            )
        }
    }
    
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // MARK: - Progress Chart Section
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Your Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(TimeRange.week)
                    Text("Month").tag(TimeRange.month)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 15) {
                    // Charts implementation
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(selectedTimeRange == .week ? weeklyData : monthlyData) { item in
                                BarMark(
                                    x: .value("Day", item.day),
                                    y: .value("Points", item.points)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(8)
                            }
                        }
                        .frame(height: 220)
                    } else {
                        // Fallback for older iOS versions
                        Text("Progress Chart")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Stats below chart
                    HStack {
                        statItem(
                            value: selectedTimeRange == .week ? "7" : "28",
                            label: "Days",
                            icon: "calendar",
                            color: .blue
                        )
                        
                        Divider()
                        
                        statItem(
                            value: selectedTimeRange == .week ? "905" : "1950",
                            label: "Points",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        Divider()
                        
                        statItem(
                            value: selectedTimeRange == .week ? "15" : "35",
                            label: "Words",
                            icon: "character.book.closed",
                            color: .green
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Achievements")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    achievementCard(
                        title: "7-Day Streak",
                        icon: "flame.fill",
                        color: .orange,
                        unlocked: true
                    )
                    
                    achievementCard(
                        title: "Vocabulary Master",
                        icon: "character.book.closed.fill",
                        color: .blue,
                        unlocked: false
                    )
                    
                    achievementCard(
                        title: "Grammar Expert",
                        icon: "text.book.closed.fill",
                        color: .green,
                        unlocked: false
                    )
                    
                    achievementCard(
                        title: "Perfect Score",
                        icon: "star.fill",
                        color: .yellow,
                        unlocked: true
                    )
                }
                .padding(.vertical, 5)
            }
        }
    }
    
    private func achievementCard(title: String, icon: String, color: Color, unlocked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(unlocked ? color.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    if unlocked {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundColor(color)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(unlocked ? .primary : .secondary)
            }
            .padding()
        }
        .frame(width: 130, height: 160)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Learning Info")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                if let profile = userProfile {
                    if let age = profile.age {
                        infoRow(icon: "person.fill", title: "Age", value: "\(age) years old", color: .blue)
                        Divider()
                    }
                    
                    if !profile.nativeLanguage.isEmpty {
                        infoRow(icon: "globe", title: "Native Language", value: profile.nativeLanguage, color: .green)
                        Divider()
                    }
                    
                    if !profile.learningGoal.isEmpty {
                        infoRow(icon: "target", title: "Learning Goal", value: profile.learningGoal, color: .orange)
                        Divider()
                    }
                    
                    if !profile.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.headline)
                                    .foregroundColor(.pink)
                                    .frame(width: 30)
                                
                                Text("Interests")
                                    .font(.headline)
                            }
                            .padding(.vertical, 12)
                            
                            FlowLayout(items: profile.interests) { interest in
                                Text(interest)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.1))
                                    .foregroundColor(.pink)
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                } else {
                    Text("Complete onboarding to see your profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.bottom)
    }
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func getInitials() -> String {
        if let name = userProfile?.name, !name.isEmpty {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                let first = String(components.first?.prefix(1) ?? "")
                let last = String(components.last?.prefix(1) ?? "")
                return "\(first)\(last)".uppercased()
            } else {
                return String(name.prefix(2)).uppercased()
            }
        }
        return "FL"
    }
    
    private func getUserTitle() -> String {
        if let profile = userProfile {
            if !profile.learningGoal.isEmpty {
                return profile.learningGoal
            } else if !profile.nativeLanguage.isEmpty {
                return "Learning from \(profile.nativeLanguage)"
            }
        }
        return "English Learner"
    }
}

// MARK: - Models
struct ProgressPoint: Identifiable {
    var id = UUID()
    var day: String
    var points: Double
}

enum TimeRange {
    case week
    case month
}

// MARK: - Flow Layout for Interests
struct FlowLayout<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView
    
    @State private var totalHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                itemView(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == items.count - 1 {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if index == items.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

#Preview {
    ProfileView(userProgress: UserProgress(), userProfile: nil)
        .modelContainer(for: Lesson.self, inMemory: true)
        .modelContainer(for: Word.self, inMemory: true)
}
