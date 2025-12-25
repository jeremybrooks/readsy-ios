//
//  DataManager.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/13/24.
//

import Foundation
import ZIPFoundation

class DataManager {
    /// Shared instance of DataManager.
    static let shared = DataManager()

    /// Lock to prevent multiple threads from loading the library at the same time.
    private let lock = NSLock()

    private init() {}

    /// Load books into the specified library.
    ///
    /// The books array inside the library will be cleared, then the iCloud documents directory will be scanned for
    /// book.json files. A book will be created for each book.json file that is found, that the book will be
    /// added to the library books array.
    ///
    /// The code inside this method uses a lock to prevent multiple threads from trying to load the library at the same time.
    /// This case is rare, but can happen when a user installs a book from a downloaded file.
    /// - Parameter library: The library to load books into.
    /// - Throws: This method will throw ReadsyErrors.iCloudNotAvailable if it cannot get the iCloud container URL, or errors if the json cannot be decoded.
    func loadLibrary(_ library: Library) throws {
        lock.lock()
        defer {
            lock.unlock()
        }
        var newBooks: [Book] = []
        
        if let documentStorageURL = getDocumentStorageURL() {

            let infoFiles = getInfoFilesFrom(directory: documentStorageURL)
            if !infoFiles.isEmpty {
                try infoFiles.forEach { infoFileURL in
                    let book: Book = try readBookFrom(
                        filePath: infoFileURL)
                    newBooks.append(book)
                    // if the new book is NOT in the library, add it
                    if !library.books.contains(book) {
                        book.bookDirectoryURL =
                            infoFileURL.deletingLastPathComponent()
                        book.page = getPage(forBook: book)
                        book.calculateReadingStatus()
                        let coverURL = infoFileURL.deletingLastPathComponent()
                            .appendingPathComponent("cover.png")
                        do {
                            let fileAttributes = try coverURL.resourceValues(
                                forKeys: [.isRegularFileKey])
                            if fileAttributes.isRegularFile! {
                                book.coverURL = coverURL.absoluteString
                            }
                        } catch {
                            book.coverURL = nil
                        }
                        library.books.append(book)
                    }
                }
                // now look for any books in the library that are NOT in the newBooks array
                for book in library.books {
                    if !newBooks.contains(book) {
                        library.books.remove(
                            at: library.books.firstIndex(of: book)!)
                    }
                }
                library.books.sort()
            }
        } else {
            throw ReadsyErrors.iCloudNotAvailable
        }
    }

    /// Get the current page for the specified book.
    ///
    /// This method checks to see that the requested date is in the reading range for the book, ensures that the
    /// book is valid for the page date, then does some checking to properly handle Leap Day and adjust
    /// day indexes when using a book with 365 pages during a 366 day reading year.
    ///
    /// In each of the exceptional cases, or in the case of an error, the returned Page will have a heading and text
    /// that can be displayed so the user knows that there is no content to display for whatever reason.
    /// - Parameter book: The book to load page data for.
    /// - Returns: The Page corresponding to the day specified by the books pageDate field.
    func getPage(forBook book: Book) -> Page {
        // is the page date within the reading start/end dates?
        if !book.isPageDateInReadingRange() {
            return Page(
                heading: "Outside Reading Year",
                text: "The requested date of \(book.pageDate.formatted(date: .long, time: .omitted)) is outside the reading year for this book.\n\nThis book is scheduled to be read from \(book.startDate.formatted(date: .long, time: .omitted)) through \(book.endDate.formatted(date: .long, time: .omitted))."
            )
        }
        
        // Return "no page" if the book is not valid
        if !book.isBookValid() {
            return Page(
                heading: "No Content",
                text: "This book has no page for the requested date.")
        }
        
        var day = book.getDayOfReadingYear(forDate: book.pageDate)

        // If the book is valid for "any year" (validYear == 0) it will have 365 pages. Therefore, if
        // the current reading year has 366 days, we have to do some checking to handle Leap Day, and
        // to adjust the day index after leap day, since we will have one more day than the book has pages.
        if book.validYear == 0 && book.daysInReadingYear() > 365 {
            // If the requested day is leap day (February 29)
            // return a page informing the user that there is no content for leap day.
            if day == 60 {
                return Page(
                    heading: "Leap Day",
                    text:
                        "This book doesn't have a page for Leap Day. Come back tomorrow."
                )
            }
            // if we got this far, the year has more than 365 days, and it's not Leap Day.
            // So, if we are after Leap Day, move the requested day back one to make up
            // for skipping Leap Day.
            if day > 60 {   // days in January plus days in leap February (31 + 29)
                day -= 1
            }
        }

        // Return the data for the page date, or an error if something goes wrong
        var page: Page
        let pageURL = book.bookDirectoryURL!.appendingPathComponent(
            String(day)
                + ".json")
        do {
            let content = try String(
                contentsOf: pageURL, encoding: .utf8)
            let json = content.data(using: .utf8)!
            page = try JSONDecoder().decode(Page.self, from: json)
        } catch {
            page = Page(
                heading: "No Content",
                text:
                    "Unable to find content for the requested page. This may be caused by network errors or a recently added file that has not yet been synced. Please wait a few minutes and try again.\n\n\(error.localizedDescription)"
            )
        }
        return page
    }

