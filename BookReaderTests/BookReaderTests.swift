//
//  BookReaderTests.swift
//  BookReaderTests
//
//  Created by Sunrizz on 27.09.2024.
//

import XCTest
@testable import BookReader

final class BookReaderTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func loadTestNCXFile(named fileName: String) -> URL? {
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "ncx") else {
            XCTFail("Не удалось найти файл \(fileName).ncx в тестовом бандле")
            return nil
        }
        return fileURL
    }
    
    func testSimpleNCXFile() async {
        guard let testFileURL = loadTestNCXFile(named: "tocs") else { return }
        
        let parser = NCXParser()
        await parser.parse(url: testFileURL)
        
        let toc = parser.flattenTOC()
        
        for item in toc {
            print(item)
        }
        
        // Проверяем количество пунктов оглавления
//        XCTAssertEqual(toc.count, 2, "Ожидалось 2 главы")
//        
//        // Проверяем первую главу
//        let firstChapter = toc[0]
//        XCTAssertEqual(firstChapter.label, "Chapter 1")
//        XCTAssertEqual(firstChapter.contentSrc, "ch01.html")
//        XCTAssertEqual(firstChapter.playOrder, 1)
//        
//        // Проверяем вторую главу
//        let secondChapter = toc[1]
//        XCTAssertEqual(secondChapter.label, "Chapter 2")
//        XCTAssertEqual(secondChapter.contentSrc, "ch02.html")
//        XCTAssertEqual(secondChapter.playOrder, 2)
    }
    
//    func testNestedNCXFile() async {
//        guard let testFileURL = loadTestNCXFile(named: "toc") else { return }
//        
//        let parser = NCXParser()
//        await parser.parse(url: testFileURL)
//        
//        let toc = parser.flattenTOC()
//        
//        // Проверяем общее количество пунктов оглавления
//        XCTAssertEqual(toc.count, 4, "Ожидалось 4 главы")
//        
//        // Проверяем структуру оглавления
//        let firstChapter = toc[0]
//        XCTAssertEqual(firstChapter.label, "Introduction")
//        XCTAssertEqual(firstChapter.playOrder, 1)
//        
//        let secondChapter = toc[1]
//        XCTAssertEqual(secondChapter.label, "Chapter 1")
//        XCTAssertEqual(secondChapter.playOrder, 2)
//        
//        let thirdChapter = toc[2]
//        XCTAssertEqual(thirdChapter.label, "Chapter 2")
//        XCTAssertEqual(thirdChapter.playOrder, 4)
//    }
}
