//
//  HackathonAppApp.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 29/01/26.
//

import SwiftUI
import SwiftData

@main
struct HackathonAppApp: App {
    
    init() {
        // Eka Care SDK will be initialized when user enters ABHA ID
        // The API key is stored in EkaCareAuthService
        print("🚀 CognitiveTrack App Starting...")
        print("📋 Eka Care API Key configured")
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            CognitiveScore.self,
            ReactionTimeResult.self,
            SleepData.self,
            PhotoRecognitionResult.self,
            UserPhoto.self,
            MedicalRecordAnalysis.self,
            ShapeSequenceResult.self,
            // Coremlgame integrated models (renamed to avoid duplicate symbols)
            CoremlCognitiveScore.self,
            CoremlSleepData.self,
            CoremlReactionTimeResult.self,
            CoremlPhotoRecognitionResult.self,
        ])
        
        // Use versioned database name to avoid conflicts with old schema
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If schema migration fails, print error and use in-memory as fallback
            print("⚠️ ModelContainer error: \(error)")
            print("Using in-memory database. Delete app and reinstall to fix.")
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [inMemoryConfig])
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                CoremlgameDashboardView()
                    .tabItem {
                        Label("Cognitive", systemImage: "brain.head.profile")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
