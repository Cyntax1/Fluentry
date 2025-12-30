//
//  FluentryApp.swift
//  Fluentry
//
//  Created by Rishith Chennupati on 5/25/25.
//

import SwiftUI
import SwiftData

@main
struct FluentryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Word.self,
            Lesson.self,
            Exercise.self,
            UserProgress.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Auto-cleanup: If database fails to load, delete it and recreate
            print("⚠️ ModelContainer failed: \(error)")
            print("🔄 Cleaning up old database files...")
            
            // Try to find and delete SwiftData files
            let fileManager = FileManager.default
            let searchPaths: [FileManager.SearchPathDirectory] = [
                .applicationSupportDirectory,
                .documentDirectory,
                .libraryDirectory
            ]
            
            for searchPath in searchPaths {
                if let baseURL = try? fileManager.url(for: searchPath, in: .userDomainMask, appropriateFor: nil, create: false) {
                    // Look for .store files
                    if let enumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: nil) {
                        for case let fileURL as URL in enumerator {
                            if fileURL.pathExtension == "store" || fileURL.lastPathComponent.contains("default") {
                                try? fileManager.removeItem(at: fileURL)
                                print("🗑️ Deleted: \(fileURL.lastPathComponent)")
                            }
                        }
                    }
                }
            }
            
            // Try again with clean slate
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
