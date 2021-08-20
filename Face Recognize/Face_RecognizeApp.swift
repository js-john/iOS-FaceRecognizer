//
//  Face_RecognizeApp.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/20.
//

import SwiftUI

@main
struct Face_RecognizeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
