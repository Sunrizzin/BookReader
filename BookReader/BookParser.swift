import Foundation
import UIKit
import ZIPFoundation

class BookParser {
    
    func parseEPUB(at epubURL: URL) async throws -> Book? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: epubURL, to: tempDir)
            
            guard let opfURL = findFile(withExtension: "opf", in: tempDir) else {
                throw NSError(domain: "EPUBParserError", code: 404, userInfo: [NSLocalizedDescriptionKey: "OPF файл не найден"])
            }
            
            let opfParser = OPFParser()
            try await opfParser.parse(url: opfURL)
            
            var chapters: [Chapter] = []
            
            if let ncxURL = findFile(withExtension: "ncx", in: tempDir) {
                let ncxParser = NCXParser()
                try await ncxParser.parse(url: ncxURL)
                let orderedChapters = ncxParser.flattenTOC()
                
                for navPoint in orderedChapters {
                    if let href = opfParser.manifest.values.first(where: { normalizePath($0) == normalizePath(navPoint.contentSrc) }) {
                        let chapterURL = opfURL.deletingLastPathComponent().appendingPathComponent(href)
                        let content = try String(contentsOf: chapterURL, encoding: .utf8)
                        let baseURL = chapterURL.deletingLastPathComponent()
                        
                        let chapter = Chapter(title: navPoint.label, content: content, baseURL: baseURL)
                        chapters.append(chapter)
                    } else {
                        print("Не удалось найти href для \(navPoint.contentSrc)")
                    }
                }
            } else {
                print("NCX файл не найден, попробуем использовать spine")
                
                for idref in opfParser.spine {
                    if let href = opfParser.manifest[idref] {
                        let chapterURL = opfURL.deletingLastPathComponent().appendingPathComponent(href)
                        
                        print("Читаем файл главы по пути: \(chapterURL.path)")
                        
                        do {
                            let content = try String(contentsOf: chapterURL, encoding: .utf8)
                            
                            let title = href.components(separatedBy: "/").last ?? "Без названия"
                            let baseURL = chapterURL.deletingLastPathComponent()
                            
                            let chapter = Chapter(title: title, content: content, baseURL: baseURL)
                            chapters.append(chapter)
                        } catch {
                            print("Ошибка чтения содержимого главы: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
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
            
            var cssContent: String = ""
            if let cssURL = findFile(withExtension: "css", in: tempDir) {
                do {
                    cssContent = try String(contentsOf: cssURL, encoding: .utf8)
                } catch {
                    print("Не удалось прочитать CSS файл: \(error.localizedDescription)")
                }
            } else {
                print("CSS файл не найден")
            }
            
            let baseURL = opfURL.deletingLastPathComponent()
            
            return Book(
                title: opfParser.metadata["title"] ?? "No title",
                author: opfParser.metadata["creator"] ?? "Unknown author",
                chapters: chapters,
                baseURL: baseURL,
                coverImage: coverImage,
                css: cssContent
            )
        } catch {
            throw NSError(domain: "EPUBParserError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга EPUB: \(error.localizedDescription)"])
        }
    }
    
    private func findFile(withExtension ext: String, in directory: URL) -> URL? {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == ext.lowercased() {
                    return fileURL
                }
            }
        }
        return nil
    }
    
    private func normalizePath(_ path: String) -> String {
        return path.components(separatedBy: "#").first ?? path
    }
}
