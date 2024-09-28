import Foundation

class OPFParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var tempValue = ""
    
    private(set) var metadata: [String: String] = [:]
    private(set) var manifest: [String: String] = [:]
    private(set) var spine: [String] = []
    
    private(set) var subjects: [String] = []
    var coverItemID: String?
    var translator: String?
    
    // Асинхронный метод парсинга с использованием Task.detached
    func parse(url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached { [weak self] in
                guard let self = self else { return }
                
                // Проверка возможности создания XMLParser
                guard let parser = XMLParser(contentsOf: url) else {
                    continuation.resume(throwing: NSError(domain: "OPFParserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать XMLParser"]))
                    return
                }
                
                // Устанавливаем делегат
                parser.delegate = self
                
                // Парсинг файла
                if parser.parse() {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "OPFParserError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка парсинга OPF"]))
                }
            }
        }
    }
    
    // Начало элемента
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        // Обработка элемента item для заполнения манифеста
        if elementName == "item" {
            if let id = attributeDict["id"], let href = attributeDict["href"] {
                manifest[id] = href
            }
        }
        
        // Обработка элемента itemref для заполнения spine
        if elementName == "itemref" {
            if let idref = attributeDict["idref"] {
                spine.append(idref)
            }
        }
        
        // Обработка элемента meta для определения обложки или переводчика
        if elementName == "meta" {
            if let name = attributeDict["name"], name == "cover" {
                coverItemID = attributeDict["content"]
            } else if let name = attributeDict["name"], name == "FB2.book-info.translator" {
                translator = attributeDict["content"]
            }
        }
        
        // Очищаем tempValue для нового элемента
        tempValue = ""
    }
    
    // Найдены символы между открывающим и закрывающим тегами
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Удаляем лишние пробелы и символы новой строки
        tempValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Завершение элемента
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Обрабатываем метаданные
        switch elementName {
        case "dc:title":
            metadata["title"] = tempValue
        case "dc:creator":
            metadata["creator"] = tempValue
        case "dc:language":
            metadata["language"] = tempValue
        case "dc:identifier":
            metadata["identifier"] = tempValue
        case "dc:publisher":
            metadata["publisher"] = tempValue
        case "dc:subject":
            let subject = tempValue
            subjects.append(subject)
        case "dc:date":
            metadata["date"] = tempValue
        case "dc:rights":
            metadata["rights"] = tempValue
        case "dc:description":
            metadata["description"] = tempValue
        default:
            break
        }
        
        // Сбрасываем текущий элемент и временное значение
        currentElement = ""
        tempValue = ""
    }
    
    // Обработка ошибок парсинга
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Ошибка парсинга: \(parseError.localizedDescription)")
    }
}
