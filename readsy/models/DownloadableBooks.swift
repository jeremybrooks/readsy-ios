//
//  DownloadableBooks.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/30/24.
//

import Foundation

struct DownloadableBooks: Codable {
    
    var books: [DownloadableBook] = []
    
    struct DownloadableBook: Codable, Identifiable {
        
        private enum CodingKeys: String, CodingKey {
            case title
            case author
            case bookURL
            case coverURL
            case description
        }
        
        let id = UUID()
        let title: String
        let author: String
        let bookURL: URL
        let coverURL: URL
        let description: String
        
        var installing = false
    }
}
