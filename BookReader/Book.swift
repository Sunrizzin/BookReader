//
//  Book.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import Foundation
import UIKit

struct Book {
    var title: String
    var author: String
    var chapters: [Chapter]
    var baseURL: URL?
    var coverImage: UIImage?
}

struct Chapter {
    var title: String
    var content: String
    var baseURL: URL
}
