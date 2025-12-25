//
//  AddBookView.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/22/24.
//

import SwiftUI

struct AddBookView: View {
    @Environment(\.openURL) var openURL

    var library: Library

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertText = ""

    @State var availableBooks: DownloadableBooks = DownloadableBooks()

    /// Used to disable the UI while a book is being installed
    @State var installRunning = false

    var body: some View {
        VStack {
            Text(
                "Select one of the books listed below to download and install it. More books may be made avialable periodically.\n\nTo learn how to create your own books, visit the [Readsy web site](https://jeremybrooks.net/readsy)."
            )
            .padding()
            List($availableBooks.books) { $book in
                HStack {
                    Button(action: {
                        book.installing = true
                        installRunning = true
                        Task {
                            await installBook(book)
                            book.installing = false
                            installRunning = false
                        }
                    }) {
                        HStack {
                            AsyncImage(url: book.coverURL) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                } else if phase.error != nil {
                                    Image("Cover").resizable()
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 100, height: 100)
                            .scaledToFit()

                            VStack(alignment: .leading) {
                                Text(book.title)
                                    .font(.headline)
                                    .italic()
                                Text(book.author)
                                    .font(.subheadline)
                                Text(book.description)
                                    .font(.footnote)
                                if book.installing {
                                    HStack {
                                        ProgressView()
                                            .transition(.opacity)
                                        Text("Installing...")
                                    }
                                }
                            }
                        }
                    }
                    .disabled(installRunning)
                }
            }
            Spacer()
        }
        .toolbar {
            NavigationLink(destination: {
                AboutView()}) {
                Text("About")
            }
        }
        .navigationTitle("Add Books")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                do {
                    let result = try await URLSession.shared.data(
                        from: AppConstants.bookListDownloadURL!, delegate: nil)
                    availableBooks = try JSONDecoder().decode(
                        DownloadableBooks.self, from: result.0)
                    availableBooks.books.sort { $0.title < $1.title }
                } catch {
                    alertTitle = "Error Getting Book List"
                    alertText = "\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        .alert("\(alertTitle)", isPresented: $showAlert) {
        } message: {
            Text("\(alertText)")
        }
    }

    /// Attempt to install a downloaded book.
    ///
    /// - Parameter book: The book to install.
    func installBook(_ book: DownloadableBooks.DownloadableBook) async {
        do {
            try await DataManager.shared.installBook(
                url: book.bookURL, toLibrary: library)
            alertTitle = "Success"
            alertText =
                "The book \"\(book.title)\" was installed successfully and is now available in your library."
            showAlert = true
        } catch {
            alertTitle = "Error Installing Book"
            alertText =
                "Could not install book \"\(book.title)\". \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    let library = Library()
    NavigationView {
        AddBookView(library: library)
    }
}
