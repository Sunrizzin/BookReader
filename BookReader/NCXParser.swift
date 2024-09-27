//
//  NCXParser.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation
import ZIPFoundation
import SwiftUI
import WebKit

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
