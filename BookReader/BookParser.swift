import Foundation
import UIKit
import ZIPFoundation

class BookParser {
    
    func parseEPUB(at epubURL: URL) async throws -> Book? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            // Распаковка EPUB в временную директорию
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: epubURL, to: tempDir)
            
            // Чтение container.xml для нахождения OPF файла
            let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
            let containerParser = ContainerXMLParser()
            guard let opfRelativePath = try await containerParser.parse(url: containerURL) else {
                throw NSError(domain: "EPUBParserError", code: 404, userInfo: [NSLocalizedDescriptionKey: "OPF файл не найден"])
            }
            let opfURL = tempDir.appendingPathComponent(opfRelativePath)
            
            // Парсинг OPF файла
            let opfParser = OPFParser()
            try await opfParser.parse(url: opfURL)
            
            // Парсим оглавление книги (NCX)
            var chapters: [Chapter] = []
            if let ncxPath = opfParser.manifest["ncx"] {
                let ncxURL = opfURL.deletingLastPathComponent().appendingPathComponent(ncxPath)
                let ncxParser = NCXParser()
                try await ncxParser.parse(url: ncxURL)
                let orderedChapters = ncxParser.flattenTOC()  // Главы из NCX файла
                
                // Используем spine для получения физического содержимого глав
                for navPoint in orderedChapters {
                    // Проверка на содержание фрагментов (#) в пути
                    if let href = opfParser.manifest.values.first(where: { normalizePath($0) == normalizePath(navPoint.contentSrc) }) {
                        let chapterURL = opfURL.deletingLastPathComponent().appendingPathComponent(href)
                        let content = try String(contentsOf: chapterURL, encoding: .utf8)
                        let baseURL = chapterURL.deletingLastPathComponent()
                        
                        // Добавляем главу в список
                        let chapter = Chapter(title: navPoint.label, content: content, baseURL: baseURL)
                        chapters.append(chapter)
                    } else {
                        print("Не удалось найти href для \(navPoint.contentSrc)")
                    }
                }
            } else {
                print("NCX файл не найден в манифесте OPF")
            }
            
            // Парсинг обложки (если есть)
            var coverImage: UIImage? = nil
            if let coverItemID = opfParser.coverItemID, let coverPath = opfParser.manifest[coverItemID] {
                let coverURL = opfURL.deletingLastPathComponent().appendingPathComponent(coverPath)
                if let imageData = try? Data(contentsOf: coverURL), let image = UIImage(data: imageData) {
                    coverImage = image
                } else {
                    print("Не удалось загрузить обложку по пути \(coverPath)")
                }
            } else {
                print("Обложка не найдена в OPF метаданных")
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
            // Обработка ошибок при парсинге
            throw NSError(domain: "EPUBParserError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга EPUB: \(error.localizedDescription)"])
        }
    }
    
    // Утилита для нормализации пути (убирает фрагменты)
    private func normalizePath(_ path: String) -> String {
        return path.components(separatedBy: "#").first ?? path
    }
}
