//
//  BookView.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/7/24.
//

import SwiftUI

struct BookView: View {

    @Bindable var book: Book

    var body: some View {
        VStack {
            if book.isBookValid() && book.isPageDateInReadingRange() {
                Text(book.pageDate.formatted(date: .complete, time: .omitted) +
                     " - Day \(book.getDayOfReadingYear(forDate: book.pageDate))/\(book.daysInReadingYear())")
                    .font(.headline)
            } else {
                Text(book.pageDate.formatted(date: .complete, time: .omitted))
                    .font(.headline)
            }
            
            Text(book.page.heading)
                .italic()
                .padding([.top])
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                Text(book.page.text)
                    .padding([.top])
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            HStack {
                Toggle("Read", isOn: $book.currentPageIsRead)
                    .fixedSize()
                    .disabled(!book.isBookValid() ||  !book.isPageDateInReadingRange())
                Spacer()
                Menu {
                    Button("Previous Day") {
                        book.turnPageTo(.previous)
                    }
                    Button("Today") {
                        book.turnPageTo(.today)
                    }
                    Button("Next Day") {
                        book.turnPageTo(.next)
                    }
                    if book.isBookValid() {
                        Button("First Unread") {
                            book.turnPageTo(.firstUnread)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
        }
        .alert(book.errorTitle, isPresented: $book.errorState) {
        } message: {
            Text(book.errorText)
        }

        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    let data = """
        {"shortTitle":"warandpeace","version":"2","validYear":0,"title":"War and Peace (Project Gutenberg)","author":"Leo Tolstoy","statusFlags":"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
        """.data(using: .utf8)!
    NavigationView {
        BookView(book: try! JSONDecoder().decode(Book.self, from: data))
    }
}
