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
    
    func parse(url: URL) async {
        await withCheckedContinuation { continuation in
            guard let parser = XMLParser(contentsOf: url) else {
                continuation.resume()
                return
            }
            parser.delegate = self
            if !parser.parse() {
                continuation.resume()
            } else {
                continuation.resume()
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempValue += string
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            if let id = attributeDict["id"], let href = attributeDict["href"] {
                manifest[id] = href
            }
        } else if elementName == "itemref" {
            if let idref = attributeDict["idref"] {
                spine.append(idref)
            }
        } else if elementName == "meta", let name = attributeDict["name"], name == "cover" {
            coverItemID = attributeDict["content"]
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if currentElement == "dc:title" {
            metadata["title"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if currentElement == "dc:creator" {
            metadata["creator"] = tempValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        tempValue = ""
    }
}
