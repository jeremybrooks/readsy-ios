//
//  BookTest.swift
//  readsyTests
//
//  Created by Jeremy Brooks on 1/24/25.
//

import Testing
import Foundation
@testable import readsy


struct BookTest {
    
    // this book is read during a normal calendar year, during a non leap year
    let book0 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2025-01-01",
            "readingEndDate":"2025-12-31"}
        """
    
    // this book is read during a normal calendar year, during a leap year
    let book1 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2024-01-01",
            "readingEndDate":"2024-12-31"}
        """
    
    @Test func testGetCurrentDayOfReadingYearDayOne() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book0.data(using: .utf8)!)
        let testDate = try Date("2025-01-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }


    @Test func testGetCurrentDayOfReadingYearDay365() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book0.data(using: .utf8)!)
        let testDate = try Date("2025-12-31", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 365)
    }
    
    @Test func testGetCurrentDayOfReadingYearLeapYear() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book1.data(using: .utf8)!)
        let testDate = try Date("2024-12-31", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 366)
    }
    
    // this book starts reading during a non-leap year and ends the next calendar year
    let book2 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2025-03-01",
            "readingEndDate":"2026-02-28"}
        """
    
    @Test func testCurrentReadingDay2_1() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book2.data(using: .utf8)!)
        let testDate = try Date("2025-03-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }


    @Test func testCurrentReadingDay2_2() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book2.data(using: .utf8)!)
        let testDate = try Date("2026-02-28", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 365)
    }
    
    @Test func testCurrentReadingDay2_3() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book2.data(using: .utf8)!)
        let testDate = try Date("2025-04-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 32)
    }
    
    
    
    // This book starts reading in a leap year before leap day, and finishes the next calendar year
    let book3 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2024-02-01",
            "readingEndDate":"2025-01-31"}
        """
    @Test func testCurrentReadingDay3_1() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book3.data(using: .utf8)!)
        let testDate = try Date("2024-02-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }
    
    @Test func testCurrentReadingDay3_2() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book3.data(using: .utf8)!)
        let testDate = try Date("2025-01-31", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 366)
    }
    
    @Test func testCurrentReadingDay3_3() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book3.data(using: .utf8)!)
        let testDate = try Date("2024-03-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 30)
    }
    
    // This book starts reading in a leap year after leap day, and finishes the next calendar year
    let book4 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2024-03-01",
            "readingEndDate":"2025-02-28"}
        """
    @Test func testCurrentReadingDay4_1() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book4.data(using: .utf8)!)
        let testDate = try Date("2024-03-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }
    
    @Test func testCurrentReadingDay4_2() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book4.data(using: .utf8)!)
        let testDate = try Date("2025-02-28", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 365)
    }
    
    @Test func testCurrentReadingDay4_3() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book4.data(using: .utf8)!)
        let testDate = try Date("2024-04-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 32)
    }
    
    // this book starts reading during a non-leap year and ends the next calendar year, which is a leap year, after leap day
    let book5 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2019-04-01",
            "readingEndDate":"2020-03-31"}
        """
    @Test func testCurrentReadingDay5_1() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book5.data(using: .utf8)!)
        let testDate = try Date("2019-04-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }
    
    @Test func testCurrentReadingDay5_2() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book5.data(using: .utf8)!)
        let testDate = try Date("2020-03-31", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 366)
    }
    
    @Test func testCurrentReadingDay5_3() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book5.data(using: .utf8)!)
        let testDate = try Date("2019-05-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 31)
    }
    
    // this book starts reading during a non-leap year and ends the next calendar year, which is a leap year, before leap day
    let book6 = """
        {"shortTitle":"poems1","title":"Poem-a-Day, Volume 1","statusFlags":"0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "validYear":0,"author":"Various Authors","version":"2",
            "readingStartDate":"2019-02-01",
            "readingEndDate":"2020-01-31"}
        """
    @Test func testCurrentReadingDay6_1() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book6.data(using: .utf8)!)
        let testDate = try Date("2019-02-01", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 1)
    }
    
    @Test func testCurrentReadingDay6_2() async throws {
        let book = try! JSONDecoder().decode(Book.self, from: book6.data(using: .utf8)!)
        let testDate = try Date("2020-01-31", strategy: Formatters.shortISOFormatter)
        #expect(book.getDayOfReadingYear(forDate: testDate) == 365)
    }
}
