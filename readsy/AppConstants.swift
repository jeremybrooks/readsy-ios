//
//  AppConstants.swift
//
//  Created by Jeremy Brooks on 12/13/24.
//

import Foundation

enum AppConstants {
    
    /// The file that will contain metadata about the book being read.
    static let bookMetadataFilename = "book.json"
    
    /// The identifier for this applications iCloud container.
    static let iCloudContainerIdentifier = "iCloud.net.jeremybrooks.readsy"
    
    /// The URL to the Readsy web site.
    static let readsyWebSiteURL = URL(string: "https://jeremybrooks.net/readsy")
    
    /// The URL to the file containing books available for download.
    static let bookListDownloadURL = readsyWebSiteURL?.appendingPathComponent("books").appendingPathComponent("bookList.json")
    
    /// Status flags representing a book that has not had any pages read.
    static let nothingRead =
    "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    

    static let groupUserDefaultsIdentifier = "group.net.jeremybrooks.readsy"    
    static let readingCompleteEmoji = "🤩"
    static let readingNotCompleteEmoji = "📖"
    static let readingUnknownEmoji = "📚"
}

enum UserDefaultsKeys {
    static let useiCloud = "readsy.useiCloud"
    static let onboardingNeeded = "readsy.onboardingNeeded"
}

enum GroupDefaultsKeys {
    static let readingStatusIcons = "readsy.readingStatusIcons"
    static let bookCount = "readsy.bookCount"
    static let caughtUpBookCount = "readsy.caughtUpCount"
    static let unreadPageCount = "readsy.unreadPageCount"
}

enum Formatters {
    /// Format dates as yyyy-MM-dd, so that January 5, 2024 becomes 2024-01-05.
    static let shortISOFormatter = Date.ISO8601FormatStyle(dateSeparator: .dash, timeZone: TimeZone.current).year().month().day()
    
    /// Format dates as MMdd, so that January 5, 2024 becomes 0105.
    static let mmddFormatter = Date.ISO8601FormatStyle(dateSeparator: .omitted, timeZone: TimeZone.current).month().day()

}
