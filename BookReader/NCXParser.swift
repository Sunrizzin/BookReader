import Foundation

class NCXParser: NSObject, XMLParserDelegate {
    struct NavPoint {
        var playOrder: Int
        var label: String
        var contentSrc: String
        var children: [NavPoint] = []
    }
    
    private var currentElement = ""
    private var tempValue = ""
    private var navPointStack: [NavPoint] = []
    private(set) var toc: [NavPoint] = []
    
    // Асинхронный метод парсинга
    func parse(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached { [weak self] in
                guard let self = self else { return }
                
                guard let parser = XMLParser(contentsOf: url) else {
                    continuation.resume(throwing: NSError(domain: "NCXParserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать XMLParser"]))
                    return
                }
                
                parser.delegate = self
                
                if !parser.parse() {
                    continuation.resume(throwing: NSError(domain: "NCXParserError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга NCX"]))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // Начало элемента
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "navPoint" {
            let playOrder = Int(attributeDict["playOrder"] ?? "0") ?? 0
            let navPoint = NavPoint(playOrder: playOrder, label: "", contentSrc: "")
            navPointStack.append(navPoint)
        } else if elementName == "content" {
            // Сохраняем путь к главе
            if var currentNavPoint = navPointStack.last, let src = attributeDict["src"] {
                currentNavPoint.contentSrc = src
                navPointStack[navPointStack.count - 1] = currentNavPoint
            }
        }
        
        // Очищаем временное значение для нового элемента
        tempValue = ""
    }
    
    // Найдены символы внутри элемента
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Добавляем символы с удалением лишних пробелов
        tempValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Конец элемента
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "text" {
            if var currentNavPoint = navPointStack.last {
                currentNavPoint.label = tempValue
                navPointStack[navPointStack.count - 1] = currentNavPoint
            }
        } else if elementName == "navPoint" {
            guard let completedNavPoint = navPointStack.popLast() else { return }
            
            if var parentNavPoint = navPointStack.last {
                parentNavPoint.children.append(completedNavPoint)
                navPointStack[navPointStack.count - 1] = parentNavPoint
            } else {
                toc.append(completedNavPoint)
            }
        }
        
        // Сбрасываем временное значение после завершения элемента
        tempValue = ""
    }
    
    // Плоское представление TOC (оглавления)
    func flattenTOC() -> [NavPoint] {
        var flatTOC: [NavPoint] = []
        
        // Рекурсивная функция для обхода иерархии
        func flatten(navPoints: [NavPoint]) {
            for navPoint in navPoints {
                flatTOC.append(navPoint)
                if !navPoint.children.isEmpty {
                    flatten(navPoints: navPoint.children)
                }
            }
        }
        
        flatten(navPoints: toc)
        
        // Сортируем по playOrder
        flatTOC.sort { $0.playOrder < $1.playOrder }
        
        return flatTOC
    }
    
    // Обработка ошибки парсинга
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Ошибка парсинга NCX: \(parseError.localizedDescription)")
    }
}
