//
//  BookInfoTopSection.swift
//  readsy
//
//  Created by Jeremy Brooks on 1/2/25.
//

import SwiftUI

struct BookInfoTopSection: View {
    var book: Book
    var body: some View {
        VStack {
            HStack {
                if book.coverURL == nil {
                    Image("Cover")
                        .frame(width: 100, height: 100)
                        .scaledToFit()
                } else {
                    AsyncImage(url: URL(string: book.coverURL!)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)
                    .scaledToFit()
                }
                VStack {
                    Text(book.title)
                        .font(.headline)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(book.author)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(book.validYearDescription)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(book.versionDescription)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    let data = """
        {"shortTitle":"warandpeace","version":"2","validYear":0,"title":"War and Peace (Project Gutenberg)","author":"Leo Tolstoy","statusFlags":"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","readingStartDate":"2024-01-01","readingEndDate":"2024-12-31"}
        """.data(using: .utf8)!
        BookInfoTopSection(book: try! JSONDecoder().decode(Book.self, from: data))
}