    /// Save the specified book by encoding it as JSON and saving the resulting data in the iCloud documents directory.
    /// - Parameter book: The book to save.
    /// - Throws: Errors from the call to JSONEncoder().encode
    func save(book: Book) throws {
        let bookURL = book.bookDirectoryURL!.appendingPathComponent(
            AppConstants.bookMetadataFilename)
        let json = try JSONEncoder().encode(book)
        try json.write(to: bookURL)
    }

    /// Delete the specified book from the iCloud documents directory.
    /// - Parameter book: The book to delete.
    /// - Throws: Any errors from the FileManager removeItem call.
    func delete(book: Book) throws {
        try FileManager.default.removeItem(at: book.bookDirectoryURL!)
    }

    /// Install a book by copying the data from the specified URL to the library.
    ///
    /// If the URL is a local file URL, the data is loaded directly into a Data object. If the URL represents
    /// a remote site, a URLSession object is used to download the data.
    ///
    /// The data from the URL will be copied to a temporary directory and unzipped, and the resulting data
    /// will be scanned for books. If no books are found, or more than one book is found, an error will be
    /// thrown. If the book is created successfully, the book will be unzipped in the iCloud documents directory
    /// and the library will be reloaded to get the new book. The new book will then have the startReadingDate
    /// and endReadingDate properties set, and the book will be saved to persist the new start/end dates.
    ///
    /// - Parameters:
    ///   - url: The path to the book. This can be a local file URL or a remote https URL.
    ///   - library: The library to copy the book to.
    /// - Throws: ReadsyErrors.wrongFileType, ReadsyErrors.errorReadingData, ReadsyErrors.noBookFound, ReadsyErrors.multipleBooksFound, ReadsyErrors.bookExists, Error
    func installBook(url: URL, toLibrary library: Library) async throws {
        guard url.pathExtension == "readsy" else {
            throw ReadsyErrors.wrongFileType
        }
        // fail if iCloud isn't available
        guard let iCloudDirectoryURL = getDocumentStorageURL() else {
            throw ReadsyErrors.iCloudNotAvailable
        }

        // read the data from local file or from remote server
        var data: Data?
        if url.isFileURL {
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw ReadsyErrors.errorReadingData
            }
        } else {
            let result = try await URLSession.shared.data(
                from: url, delegate: nil)
            data = result.0
        }

        // create temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let tempDirURL = try FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: tempDir,
            create: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirURL)
        }

        // copy data to a temp file in the temp directory, then unzip it
        let tempBookURL = tempDirURL.appendingPathComponent("book.readsy")
        FileManager.default.createFile(
            atPath: tempBookURL.path, contents: data, attributes: nil)
        try FileManager().unzipItem(at: tempBookURL, to: tempDirURL)

        // attempt to create a book from the unzipped data
        let infoFiles = getInfoFilesFrom(directory: tempDirURL)
        if infoFiles.isEmpty {
            throw ReadsyErrors.noBooksFound
        } else if infoFiles.count > 1 {
            throw ReadsyErrors.multipleBooksFound
        }
        let testBook = try readBookFrom(filePath: infoFiles.first!)

        // check to see if the book is already installed
        for libraryBook in library.books {
            if libraryBook.shortTitle == testBook.shortTitle {
                throw ReadsyErrors.bookExists
            }
        }

        // book data was valid and does not exist in the library, so unzip the data to the library directory
        try FileManager().unzipItem(at: tempBookURL, to: iCloudDirectoryURL)

        // reload the library to get the new book
        try self.loadLibrary(library)

        // find the newly installed book and set the reading start/end dates
        // load the correct page based on the reading start date
        // then save the book to ensure start/end dates are in the book.json file
        // and recalculate the reading status
        for b in library.books {
            if b.shortTitle == testBook.shortTitle {
                if b.validYear == 0 {
                    let startDate = Date()
                    var endDate = Calendar.current.date(
                        byAdding: .year, value: 1, to: startDate)!
                    endDate = Calendar.current.date(
                        byAdding: .day, value: -1, to: endDate)!
                    b.readingStartDate = startDate.formatted(
                        Formatters.shortISOFormatter)
                    b.readingEndDate = endDate.formatted(
                        Formatters.shortISOFormatter)
                } else {
                    b.readingStartDate = "\(b.validYear)-01-01"
                    b.readingEndDate = "\(b.validYear)-12-31"
                }
                b.page = getPage(forBook: b)
                b.calculateReadingStatus()
                try save(book: b)
                break
            }
        }
    }

    private func getDocumentStorageURL() -> URL? {
        var documentDirectory: URL?
        
        if (UserDefaults.standard.bool(forKey: UserDefaultsKeys.useiCloud)) {
            documentDirectory = FileManager.default.url(
                forUbiquityContainerIdentifier: AppConstants
                    .iCloudContainerIdentifier)
            if documentDirectory != nil {
                documentDirectory = documentDirectory!.appendingPathComponent("Documents")
            }
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            documentDirectory = paths[0]
        }
        return documentDirectory
    }
    

    private func readBookFrom(filePath: URL) throws -> Book {
        let content = try String(contentsOf: filePath, encoding: .utf8)
        let json = content.data(using: .utf8)!
        return try JSONDecoder().decode(Book.self, from: json)
    }

    /*
     * Recursively searches the provided URL to find files named "book.json" and returns an array of URL's for those files.
     */
    private func getInfoFilesFrom(directory: URL) -> [URL] {
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(
            at: directory, includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants])
        {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent
                    == AppConstants.bookMetadataFilename
                {
                    files.append(fileURL)
                }
            }
        }
        return files
    }
}
