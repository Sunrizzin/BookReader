//
//  OPFParserTests.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import XCTest
@testable import BookReader

class OPFParserTests: XCTestCase {
    
    // Метод для загрузки тестового OPF-файла
    func loadTestOPFFile(named fileName: String) -> URL? {
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "opf") else {
            XCTFail("Не удалось найти файл \(fileName).opf в тестовом бандле")
            return nil
        }
        return fileURL
    }
    
    // Тестируем парсинг простого OPF-файла
    func testSimpleOPFFile() async throws {
        guard let testFileURL = loadTestOPFFile(named: "contents") else { return }
        
        let parser = OPFParser()
        try await parser.parse(url: testFileURL)
        
        for item in parser.metadata {
            print(item)
        }
        print("----------")
        for item in parser.subjects {
            print(item)
        }
        print("----------")
        for item in parser.manifest {
            print(item)
        }
        print("----------")
        for item in parser.spine {
            print(item)
        }
        
        // Проверка метаданных
//        XCTAssertEqual(parser.metadata["title"], "Темная материя", "Название книги не совпадает")
//        XCTAssertEqual(parser.metadata["creator"], "Test Author", "Автор не совпадает")
//        XCTAssertEqual(parser.metadata["language"], "ru", "Язык книги не совпадает")
//        XCTAssertEqual(parser.metadata["identifier"], "1234567890", "Идентификатор книги не совпадает")
//        XCTAssertEqual(parser.metadata["publisher"], "Test Publisher", "Издатель книги не совпадает")
        
        // Проверка манифеста
//        XCTAssertNotNil(parser.manifest["item1"], "Отсутствует элемент item1 в манифесте")
//        XCTAssertEqual(parser.manifest["item1"], "text/chapter1.xhtml", "Неправильный путь для item1")
        
        // Проверка spine
//        XCTAssertEqual(parser.spine.count, 1, "Ожидался один элемент в spine")
//        XCTAssertEqual(parser.spine.first, "item1", "Неправильный элемент в spine")
        
        // Проверка обложки
//        XCTAssertEqual(parser.coverItemID, "cover-image", "Неправильный ID обложки")
    }
    
    // Тест на отсутствие обложки в OPF
//    func testOPFWithoutCover() async throws {
//        guard let testFileURL = loadTestOPFFile(named: "content") else { return }
//        
//        let parser = OPFParser()
//        try await parser.parse(url: testFileURL)
//        
//        // Проверка отсутствия обложки
//        XCTAssertNil(parser.coverItemID, "Обложка не должна существовать")
//    }
    
    // Тест на корректную обработку ошибок парсинга
//    func testOPFParsingError() async {
//        // Пробуем загрузить несуществующий OPF-файл
//        let invalidURL = URL(fileURLWithPath: "/invalid/path/to.opf")
//        
//        let parser = OPFParser()
//        do {
//            try await parser.parse(url: invalidURL)
//            XCTFail("Ожидалась ошибка парсинга, но она не произошла")
//        } catch {
//            XCTAssertEqual(error.localizedDescription, "Не удалось создать XMLParser", "Неправильное сообщение об ошибке")
//        }
//    }
}
