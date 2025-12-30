//
//  OnboardingView.swift
//  Fluentry
//
//  Comprehensive onboarding flow to collect user information
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age: Double = 25
    @State private var nativeLanguage = ""
    @State private var learningGoal = ""
    @State private var customGoal = ""
    @State private var proficiencyLevel = "Beginner"
    @State private var selectedInterests: Set<String> = []
    
    let proficiencyLevels = ["Beginner", "Elementary", "Intermediate", "Advanced", "Fluent"]
    let goalOptions = [
        "Improve business English for work",
        "Prepare for English exams (TOEFL/IELTS)",
        "Travel and communicate abroad",
        "Academic studies and research",
        "Daily conversation skills",
        "Professional certifications",
        "Other"
    ]
    let interestOptions = [
        "Business", "Travel", "Academic", "Conversation",
        "Writing", "Reading", "Listening", "Grammar",
        "Vocabulary", "Pronunciation", "Culture", "Literature"
    ]
    
    var body: some View {
        ZStack {
            // Clean iOS background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern progress indicator
                modernProgressIndicator
                    .padding(.top, 20)
                
                // Page content with smooth transitions
                ZStack {
                    ForEach(0..<8) { index in
                        if currentPage == index {
                            Group {
                                switch index {
                                case 0: welcomePage
                                case 1: namePage
                                case 2: languagePage
                                case 3: proficiencyPage
                                case 4: goalsPage
                                case 5: learningGoalsPage
                                case 6: interestsPage
                                case 7: completionPage
                                default: EmptyView()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                
                Spacer()
                
                // Modern navigation buttons
                modernNavigationButtons
                    .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var modernProgressIndicator: some View {
        VStack(spacing: 12) {
            // Page counter
            Text("Step \(currentPage + 1) of 8")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Progress bar
            ProgressView(value: Double(currentPage + 1), total: 8.0)
                .tint(.blue)
                .padding(.horizontal, 30)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Welcome Page
    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer(minLength: 40)
                
                // App icon
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Fluentry")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Your AI-powered English learning companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                
                // Feature cards
                VStack(spacing: 16) {
                    modernFeatureCard(
                        icon: "sparkles",
                        title: "AI-Powered Lessons",
                        description: "Personalized content just for you",
                        color: .blue
                    )
                    
                    modernFeatureCard(
                        icon: "message.fill",
                        title: "Conversational Practice",
                        description: "Chat with AI and improve fluency",
                        color: .blue
                    )
                    
                    modernFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Your Progress",
                        description: "See your improvement over time",
                        color: .blue
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 20)
            }
        }
    }
    
    // MARK: - Feature Card
    private func modernFeatureCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Name Page
    private var namePage: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("What's your name?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("We'll personalize your learning experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextField("First name", text: $firstName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextField("Last name", text: $lastName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 30)
        }
    }
    
    // MARK: - Age Page
    private var languagePage: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("How old are you?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Optional - helps us personalize content")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 20) {
                    Text("\(Int(age)) years old")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 12) {
                        Slider(value: $age, in: 10...100, step: 1)
                            .tint(.blue)
                        
                        HStack {
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 30)
        }
    }
    
    // MARK: - Native Language Page
    private var proficiencyPage: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                Image(systemName: "flag.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("What's your native language?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("This helps us provide better examples")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Native Language")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Spanish, Chinese, Hindi", text: $nativeLanguage)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 30)
        }
    }
    
    // MARK: - Proficiency Level Page
    private var goalsPage: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("What's your current English level?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Be honest - we'll adjust the content to match")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    ForEach(proficiencyLevels, id: \.self) { level in
                        Button(action: {
                            withAnimation {
                                proficiencyLevel = level
                            }
                        }) {
                            HStack {
                                Text(level)
                                    .font(.headline)
                                Spacer()
                                if proficiencyLevel == level {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(proficiencyLevel == level ? .white : .primary)
                            .padding()
                            .background(
                                proficiencyLevel == level
                                ? Color.blue
                                : Color(.secondarySystemGroupedBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 30)
        }
    }
    
    // MARK: - Learning Goals Page
    private var learningGoalsPage: some View {
        ScrollView {
            VStack(spacing: 25) {
                Image(systemName: "target")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("What's your learning goal?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                
                Text("We'll create a personalized learning path")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select a goal or enter your own")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 12) {
                        ForEach(goalOptions, id: \.self) { goal in
                            Button(action: {
                                withAnimation {
                                    if goal == "Other" {
                                        learningGoal = ""
                                    } else {
                                        learningGoal = goal
                                    }
                                }
                            }) {
                                HStack {
                                    Text(goal)
                                        .font(.body)
                                        .foregroundColor(learningGoal == goal ? .white : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    if learningGoal == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(
                                    learningGoal == goal
                                    ? Color.blue
                                    : Color(.secondarySystemGroupedBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Custom goal input (shows when "Other" is selected)
                    if learningGoal == "Other" || (learningGoal.isEmpty && !goalOptions.contains(learningGoal)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Custom Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $customGoal)
                                .frame(height: 100)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Group {
                                        if customGoal.isEmpty {
                                            Text("e.g., I want to improve my...")
                                                .foregroundColor(.secondary.opacity(0.5))
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Interests Page
    private var interestsPage: some View {
        ScrollView {
            VStack(spacing: 30) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("What interests you?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select topics you'd like to focus on")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(interestOptions, id: \.self) { interest in
                        Button(action: {
                            withAnimation {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        }) {
                            Text(interest)
                                .font(.subheadline)
                                .fontWeight(selectedInterests.contains(interest) ? .bold : .regular)
                                .foregroundColor(selectedInterests.contains(interest) ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedInterests.contains(interest)
                                    ? Color.blue
                                    : Color.gray.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 30)
        }
    }
    
    // MARK: - Completion Page
    private var completionPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text("You're all set!")
                .font(.system(size: 36, weight: .bold))
            
            Text("Let's start your English learning journey")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 15) {
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                summaryRow(icon: "person.fill", label: "Name", value: fullName)
                if !nativeLanguage.isEmpty {
                    summaryRow(icon: "flag.fill", label: "Native Language", value: nativeLanguage)
                }
                summaryRow(icon: "chart.bar.fill", label: "Level", value: proficiencyLevel)
                if selectedInterests.count > 0 {
                    HStack(alignment: .top) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.blue)
                        Text("Interests:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(Array(selectedInterests).prefix(3).joined(separator: ", "))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Modern Navigation Buttons
    private var modernNavigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentPage > 0 {
                Button(action: previousPage) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // Continue/Get Started button
            Button(action: nextPage) {
                HStack(spacing: 8) {
                    Text(currentPage == 7 ? "Get Started" : "Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if currentPage < 7 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if canProceed {
                            Color.blue
                        } else {
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: canProceed ? Color.blue.opacity(0.3) : .clear, radius: 15, x: 0, y: 8)
                .scaleEffect(canProceed ? 1.0 : 0.98)
                .animation(.spring(response: 0.3), value: canProceed)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
    }
    
    private var canProceed: Bool {
        switch currentPage {
        case 1: return !firstName.isEmpty // At least first name required
        case 3: return !nativeLanguage.isEmpty
        case 5: // Learning Goals page
            if learningGoal == "Other" {
                return !customGoal.isEmpty
            }
            return !learningGoal.isEmpty
        default: return true
        }
    }
    
    private func previousPage() {
        withAnimation {
            currentPage -= 1
        }
    }
    
    private func nextPage() {
        if currentPage == 7 {
            completeOnboarding()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    private func completeOnboarding() {
        // Use custom goal if "Other" was selected
        let finalGoal = learningGoal == "Other" ? customGoal : learningGoal
        
        // Combine first and last name
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        let profile = UserProfile(
            name: fullName,
            age: Int(age),
            nativeLanguage: nativeLanguage,
            learningGoal: finalGoal,
            proficiencyLevel: proficiencyLevel,
            interests: Array(selectedInterests),
            hasCompletedOnboarding: true
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
