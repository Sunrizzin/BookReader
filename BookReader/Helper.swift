//
//  Helper.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation
import ZIPFoundation
import SwiftUI
import WebKit

struct Book {
    var title: String
    var author: String
    var chapters: [Chapter]
    var baseURL: URL?
}

struct Chapter {
    var title: String
    var content: String
    var baseURL: URL
}

class BookParser {
    
    func normalizePath(_ path: String) -> String {
        let pathWithoutFragment = path.components(separatedBy: "#").first ?? path
        let standardizedPath = NSString(string: pathWithoutFragment).standardizingPath
        return standardizedPath
    }
    
    func parseEPUB(at epubURL: URL) -> Book? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            
            try fileManager.unzipItem(at: epubURL, to: tempDir)
            let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
            let containerParser = ContainerXMLParser()
            guard let opfRelativePath = containerParser.parse(url: containerURL) else {
                print("Не удалось найти путь к .opf файлу")
                return nil
            }
            let opfURL = tempDir.appendingPathComponent(opfRelativePath)
            
            let opfParser = OPFParser()
            opfParser.parse(url: opfURL)
            
            // Определение версии EPUB и парсинг оглавления
            var tocMap: [String: String] = [:]
            if let ncxPath = opfParser.manifest["ncx"] {
                let ncxURL = opfURL.deletingLastPathComponent().appendingPathComponent(ncxPath)
                let ncxParser = NCXParser()
                ncxParser.parse(url: ncxURL)
                let flatTOC = ncxParser.flattenTOC()
                
                // Создаем сопоставление между contentSrc и label
                for navPoint in flatTOC {
                    let normalizedSrc = normalizePath(navPoint.contentSrc)
                    tocMap[normalizedSrc] = navPoint.label
                }
            }
            
            // Парсинг книги
            var chapters: [Chapter] = []
            for id in opfParser.spine {
                if let href = opfParser.manifest[id] {
                    let chapterURL = opfURL.deletingLastPathComponent().appendingPathComponent(href)
                    let content = try String(contentsOf: chapterURL, encoding: .utf8)
                    let baseURL = chapterURL.deletingLastPathComponent()
                    
                    let normalizedHref = normalizePath(href)
                    let title = tocMap[normalizedHref] ?? "Глава"
                    
                    let chapter = Chapter(title: title, content: content, baseURL: baseURL)
                    chapters.append(chapter)
                }
            }
            
            let baseURL = opfURL.deletingLastPathComponent()
            
            let book = Book(
                title: opfParser.metadata["title"] ?? "Без названия",
                author: opfParser.metadata["creator"] ?? "Неизвестный автор",
                chapters: chapters,
                baseURL: baseURL
            )
            
            return book
        } catch {
            print("Ошибка при парсинге EPUB: \(error)")
            return nil
        }
    }
    
    func extractContent(from htmlURL: URL) -> String {
        do {
            let htmlString = try String(contentsOf: htmlURL)
            return htmlString
        } catch {
            print("Ошибка при чтении файла \(htmlURL): \(error)")
            return ""
        }
    }
    
    func extractTitle(from htmlContent: String) -> String? {
        if let titleStartRange = htmlContent.range(of: "<title>"),
           let titleEndRange = htmlContent.range(of: "</title>", range: titleStartRange.upperBound..<htmlContent.endIndex) {
            let title = htmlContent[titleStartRange.upperBound..<titleEndRange.lowerBound]
            return String(title).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
}


class ContainerXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private(set) var opfPath: String?
    
    func parse(url: URL) -> String? {
        guard let parser = XMLParser(contentsOf: url) else {
            print("Не удалось инициализировать XMLParser с URL: \(url)")
            return nil
        }
        parser.delegate = self
        if parser.parse() {
            return opfPath
        } else {
            print("Ошибка при парсинге container.xml: \(parser.parserError?.localizedDescription ?? "Неизвестная ошибка")")
            return nil
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "rootfile" {
            opfPath = attributeDict["full-path"]
        }
    }
}

class OPFParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var tempValue = ""
    
    private(set) var metadata: [String: String] = [:]
    
    private(set) var manifest: [String: String] = [:]
    
    private(set) var spine: [String] = []
    
    private(set) var isEPUB3: Bool = false
    
    func parse(url: URL) {
        guard let parser = XMLParser(contentsOf: url) else {
            print("Не удалось инициализировать XMLParser с URL: \(url)")
            return
        }
        parser.delegate = self
        if !parser.parse() {
            print("Ошибка при парсинге .opf файла: \(parser.parserError?.localizedDescription ?? "Неизвестная ошибка")")
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "package" {
            if let version = attributeDict["version"], version.hasPrefix("3") {
                isEPUB3 = true
            }
        } else if elementName == "item" {
            if let id = attributeDict["id"], let href = attributeDict["href"] {
                manifest[id] = href
            }
        } else if elementName == "itemref" {
            if let idref = attributeDict["idref"] {
                spine.append(idref)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if currentElement == "dc:title" {
            metadata["title"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:creator" {
            metadata["creator"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:language" {
            metadata["language"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:publisher" {
            metadata["publisher"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        tempValue = ""
    }
}

class NCXParser: NSObject, XMLParserDelegate {
    struct NavPoint {
        var playOrder: String
        var label: String
        var contentSrc: String
        var children: [NavPoint] = []
    }
    
    private var currentElement = ""
    private var tempValue = ""
    private var navPointStack: [NavPoint] = []
    private(set) var toc: [NavPoint] = []
    
    func parse(url: URL) {
        guard let parser = XMLParser(contentsOf: url) else {
            print("Не удалось инициализировать XMLParser с URL: \(url)")
            return
        }
        parser.delegate = self
        if !parser.parse() {
            print("Ошибка при парсинге toc.ncx: \(parser.parserError?.localizedDescription ?? "Неизвестная ошибка")")
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "navPoint" {
            let playOrder = attributeDict["playOrder"] ?? ""
            let navPoint = NavPoint(playOrder: playOrder, label: "", contentSrc: "")
            navPointStack.append(navPoint)
        } else if elementName == "content" {
            if var currentNavPoint = navPointStack.last, let src = attributeDict["src"] {
                currentNavPoint.contentSrc = src
                navPointStack[navPointStack.count - 1] = currentNavPoint
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "text" {
            if var currentNavPoint = navPointStack.last {
                currentNavPoint.label = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
                navPointStack[navPointStack.count - 1] = currentNavPoint
            }
        } else if elementName == "navPoint" {
            let completedNavPoint = navPointStack.popLast()!
            if var parentNavPoint = navPointStack.last {
                parentNavPoint.children.append(completedNavPoint)
                navPointStack[navPointStack.count - 1] = parentNavPoint
            } else {
                toc.append(completedNavPoint)
            }
        }
        tempValue = ""
    }
}

struct WebView: UIViewRepresentable {
    var htmlContent: String
    var baseURL: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
}

extension NCXParser {
    func flattenTOC() -> [NavPoint] {
        var flatTOC: [NavPoint] = []
        
        func flatten(navPoints: [NavPoint]) {
            for navPoint in navPoints {
                flatTOC.append(navPoint)
                if !navPoint.children.isEmpty {
                    flatten(navPoints: navPoint.children)
                }
            }
        }
        
        flatten(navPoints: toc)
        return flatTOC
    }
}
