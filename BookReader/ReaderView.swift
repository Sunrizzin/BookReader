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
                .padding(.horizontal)
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
                    
                    // Добавляем нижний тулбар с кнопками "Предыдущая" и "Следующая"
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: previousChapter) {
                            Label("Previous", systemImage: "arrow.left")
                        }
                        .disabled(selectedChapterIndex == 0) // Отключаем кнопку на первой главе
                        
                        Spacer()
                        
                        Button(action: nextChapter) {
                            Label("Next", systemImage: "arrow.right")
                        }
                        .disabled(selectedChapterIndex == book.chapters.count - 1) // Отключаем кнопку на последней главе
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
        coverImage: nil
    ))
}
