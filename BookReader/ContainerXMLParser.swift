//
//  ContainerXMLParser.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation

class ContainerXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private(set) var opfPath: String?
    
    func parse(url: URL) async throws -> String? {
        return await withCheckedContinuation { continuation in
            guard let parser = XMLParser(contentsOf: url) else {
                continuation.resume(returning: nil)
                return
            }
            parser.delegate = self
            if parser.parse() {
                continuation.resume(returning: opfPath)
            } else {
                continuation.resume(returning: nil)
            }
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
