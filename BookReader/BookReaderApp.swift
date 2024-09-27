//
//  BookReaderApp.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI
import SwiftData

@main
struct BookReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Book.self, Chapter.self]) 
        }
    }
}
