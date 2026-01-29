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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            CognitiveScore.self,
            ReactionTimeResult.self,
            SleepData.self,
            VoiceMetrics.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(sharedModelContainer)
    }
}
