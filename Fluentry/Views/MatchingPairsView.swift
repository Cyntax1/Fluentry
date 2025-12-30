//
//  MatchingPairsView.swift
//  Fluentry
//
//  Real matching pairs game with animations
//

import SwiftUI

struct MatchingPairsView: View {
    let words: [Word]
    var onCompletion: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var gameWords: [Word] = []
    @State private var leftCards: [MatchCard] = []
    @State private var rightCards: [MatchCard] = []
    @State private var selectedLeft: UUID?
    @State private var selectedRight: UUID?
    @State private var matchedPairs: Set<UUID> = []
    @State private var score = 0
    @State private var attempts = 0
    @State private var showResults = false
    @State private var wrongMatch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    resultsView
                } else {
                    gameView
                }
            }
            .navigationTitle("Matching Pairs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupGame()
            }
        }
    }
    
    private var gameView: some View {
        VStack(spacing: 20) {
            // Score header
            HStack {
                VStack(alignment: .leading) {
                    Text("Matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(matchedPairs.count) / \(gameWords.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(attempts > 0 ? Int(Double(matchedPairs.count) / Double(attempts) * 100) : 0)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(attempts > 0 && Double(matchedPairs.count) / Double(attempts) > 0.8 ? .green : .orange)
                }
            }
            .padding(.horizontal)
            
            // Instructions
            Text("Tap a word, then tap its matching definition")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            // Game board
            HStack(spacing: 20) {
                // Left column (words)
                VStack(spacing: 12) {
                    ForEach(leftCards) { card in
                        MatchCardView(
                            card: card,
                            isSelected: selectedLeft == card.id,
                            isMatched: matchedPairs.contains(card.id),
                            onTap: {
                                handleLeftCardTap(card)
                            }
                        )
                    }
                }
                
                // Right column (definitions)
                VStack(spacing: 12) {
                    ForEach(rightCards) { card in
                        MatchCardView(
                            card: card,
                            isSelected: selectedRight == card.id,
                            isMatched: matchedPairs.contains(card.id),
                            onTap: {
                                handleRightCardTap(card)
                            }
                        )
                    }
                }
            }
            .padding()
            .shake(wrongMatch ? 1 : 0)
            
            Spacer()
        }
        .padding(.top)
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            // Success icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            Text("Perfect Matching!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                ResultRow(label: "Matches", value: "\(matchedPairs.count) / \(gameWords.count)")
                ResultRow(label: "Attempts", value: "\(attempts)")
                ResultRow(label: "Accuracy", value: "\(attempts > 0 ? Int(Double(matchedPairs.count) / Double(attempts) * 100) : 0)%")
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    resetGame()
                }) {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
                
                Button(action: {
                    onCompletion?()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func setupGame() {
        // Select random words
        let selectedWords = Array(words.shuffled().prefix(6))
        gameWords = selectedWords
        
        // Create left cards (words/terms)
        leftCards = selectedWords.map { word in
            MatchCard(
                id: UUID(),
                content: word.term,
                matchId: word.term,
                type: .word
            )
        }
        
        // Create right cards (definitions) and shuffle
        rightCards = selectedWords.map { word in
            MatchCard(
                id: UUID(),
                content: word.definition,
                matchId: word.term,
                type: .definition
            )
        }.shuffled()
    }
    
    private func handleLeftCardTap(_ card: MatchCard) {
        guard !matchedPairs.contains(card.id) else { return }
        
        HapticFeedback.light()
        selectedLeft = card.id
        
        // Check for match if both selected
        if let rightId = selectedRight,
           let rightCard = rightCards.first(where: { $0.id == rightId }) {
            checkMatch(left: card, right: rightCard)
        }
    }
    
    private func handleRightCardTap(_ card: MatchCard) {
        guard !matchedPairs.contains(card.id) else { return }
        
        HapticFeedback.light()
        selectedRight = card.id
        
        // Check for match if both selected
        if let leftId = selectedLeft,
           let leftCard = leftCards.first(where: { $0.id == leftId }) {
            checkMatch(left: leftCard, right: card)
        }
    }
    
    private func checkMatch(left: MatchCard, right: MatchCard) {
        attempts += 1
        
        if left.matchId == right.matchId {
            // Correct match!
            HapticFeedback.success()
            matchedPairs.insert(left.id)
            matchedPairs.insert(right.id)
            score += 10
            
            selectedLeft = nil
            selectedRight = nil
            
            // Check if game complete
            if matchedPairs.count == (gameWords.count * 2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showResults = true
                }
            }
        } else {
            // Wrong match
            HapticFeedback.error()
            wrongMatch = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedLeft = nil
                selectedRight = nil
                wrongMatch = false
            }
        }
    }
    
    private func resetGame() {
        matchedPairs.removeAll()
        selectedLeft = nil
        selectedRight = nil
        score = 0
        attempts = 0
        showResults = false
        setupGame()
    }
}

// MARK: - Match Card Model
struct MatchCard: Identifiable {
    let id: UUID
    let content: String
    let matchId: String
    let type: CardType
    
    enum CardType {
        case word, definition
    }
}

// MARK: - Match Card View
struct MatchCardView: View {
    let card: MatchCard
    let isSelected: Bool
    let isMatched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(card.content)
                .font(card.type == .word ? .headline : .subheadline)
                .fontWeight(card.type == .word ? .bold : .regular)
                .foregroundColor(isMatched ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                        )
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8)
                )
        }
        .disabled(isMatched)
        .opacity(isMatched ? 0.7 : 1.0)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: isMatched)
    }
    
    private var cardBackground: LinearGradient {
        if isMatched {
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        } else if isSelected {
            return LinearGradient(colors: [.blue.opacity(0.2), .blue.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var borderColor: Color {
        if isMatched {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Result Row
struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Shake Effect
extension View {
    func shake(_ shake: Int) -> some View {
        self.modifier(ShakeEffect(shakes: shake))
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    
    var animatableData: Int {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(CGFloat(shakes) * .pi * 2), y: 0))
    }
}
