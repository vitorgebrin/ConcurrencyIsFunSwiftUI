//
//  ConcurrencyIsFunSwiftUIApp.swift
//  ConcurrencyIsFunSwiftUI
//
//  Created by Vitor Kalil on 26/03/24.
//

import SwiftUI
import SwiftData

@main
struct ConcurrencyIsFunSwiftUIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
            GeneralView()
        }
        .modelContainer(sharedModelContainer)
    }
}
