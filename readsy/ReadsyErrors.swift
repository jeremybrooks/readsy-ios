//
//  ReadsyErrors.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/26/24.
//

import Foundation

enum ReadsyErrors: Error {
    case iCloudNotAvailable
    case wrongFileType
    case errorReadingData
    case noBooksFound
    case multipleBooksFound
    case bookExists
}

extension ReadsyErrors: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return NSLocalizedString(
                "Could not access iCloud.", comment: "Could not access iCloud")
        case .wrongFileType:
            return NSLocalizedString(
                "Wrong file type: File does not end with .readsy extension.",
                comment: "Wrong file type")
        case .errorReadingData:
            return NSLocalizedString(
                "Error reading data from file.", comment: "Error reading data")

        case .noBooksFound:
            return NSLocalizedString(
                "No books were found in the data. The data must contain a book.info file.",
                comment: "No books found")

        case .multipleBooksFound:
            return NSLocalizedString(
                "Multiple books were found in the data. The data must contain only a single book.info file.",
                comment: "Multiple books found")
            
        case .bookExists:
            return NSLocalizedString(
                "The book is already installed in your library. If you want to install it again, delete it from your library first.",
                comment: "Book already installed")
        }
    }

}
