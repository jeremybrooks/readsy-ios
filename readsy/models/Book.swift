//
//  Book.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/24/24.
//

import Foundation
import SwiftUI

@Observable
class Book: Identifiable, Hashable, Codable, Comparable {

    private enum CodingKeys: String, CodingKey {
        case shortTitle
        case title
        case validYear
        case statusFlags
        case version
        case author
        case readingStartDate
        case readingEndDate
    }

    /// Defines which page the user is requesting to navigate to.
    enum PageNavigation {
        case previous
        case next
        case today
        case firstUnread
    }

    // These are the properties that come from the book.json file
    let shortTitle: String
    let title: String
    let validYear: Int
    var statusFlags: String
    let version: String
    let author: String

    var readingStartDate: String
    var readingEndDate: String
    
    /// The readingStartDate as a Date value.
    ///
    /// Used by the BookInfoView to allow the user to change the date. When the user changes the date, the yyyy-MM-dd
    /// values of readingStartDate and readingEndDate will be set, the book will be saved, and the reading status will be recalculated.
    var startDate: Date {
        get {
            return try! Date(readingStartDate, strategy: Formatters.shortISOFormatter)
        }
        set {
            pageDate = Calendar.current.startOfDay(for: newValue)
            readingStartDate = newValue.formatted(Formatters.shortISOFormatter)
            var end = Calendar.current.date(byAdding: .year, value: 1, to: newValue)!
            end = Calendar.current.date(byAdding: .day, value: -1, to: end)!
            readingEndDate = end.formatted(Formatters.shortISOFormatter)
            page = DataManager.shared.getPage(forBook: self)
            calculateReadingStatus()
            try? DataManager.shared.save(book: self)
        }
    }
    
    /// The reading end date as a Date value.
    var endDate: Date {
        get {
            return try! Date(readingEndDate, strategy: Formatters.shortISOFormatter)
        }
    }

    /// Tracks the date the book was loaded.
    ///
    /// This is used to reload the library when the day changes, but keep the same book objects in the library
    /// when the app moves to the background on the same day.
    var loadedDate: Date
    
    /// Unique ID will change each time the book object is created.
    let id = UUID()

    var pageDate: Date = Calendar.current.startOfDay(for: .now)
    
    /// The page content to display for the book. Based on the pageDate.
    var page = Page()
    
    /// The URL that the book was loaded from.
    var bookDirectoryURL: URL?
    
    /// An object that has data which can be shown as a graph, and the current read/missing/future counts for the book
    var readingStatus: ReadingStatus = ReadingStatus()
    
    /// The URL to the "cover.png" file in the book directory.
    var coverURL: String?

    // used to signal the View using this book that there was an error
    var errorState = false
    var errorTitle = ""
    var errorText = ""

    /// Computed property that indicates if the page number for the current pageDate is read.
    ///
    /// If the book is not valid, this will return false, since pages for invalid books do not exist.
    var currentPageIsRead: Bool {
        get {
            let dayOfReadingYear = getDayOfReadingYear(forDate: pageDate)
            return isBookValid()
                && isPageRead(forDayOfYear: dayOfReadingYear)
        }
        set {
            // if the user has navigated to a date that is not valid for the book,
            // don't let them toggle the "read' status
            if isBookValid() {
                togglePageRead(
                    forDayOfReadingYear: getDayOfReadingYear(forDate: pageDate))
                calculateReadingStatus()
                try? DataManager.shared.save(book: self)
            }
        }
    }


    /// A computed property that displays a human readable message indicating when the book is valid.
    var validYearDescription: String {
        return validYear == 0
            ? "Valid for any year" : "Valid for the year \(validYear)"
    }

    /// A computed property that displays a human readable message about the book version.
    var versionDescription: String {
        return "Version \(version)"
    }

    /// A computed property that displays human readable message summarizing the current reading status.
    var readingStatusDescription: String {
        if isBookValid() {
            switch readingStatus.missing {
            case 0:
                if readingStatus.future == 0 {
                    return "You have finished the book!"
                } else {
                    return "You are all up to date!"
                }
            case 1:
                return "You have 1 page to read."
            default:
                return "You have \(readingStatus.missing) pages to read."
            }
        } else {
            return validYearDescription
        }
    }
    

