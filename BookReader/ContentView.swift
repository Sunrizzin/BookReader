//
//  ContentView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title, order: .forward) private var books: [Book]
    
    @State private var isFileImporterPresented = false
    @State private var selectedBook: Book? = nil
    @State private var isShowingReader = false
    @State private var isLoading = false
    @State private var errorMessage: ErrorMessage?
    
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
                            ForEach(books) { book in
                                HStack {
                                    if let coverImage = book.coverImage {
                                        Image(uiImage: coverImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 75)
                                            .cornerRadius(8)
                                            .padding(.trailing, 10)
                                    } else {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.gray)
                                                .frame(width: 50, height: 75)
                                                .cornerRadius(8)
                                                .padding(.trailing, 10)
                                            Image(systemName: "book")
                                                .foregroundStyle(.white)
                                                .padding(.trailing, 10)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(book.author)
                                            .font(.title3)
                                        Text(book.title)
                                            .font(.headline)
                                    }
                                    
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
                
                if let errorMessage {
                    Text(errorMessage.message)
                        .padding()
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
            .alert(item: $errorMessage) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) async {
        do {
            let selectedURL = try result.get()
            isLoading = true
            defer { isLoading = false }
            
            if selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                
                do {
                    // Пытаемся распарсить EPUB файл
                    if let parsedBook = try await BookParser().parseEPUB(at: selectedURL) {
                        modelContext.insert(parsedBook)
                    } else {
                        errorMessage = ErrorMessage(message: "Failed to parse the EPUB file.")
                    }
                } catch let nsError as NSError {
                    // Обработка конкретных ошибок, например, отсутствие container.xml
                    if nsError.domain == "EPUBParserError" && nsError.code == 404 {
                        errorMessage = ErrorMessage(message: "OPF file not found. The EPUB file might be corrupted or incorrectly formatted.")
                    } else if nsError.domain == "EPUBParserError" && nsError.code == 500 {
                        errorMessage = ErrorMessage(message: "Error parsing EPUB file: \(nsError.localizedDescription)")
                    } else {
                        // Общая обработка остальных ошибок
                        errorMessage = ErrorMessage(message: "Unexpected error during parsing: \(nsError.localizedDescription)")
                    }
                }
            } else {
                errorMessage = ErrorMessage(message: "Failed to access the file.")
            }
        } catch {
            // Общая обработка ошибок, если не удалось получить URL файла
            errorMessage = ErrorMessage(message: "File import error: \(error.localizedDescription)")
        }
    }
    
    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = books[index]
            modelContext.delete(book)
        }
    }
}

#Preview {
    ContentView()
}
