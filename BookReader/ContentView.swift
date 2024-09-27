//
//  ContentView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    let bookParser = BookParser()
    
    @State private var isFileImporterPresented = false
    @State private var selectedFileURL: URL?
    @State private var book: Book?
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    isFileImporterPresented = true
                }) {
                    Text("Выбрать EPUB файл")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if let book = book {
                    Text("Книга: \(book.title)")
                        .font(.title3)
                        .padding(20)
                    
                    NavigationLink(destination: ReaderView(book: book)) {
                        Text("Читать")
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                } else if let fileURL = selectedFileURL {
                    Text("Выбран файл: \(fileURL.lastPathComponent)")
                        .padding()
                }
            }
            .navigationTitle("EPUB Reader")
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.epub]
            ) { result in
                do {
                    let selectedURL = try result.get()
                    selectedFileURL = selectedURL
                    
                    if selectedURL.startAccessingSecurityScopedResource() {
                        defer { selectedURL.stopAccessingSecurityScopedResource() }
                        if let parsedBook = bookParser.parseEPUB(at: selectedURL) {
                            book = parsedBook
                        } else {
                            print("Не удалось распарсить EPUB файл")
                        }
                    } else {
                        print("Не удалось получить доступ к файлу")
                    }
                } catch {
                    print("Ошибка при выборе файла: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