    /// Determine if the book is valid for the current year.
    ///
    /// A book is valid if the validYear parameter is 0 (meaning any year), or if the validYear matches the current year.
    /// - Returns: True if the book is valid, false otherwise.
    func isBookValid() -> Bool {
        return validYear == 0
            || validYear
                == Calendar(identifier: .gregorian)
                .dateComponents(
                    [.year], from: pageDate
                ).year
    }
    
    func isPageDateInReadingRange () -> Bool {
        let validRange = startDate...endDate
        return validRange.contains(pageDate)
    }

    /// Get the ordinal day of the year for the given date. For example, January 1 should return 1.
    /// - Parameter aDate: The date to get the day number for.
    /// - Returns: The day number corresponding to the given date.
    private func getDayOfCalendarYear(forDate aDate: Date) -> Int {
        return Calendar.current.ordinality(
            of: .day, in: .year, for: aDate)!
    }
    
    /// Get the ordinal day of the reading year for the given date.
    ///
    /// This is the day of the reading year, that is, the year beginning on the date the book reading started.
    /// If a book was started on February 1st, and the date passed in is February 3rd, this will return 3.
    /// - Parameter aDate: The date to get the day number for.
    /// - Returns: The day number in the reading year corresponding to the given date.
    func getDayOfReadingYear(forDate aDate: Date) -> Int {
        let readingStartDay = getDayOfCalendarYear(forDate: try! Date(readingStartDate, strategy: Formatters.shortISOFormatter))
        let dayOfCalendarYear = getDayOfCalendarYear(forDate: aDate)
        var dayOfReadingYear: Int
        if Calendar.current.isDate(aDate, equalTo: startDate, toGranularity: .year) {
            dayOfReadingYear = dayOfCalendarYear - readingStartDay
        } else {
            // year has wrapped around
            // so calculate days from reading start date to end of that year
            let year = Calendar.current.component(.year, from: startDate)
            let endOfYear = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31))!
            dayOfReadingYear = getDayOfCalendarYear(forDate: endOfYear) - readingStartDay
            
