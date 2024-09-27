//
//  ContentView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State private var isFileImporterPresented = false
    @State private var books: [Book] = []
    @State private var selectedBook: Book? = nil
    @State private var isShowingReader = false
    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?  // Используем новую структуру
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    if books.isEmpty {
                        Text("No books available. Add a book to start reading.")
                            .font(.headline)
                            .padding()
                    } else {
                        List {
                            ForEach(books, id: \.title) { book in
                                HStack {
                                    if let coverImage = book.coverImage {
                                        Image(uiImage: coverImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 75)
                                            .cornerRadius(8)
                                            .padding(.trailing, 10)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 50, height: 75)
                                            .cornerRadius(8)
                                            .padding(.trailing, 10)
                                    }
                                    
                                    Text(book.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedBook = book
                                        isShowingReader = true
                                    }) {
                                        Text("Read")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteBooks)
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Book Reader")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isFileImporterPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add book")
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.epub]
            ) { result in
                Task {
                    await handleFileImport(result: result)
                }
            }
            .navigationDestination(isPresented: $isShowingReader) {
                if let selectedBook = selectedBook {
                    ReaderView(book: selectedBook)
                } else {
                    Text("No book selected")
                }
            }
            .alert(item: $errorMessage) { error in  // Теперь используем ErrorMessage
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Асинхронная обработка импорта файла
    private func handleFileImport(result: Result<URL, Error>) async {
        do {
            let selectedURL = try result.get()
            isLoading = true
            defer { isLoading = false }
            
            if selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                
                if let parsedBook = try await BookParser().parseEPUB(at: selectedURL) {
                    books.append(parsedBook)
                } else {
                    errorMessage = ErrorMessage(message: "Failed to parse the EPUB file.")
                }
            } else {
                errorMessage = ErrorMessage(message: "Failed to access the file.")
            }
        } catch {
            errorMessage = ErrorMessage(message: "File import error: \(error.localizedDescription)")
        }
    }
    
    private func deleteBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
