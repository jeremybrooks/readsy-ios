//
//  BookRow.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/7/24.
//

import SwiftUI

struct BookRow: View {
    let book: Book

    var body: some View {
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

            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .italic()
                Text(book.author)
                    .font(.subheadline)
                Text(book.readingStatusDescription)
                    .font(.footnote)
            }
            Spacer()
        }
    }
}

#Preview {
    let data = """
        {"shortTitle":"warandpeace","version":"2","validYear":0,"title":"War and Peace (Project Gutenberg)","author":"Leo Tolstoy","statusFlags":"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
        """.data(using: .utf8)!
        BookRow(book: try! JSONDecoder().decode(Book.self, from: data))
}