            // now add days of the next year
            dayOfReadingYear += dayOfCalendarYear
        }
        
        return dayOfReadingYear + 1
    }
    
    /// Determine if the page for the day number has been read.
    /// - Parameter day: The day number to look up.
    /// - Returns: True if the page for the day number has been read, false if not.
    private func isPageRead(forDayOfYear day: Int) -> Bool {
        // Determine the byte index and bit position
        let byteIndex = (day - 1) / 8
        let bitPosition = (day - 1) % 8
        let mask = UInt8(Int(pow(2.0, Double(bitPosition))))

        // Extract the relevant data
        let startOffset = (byteIndex) * 2
        let startIndex = statusFlags.index(
            statusFlags.startIndex, offsetBy: startOffset)
        let endIndex = statusFlags.index(
            statusFlags.startIndex, offsetBy: startOffset + 2)
        let hex = statusFlags[startIndex..<endIndex]

        // convert data to a byte and apply mask with logical AND, compare for equality
        // if the byte can't be created from the hex chars, return false
        guard let byte = UInt8(hex, radix: 16) else {
            return false
        }
        return (byte & mask) == mask
    }

    /// Reset the reading status.
    ///
    /// This method sets the statusFlags to an unread state, then calls self.calculateReadingStatus() and DataManager.save.
    /// Any errors from the save operation will be reported to the user by setting the errorState field to true.
    func resetReadStatus() {
        statusFlags = AppConstants.nothingRead
        calculateReadingStatus()
        do {
            try DataManager.shared.save(book: self)
        } catch {
            errorTitle = "Save Error"
            errorText =
                "There was an error while trying to save the reading status.\n\(error)"
            errorState = true
        }
    }

    /// Mark days previous to today as read. The current day will not be changed.
    ///
    /// This method changes the value of the statusFlags for all days previous to today to read, then calls self.calculateReadingStatus()
    /// and DataManager.save.
    /// Any errors from the save operation will be reported to the user by setting the errorState field to true.
    func markPreviousDaysAsRead() {
        for day in 1..<getDayOfReadingYear(forDate: .now) {
            if !isPageRead(forDayOfYear: day) {
                togglePageRead(forDayOfReadingYear: day)
            }
        }
        calculateReadingStatus()
        do {
            try DataManager.shared.save(book: self)
        } catch {
            errorTitle = "Save Error"
            errorText =
                "There was an error while trying to save the reading status.\n\(error)"
            errorState = true
        }
    }

    /// Navigate to a new page based on the provided navigation parameter.
    ///
    /// This will change the value of the pageDate parameter for this book, then load the page data for that date.
    /// - Parameter navigation: Where to navigate.
    func turnPageTo(_ navigation: PageNavigation) {
        var newDate: Date?
        switch navigation {
        case .today:
            newDate = .now
        case .previous:
            newDate = Calendar.current.date(
                byAdding: .day, value: -1, to: pageDate)
        case .next:
            newDate = Calendar.current.date(
                byAdding: .day, value: 1, to: pageDate)
        case .firstUnread:
            newDate = findFirstUnreadDate()
        }
        if newDate != nil {
            pageDate = Calendar.current.startOfDay(for: newDate!)
            page = DataManager.shared.getPage(forBook: self)
        }
    }

    /// Calculate the reading status based on the statusFlags.
    ///
    /// This method should be called after any operation that changes the statusFlags.
    func calculateReadingStatus() {
        if isBookValid() {
            var read = 0
            var missing = 0
            var future = 0

            // number of days in the current year
            let daysInYear = daysInReadingYear()
            //                Calendar.current.component(.year, from: .now))
            let dayOfReadingYear = getDayOfReadingYear(forDate: .now)

            // find number of read and missing days from day 1 to current day of reading year
            for day in 1...dayOfReadingYear {
                if isPageRead(forDayOfYear: day) {
                    read += 1
                } else {
                    missing += 1
                }
            }

            // if there are any days left in the year,
            // now find the number of read and unread days from today to end of year
            if dayOfReadingYear < daysInYear {
                for day in (dayOfReadingYear + 1)...daysInYear {
                    if isPageRead(forDayOfYear: day) {
                        read += 1
                    } else {
                        future += 1
                    }
                }
            }
            let segments = [
                ChartSegment(
                    label: "Read", value: read, color: .green,
                    percentage: Double(read) / Double(daysInYear) * 100),
                ChartSegment(
                    label: "Unread", value: missing, color: .red,
                    percentage: Double(missing) / Double(daysInYear) * 100),
                ChartSegment(
                    label: "Future", value: future, color: .blue,
                    percentage: Double(future) / Double(daysInYear) * 100),
            ]

            readingStatus = ReadingStatus(
                segments: segments, read: read, future: future, missing: missing
            )
        } else {
            readingStatus = ReadingStatus()
        }

    }

    /// Calculate the number of days in the reading year.
    ///
    /// The reading year begins on readingStartDate and ends a year later on readingEndDate. This method will
    /// count the number of days in this period, including the start and end days. The number of days is calculated
    /// here so that leap years are handled correctly.
    /// - Returns: THe number of days in the reading year.
    func daysInReadingYear() -> Int {
        var days = 0
        do {
            let from = try Date(
                readingStartDate, strategy: Formatters.shortISOFormatter)
            let to = try Date(
                readingEndDate, strategy: Formatters.shortISOFormatter)

            let fromDate = Calendar.current.startOfDay(for: from)
            let toDate = Calendar.current.startOfDay(for: to)
            let numberOfDays = Calendar.current.dateComponents(
                [.day], from: fromDate, to: toDate)
            days = numberOfDays.day! + 1
        } catch {
            days = 0
        }
        return days
    }

    private func findFirstUnreadDate() -> Date? {
        var firstUnread: Date?
        if isBookValid(),
            let readingStartDate = try? Date(
                readingStartDate, strategy: Formatters.shortISOFormatter)
        {
            for day in 1...daysInReadingYear() {
                if !isPageRead(forDayOfYear: day) {
                    firstUnread = Calendar.current.date(
                        byAdding: .day, value: day - 1, to: readingStartDate)
                    break
                }
            }
        }
        return firstUnread
    }

    private func togglePageRead(forDayOfReadingYear day: Int) {
        // Determine the byte index and bit position
        let byteIndex = (day - 1) / 8
        let bitPosition = (day - 1) % 8
        let mask = UInt8(Int(pow(2.0, Double(bitPosition))))

        // Extract the relevant data
        let startOffset = (byteIndex) * 2
        let startIndex = statusFlags.index(
            statusFlags.startIndex, offsetBy: startOffset)
        let endIndex = statusFlags.index(
            statusFlags.startIndex, offsetBy: startOffset + 2)
        let hex = statusFlags[startIndex..<endIndex]

        let byte = UInt8(hex, radix: 16)!  //todo throw?

        let newByte = byte ^ mask

        let newByteHex = String(newByte, radix: 16)
        let paddedString = pad(string: newByteHex, toLength: 2)

        statusFlags.replaceSubrange(
            startIndex..<endIndex, with: paddedString)
    }

    private func pad(string: String, toLength: Int) -> String {
        var padded = string
        for _ in 0..<(toLength - string.count) {
            padded = "0" + padded
        }
        return padded
    }

    /* IMPLEMENT PROTOCOLS */

    // Codable
    required init(from decoder: Decoder) throws {
        loadedDate = Calendar.current.startOfDay(for: Date())
        
        let container = try decoder.container(keyedBy: CodingKeys.self)

        shortTitle = try container.decode(String.self, forKey: .shortTitle)
        title = try container.decode(String.self, forKey: .title)
        validYear = try container.decode(Int.self, forKey: .validYear)
        statusFlags = try container.decode(String.self, forKey: .statusFlags)
        version = try container.decode(String.self, forKey: .version)
        author = try container.decode(String.self, forKey: .author)

        // books won't have official start/end dates until the install process finishes,
        // so provide sane defaults when first decoding the json data.
        // this is easier than making the values optionals and checking for nil
        // every time we want to use them
        if container.contains(.readingStartDate) {
            readingStartDate = try container.decode(String.self, forKey: .readingStartDate)
        } else {
            let year = Calendar.current.component(.year, from: .now)
            readingStartDate = "\(year)-01-01"
        }
        
        if container.contains(.readingEndDate) {
            readingEndDate = try container.decode(String.self, forKey: .readingEndDate)
        } else {
            let year = Calendar.current.component(.year, from: .now)
            readingEndDate = "\(year)-12-31"
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(shortTitle, forKey: .shortTitle)
        try container.encode(title, forKey: .title)
        try container.encode(validYear, forKey: .validYear)
        try container.encode(statusFlags, forKey: .statusFlags)
        try container.encode(version, forKey: .version)
        try container.encode(author, forKey: .author)
        try container.encode(readingStartDate, forKey: .readingStartDate)
        try container.encode(readingEndDate, forKey: .readingEndDate)
    }

    /// Implement Equatable protocol
    ///
    /// Books are equal if:
    /// * The titles match
    /// * The short titles match
    /// * The authors match
    /// * The status flags match
    /// * The loaded dates match
    /// - Parameters:
    ///   - lhs: Left hand side to compare.
    ///   - rhs: Right hand side to compare.
    /// - Returns: True if the id parameters are equal.
    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.title == rhs.title &&
        lhs.shortTitle == rhs.shortTitle &&
        lhs.author == rhs.author &&
        lhs.statusFlags == rhs.statusFlags &&
        lhs.loadedDate == rhs.loadedDate
    }

    /// Implement Hashable protocol.
    ///
    /// The hash is based on the id property.
    ///
    /// - Parameter hasher: The hasher to use for computing the hash.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Implement the Comparable protocol.
    ///
    /// The title parameter is used for comparison, resulting in an alphabetic sort by title.
    /// - Parameters:
    ///   - lhs: Left hand side to compare.
    ///   - rhs: Right hand side to compare.
    /// - Returns: True if left hand side is less than right hand side.
    static func < (lhs: Book, rhs: Book) -> Bool {
        lhs.title < rhs.title
    }
}
