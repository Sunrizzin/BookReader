//
//  Book.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation
import UIKit
import Swift
import SwiftData

@Model
class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var chapters: [Chapter]
    var baseURL: URL?
    var coverImageData: Data?
    var css: String?
    
    init(title: String, author: String, chapters: [Chapter], baseURL: URL?, coverImage: UIImage?, css: String?) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.chapters = chapters
        self.baseURL = baseURL
        self.coverImageData = coverImage?.pngData()
        self.css = css
    }
    
    var coverImage: UIImage? {
        if let data = coverImageData {
            return UIImage(data: data)
        }
        return nil
    }
}

@Model
class Chapter {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var baseURL: URL
    
    init(title: String, content: String, baseURL: URL) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.baseURL = baseURL
    }
}
