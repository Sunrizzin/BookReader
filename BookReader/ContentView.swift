//
//  ContentView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @State private var isFileImporterPresented = false
    @State private var books: [Book] = []
    
    @State private var selectedBook: Book? = nil
    @State private var isShowingReader = false
    
    var body: some View {
        NavigationStack {
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
                do {
                    let selectedURL = try result.get()
                    
                    if selectedURL.startAccessingSecurityScopedResource() {
                        defer { selectedURL.stopAccessingSecurityScopedResource() }
                        if let parsedBook = BookParser().parseEPUB(at: selectedURL) {
                            books.append(parsedBook)
                        } else {
                            print("Parsing error")
                        }
                    } else {
                        print("Access error")
                    }
                } catch {
                    print("Error file: \(error.localizedDescription)")
                }
            }
            .navigationDestination(isPresented: $isShowingReader) {
                if let selectedBook = selectedBook {
                    ReaderView(book: selectedBook)
                } else {
                    Text("No book selected")
                }
            }
        }
    }
    
    private func deleteBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
