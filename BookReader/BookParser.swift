//
//  BookParser.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation
import UIKit

class BookParser {
    func normalizePath(_ path: String) -> String {
        let pathWithoutFragment = path.components(separatedBy: "#").first ?? path
        return NSString(string: pathWithoutFragment).standardizingPath
    }
    
    func parseEPUB(at epubURL: URL) async throws -> Book? {
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
                try fileManager.unzipItem(at: epubURL, to: tempDir)
                
                let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
                let containerParser = ContainerXMLParser()
                guard let opfRelativePath = try await containerParser.parse(url: containerURL) else {
                    throw NSError(domain: "EPUBParserError", code: 404, userInfo: [NSLocalizedDescriptionKey: "OPF файл не найден"])
                }
                let opfURL = tempDir.appendingPathComponent(opfRelativePath)
                
                let opfParser = OPFParser()
                try! await opfParser.parse(url: opfURL)
                
                // Парсим оглавление книги (NCX)
                if let ncxPath = opfParser.manifest["ncx"] {
                    let ncxURL = opfURL.deletingLastPathComponent().appendingPathComponent(ncxPath)
                    let ncxParser = NCXParser()
                    await ncxParser.parse(url: ncxURL)
                    let chapters = ncxParser.flattenTOC()  // Главы из NCX файла в правильном порядке
                    
                    // Пример обработки глав из NCX
                    for chapter in chapters {
                        print("Chapter: \(chapter.label), Content URL: \(chapter.contentSrc)")
                    }
                }

                var coverImage: UIImage? = nil
                if let coverItemID = opfParser.coverItemID, let coverPath = opfParser.manifest[coverItemID] {
                    let coverURL = opfURL.deletingLastPathComponent().appendingPathComponent(coverPath)
                    if let imageData = try? Data(contentsOf: coverURL), let image = UIImage(data: imageData) {
                        coverImage = image
                    }
                }
                
                var chapters: [Chapter] = []

                // 1. Парсинг глав через NCX для получения правильных заголовков и порядка
                if let ncxPath = opfParser.manifest["ncx"] {
                    let ncxURL = opfURL.deletingLastPathComponent().appendingPathComponent(ncxPath)
                    let ncxParser = NCXParser()
                    await ncxParser.parse(url: ncxURL)
                    let orderedChapters = ncxParser.flattenTOC()  // Главы из NCX файла в правильном порядке
                    
                    // 2. Используем spine для получения физического содержимого глав
                    for navPoint in orderedChapters {
                        // В NCX <content src="..."> указывает на нужный файл главы
                        if let href = opfParser.manifest.values.first(where: { $0.contains(navPoint.contentSrc) }) {
                            let chapterURL = opfURL.deletingLastPathComponent().appendingPathComponent(href)
                            let content = try String(contentsOf: chapterURL, encoding: .utf8)
                            let baseURL = chapterURL.deletingLastPathComponent()
                            
                            // Заголовок главы берем из NCX
                            let chapter = Chapter(title: navPoint.label, content: content, baseURL: baseURL)
                            chapters.append(chapter)
                        }
                    }
                }
                
                let baseURL = opfURL.deletingLastPathComponent()
                
                return Book(
                    title: opfParser.metadata["title"] ?? "No title",
                    author: opfParser.metadata["creator"] ?? "Unknown author",
                    chapters: chapters,
                    baseURL: baseURL,
                    coverImage: coverImage
                )
            } catch {
                throw NSError(domain: "EPUBParserError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга EPUB: \(error.localizedDescription)"])
            }
        }
    
    func extractContent(from htmlURL: URL) async throws -> String {
        return try String(contentsOf: htmlURL, encoding: .utf8)
    }
    
    func extractTitle(from htmlContent: String) -> String? {
        guard let titleStartRange = htmlContent.range(of: "<title>"),
              let titleEndRange = htmlContent.range(of: "</title>", range: titleStartRange.upperBound..<htmlContent.endIndex) else {
            return nil
        }
        let title = htmlContent[titleStartRange.upperBound..<titleEndRange.lowerBound]
        return String(title).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
