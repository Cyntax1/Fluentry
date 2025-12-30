//
//  DictionaryLookupView.swift
//  Fluentry
//
//  Dictionary lookup view for searching and learning new words
//

import SwiftUI
import SwiftData

struct DictionaryLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchTerm = ""
    @State private var isSearching = false
    @State private var searchResult: DictionaryWord?
    @State private var errorMessage: String?
    @State private var showAddConfirmation = false
    @State private var recentSearches: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Search Bar
                searchBarView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if isSearching {
                            loadingView
                        } else if let result = searchResult {
                            wordResultView(result)
                        } else if let error = errorMessage {
                            errorView(error)
                        } else {
                            suggestionsView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.05), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .alert("Word Added!", isPresented: $showAddConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The word has been added to your vocabulary.")
            }
            .onAppear {
                loadRecentSearches()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 15) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.indigo, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Dictionary Lookup")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Search for any word to see its definition, examples, and synonyms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Enter a word to look up", text: $searchTerm)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        searchWord()
                    }
                
                if !searchTerm.isEmpty {
                    Button(action: { searchTerm = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button(action: searchWord) {
                Text("Search")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.indigo, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(searchTerm.isEmpty || isSearching)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Looking up word...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Word Result View
    private func wordResultView(_ dictWord: DictionaryWord) -> some View {
        VStack(spacing: 20) {
            // Word Header
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 15) {
                    Text(dictWord.word.capitalized)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.indigo)
                    
                    if !FreeDictionaryService.shared.getPronunciation(from: dictWord).isEmpty {
                        Text(FreeDictionaryService.shared.getPronunciation(from: dictWord))
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // Meanings
            ForEach(Array(dictWord.meanings.prefix(3).enumerated()), id: \.offset) { index, meaning in
                meaningCardView(meaning, index: index + 1)
            }
            
            // Synonyms
            let synonyms = FreeDictionaryService.shared.getAllSynonyms(from: dictWord)
            if !synonyms.isEmpty {
                synonymsCardView(synonyms)
            }
            
            // Add to Vocabulary Button
            Button(action: {
                addToVocabulary(dictWord)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to My Vocabulary")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.indigo, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Meaning Card
    private func meaningCardView(_ meaning: DictionaryWord.Meaning, index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 12) {
                // Part of Speech
                HStack {
                    Text("\(index). \(meaning.partOfSpeech)")
                        .font(.headline)
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.indigo.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                
                // Definitions
                ForEach(Array(meaning.definitions.prefix(2).enumerated()), id: \.offset) { defIndex, definition in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("•")
                                .fontWeight(.bold)
                            Text(definition.definition)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if let example = definition.example {
                            HStack(alignment: .top) {
                                Image(systemName: "quote.bubble")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                Text("\"\(example)\"")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Synonyms Card
    private func synonymsCardView(_ synonyms: [String]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.purple)
                    Text("Synonyms")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(synonyms.prefix(10), id: \.self) { synonym in
                            Text(synonym)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Word Not Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Suggestions View
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Searches")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    ForEach(recentSearches, id: \.self) { search in
                        Button(action: {
                            searchTerm = search
                            searchWord()
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.indigo)
                                Text(search)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            // Quick suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Try These Words")
                    .font(.headline)
                    .fontWeight(.bold)
                
                let suggestions = ["eloquent", "persevere", "benevolent", "resilient", "profound"]
                
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        searchTerm = suggestion
                        searchWord()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text(suggestion.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    private func searchWord() {
        guard !searchTerm.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResult = nil
        
        Task {
            do {
                let result = try await FreeDictionaryService.shared.fetchWord(searchTerm.lowercased())
                
                await MainActor.run {
                    searchResult = result
                    isSearching = false
                    saveRecentSearch(searchTerm)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }
    
    private func addToVocabulary(_ dictWord: DictionaryWord) {
        let newWord = Word(
            term: dictWord.word,
            definition: FreeDictionaryService.shared.getPrimaryDefinition(from: dictWord),
            example: FreeDictionaryService.shared.getExampleSentence(from: dictWord),
            pronunciation: FreeDictionaryService.shared.getPronunciation(from: dictWord),
            difficulty: .medium,
            category: "Dictionary Lookup",
            synonyms: FreeDictionaryService.shared.getAllSynonyms(from: dictWord)
        )
        
        modelContext.insert(newWord)
        try? modelContext.save()
        showAddConfirmation = true
    }
    
    private func saveRecentSearch(_ search: String) {
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == search.lowercased() }
        searches.insert(search, at: 0)
        recentSearches = Array(searches.prefix(5))
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    private func loadRecentSearches() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recentSearches") {
            recentSearches = saved
        }
    }
}

#Preview {
    let schema = Schema([
        Word.self,
        Lesson.self,
        Exercise.self,
        UserProgress.self,
        UserProfile.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return DictionaryLookupView()
        .modelContainer(container)
}
