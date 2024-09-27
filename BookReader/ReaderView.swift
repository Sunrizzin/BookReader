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
    
    var body: some View {
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
            }
    }
}

