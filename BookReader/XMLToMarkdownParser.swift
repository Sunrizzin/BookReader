import Foundation

class XMLToMarkdownParser: NSObject, XMLParserDelegate {
    private var markdownText = ""
    private var currentLink: String? = nil
    private var insidePreformattedBlock = false
    
    // Функция для парсинга данных XML
    func parse(xmlData: Data) -> String {
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        return markdownText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Начало обработки элемента
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String] = [:]) {
        switch elementName {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            let level = Int(elementName.suffix(1)) ?? 1
            markdownText += String(repeating: "#", count: level) + " "
        case "p":
            markdownText += "\n\n"
        case "strong", "b":
            markdownText += "**"
        case "em", "i":
            markdownText += "_"
        case "code":
            markdownText += insidePreformattedBlock ? "" : "`"
        case "pre":
            markdownText += "\n```\n"
            insidePreformattedBlock = true
        case "blockquote":
            markdownText += "\n> "
        case "a":
            if let href = attributes["href"] {
                markdownText += "["
                currentLink = href
            }
        case "ul":
            markdownText += "\n"
        case "li":
            markdownText += "- "
        case "img":
            if let src = attributes["src"], let alt = attributes["alt"] {
                markdownText += "![\(alt)](\(src))"
            }
        case "div":
            // игнорируем контейнеры <div>
            break
        default:
            break
        }
    }
    
    // Обработка текста внутри элементов
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Заменяем неразрывные пробелы на обычные
        let cleanString = string.replacingOccurrences(of: "&#160;", with: " ")
        markdownText += cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Конец обработки элемента
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        switch elementName {
        case "p", "h1", "h2", "h3", "h4", "h5", "h6":
            markdownText += "\n"
        case "strong", "b":
            markdownText += "**"
        case "em", "i":
            markdownText += "_"
        case "code":
            markdownText += insidePreformattedBlock ? "" : "`"
        case "pre":
            markdownText += "\n```\n"
            insidePreformattedBlock = false
        case "blockquote":
            markdownText += "\n"
        case "a":
            if let currentLink = currentLink {
                markdownText += "](" + currentLink + ")"
            }
            currentLink = nil
        case "li":
            markdownText += "\n"
        default:
            break
        }
    }
}
