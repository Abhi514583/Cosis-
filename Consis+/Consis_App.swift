//
//  Consis_App.swift
//  Consis+
//
//  Created by Abhishek Thakur on 2026-04-05.
//

import SwiftUI
import SwiftData

@main
struct Consis_App: App {
    var sharedModelContainer: ModelContainer
    @StateObject private var dataManager: WorkoutDataManager

    init() {
        let schema = Schema([
            AppSettings.self,
            ExerciseEntity.self,
            RoutineDayEntity.self,
            PlannedExerciseEntity.self,
            PlannedSetEntity.self,
            WorkoutSessionEntity.self,
            ExerciseLogEntity.self,
            WorkoutSetEntity.self,
            ProgressionPhotoEntity.self,
            BodyZoneEntity.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.sharedModelContainer = container
            self._dataManager = StateObject(wrappedValue: WorkoutDataManager(modelContext: container.mainContext))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
