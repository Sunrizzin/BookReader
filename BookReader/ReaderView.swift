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
    
    var body: some View {
        VStack {
            WebView(htmlContent: book.chapters[selectedChapterIndex].content, baseURL: book.chapters[selectedChapterIndex].baseURL)
                .edgesIgnoringSafeArea(.bottom)
                .padding(.horizontal, 4)
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
                }
        }
        .alert(item: $errorMessage) { error in  // Алерт для ошибок
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
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
        coverImage: nil
    ))
}
