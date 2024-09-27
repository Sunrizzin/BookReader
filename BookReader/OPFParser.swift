//
//  OPFParser.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation

class OPFParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var tempValue = ""
    
    private(set) var metadata: [String: String] = [:]
    private(set) var manifest: [String: String] = [:]
    private(set) var spine: [String] = []
    
    var coverItemID: String?
    
    func parse(url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard let parser = XMLParser(contentsOf: url) else {
                continuation.resume(throwing: NSError(domain: "OPFParserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать XMLParser"]))
                return
            }
            parser.delegate = self
            if parser.parse() {
                continuation.resume()
            } else {
                continuation.resume(throwing: NSError(domain: "OPFParserError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга OPF"]))
            }
        }
    }
    
    // Начало элемента
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        // Обработка элемента item
        if elementName == "item" {
            if let id = attributeDict["id"], let href = attributeDict["href"] {
                manifest[id] = href
            }
        }
        
        // Обработка элемента itemref
        if elementName == "itemref" {
            if let idref = attributeDict["idref"] {
                spine.append(idref)
            }
        }
        
        // Обработка элемента meta
        if elementName == "meta", let name = attributeDict["name"], name == "cover" {
            coverItemID = attributeDict["content"]
        }
        
        // Очищаем tempValue для нового элемента
        tempValue = ""
    }
    
    // Найдены символы между открывающим и закрывающим тегами
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempValue += string
    }
    
    // Завершение элемента
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Обрабатываем метаданные в зависимости от текущего элемента
        if currentElement == "dc:title" {
            metadata["title"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:creator" {
            metadata["creator"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:language" {
            metadata["language"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:identifier" {
            metadata["identifier"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:publisher" {
            metadata["publisher"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Сбрасываем текущий элемент после завершения обработки
        currentElement = ""
        tempValue = ""
    }
}
