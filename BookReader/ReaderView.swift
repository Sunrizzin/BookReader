//
//  ReaderView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI
import WebKit

struct ReaderView: View {
    var book: Book
    @State private var selectedChapterIndex = 0
    @State private var errorMessage: ErrorMessage?
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var fontSize: Int = 100
    
    var body: some View {
        VStack {
            WebView(
                htmlContent: book.chapters[selectedChapterIndex].content,
                baseURL: book.chapters[selectedChapterIndex].baseURL,
                cssContent: book.css ?? "",
                colorScheme: .dark,
                fontSize: $fontSize
            )
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle(book.chapters[selectedChapterIndex].title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(0..<book.chapters.count, id: \.self) { index in
                            Button(action: {
                                selectedChapterIndex = index
                            }) {
                                Text(book.chapters[index].title)
                                    .lineLimit(1)
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    Button(action: decreaseFontSize) {
                        Image(systemName: "textformat.size.smaller")
                    }
                    
                    Button(action: increaseFontSize) {
                        Image(systemName: "textformat.size.larger")
                    }
                    
                    Spacer()
                    
                    Button(action: previousChapter) {
                        Label("Previous", systemImage: "arrow.left")
                    }
                    .disabled(selectedChapterIndex == 0)
                    
                    Button(action: nextChapter) {
                        Label("Next", systemImage: "arrow.right")
                    }
                    .disabled(selectedChapterIndex == book.chapters.count - 1)
                    
                    
                }
            }
        }
        .alert(item: $errorMessage) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func increaseFontSize() {
        fontSize += 10
    }
    
    private func decreaseFontSize() {
        if fontSize > 50 {
            fontSize -= 10
        }
    }
    
    // Функции для переключения глав
    private func previousChapter() {
        if selectedChapterIndex > 0 {
            selectedChapterIndex -= 1
        }
    }
    
    private func nextChapter() {
        if selectedChapterIndex < book.chapters.count - 1 {
            selectedChapterIndex += 1
        }
    }
}

#Preview {
    ReaderView(book: Book(
        title: "Sample Book",
        author: "Author",
        chapters: [
            Chapter(title: "Chapter 1", content: "<html><body><h1>Chapter 1</h1></body></html>", baseURL: URL(fileURLWithPath: "")),
            Chapter(title: "Chapter 2", content: "<html><body><h1>Chapter 2</h1></body></html>", baseURL: URL(fileURLWithPath: ""))
        ],
        baseURL: nil,
        coverImage: nil,
        css: ""
    ))
}
