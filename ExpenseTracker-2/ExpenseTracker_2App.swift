//
//  ExpenseTracker_2App.swift
//  ExpenseTracker-2
//
//  Created by Şahin Karahan on 10.01.2025.
//

import SwiftUI

@main
struct ExpenseTracker_2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
