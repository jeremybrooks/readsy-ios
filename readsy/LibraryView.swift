//
//  LibraryView.swift
//  readsy
//
//  Created by Jeremy Brooks on 11/27/24.
//

import SwiftUI
import WidgetKit

struct LibraryView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @State private var library = Library()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertText = ""
    @State private var welcome = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationStack {
                    List(library.books) { book in
                        NavigationLink(value: book) {
                            BookRow(book: book)
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            NavigationLink(
                                destination: BookInfoView(book: book)
                            ) {
                                Button {
                                } label: {
                                    Label("Info", systemImage: "info")
                                }
                                .tint(.blue)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                do {
                                    try DataManager.shared.delete(
                                        book: book)
                                    library.books.removeAll(where: {
                                        $0 == book
                                    })
                                } catch {
                                    alertTitle = "Warning"
                                    alertText =
                                    "There was an error while trying to delete the book.\n\(error)"
                                    showAlert = true
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                    }
                    .navigationTitle("Library")
                    .toolbar {
                        NavigationLink("Add Book", value: "Add")
                    }
                    .navigationDestination(for: Book.self) {
                        book in BookView(book: book)
                    }
                    .navigationDestination(for: String.self) {
                        textValue in AddBookView(library: library)
                    }
                }
            }
            .sheet(isPresented: $welcome) {
                WelcomeView(library: library)
            }
        }
        // when transitioning from inactive to active, load the library
        // this handles the case of use launching the app, and the
        // case of the app coming back into view
        //
        // when transitioning from active to inactive, write the
        // group defaults required for widget state data
        // and force a widget reload
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingNeeded) {
                welcome = true
            } else {
                if oldPhase == .inactive && newPhase == .active {
                    Task {
                        do {
                            try DataManager.shared.loadLibrary(library)
                        } catch {
                            alertTitle = "Error"
                            alertText =
                            "Error loading library.\n\(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                } else if (oldPhase == .active && newPhase == .inactive) {
                    let groupDefaults = UserDefaults(suiteName: AppConstants.groupUserDefaultsIdentifier)
                    var validBookCount = 0
                    var unreadPageCount = 0
                    var caughtUpCount = 0
                    var emoji: String = ""
                    for book in library.books {
                        if (book.isBookValid()) {
                            validBookCount += 1
                            if (book.readingStatus.missing == 0) {
                                emoji.append(AppConstants.readingCompleteEmoji);
                                caughtUpCount += 1
                            } else {
                                unreadPageCount += book.readingStatus.missing
                                emoji.append(AppConstants.readingNotCompleteEmoji);
                            }
                        }
                    }
                    groupDefaults?.set(emoji, forKey: GroupDefaultsKeys.readingStatusIcons)
                    groupDefaults?.set(validBookCount, forKey: GroupDefaultsKeys.bookCount)
                    groupDefaults?.set(unreadPageCount, forKey: GroupDefaultsKeys.unreadPageCount)
                    groupDefaults?.set(caughtUpCount, forKey: GroupDefaultsKeys.caughtUpBookCount)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        .onOpenURL { url in
            Task {
                do {
                    try await DataManager.shared.installBook(
                        url: url, toLibrary: library)
                } catch {
                    alertTitle = "Error"
                    alertText =
                    "There was an error while installing the book.\n\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        .alert("\(alertTitle)", isPresented: $showAlert) {
        } message: {
            Text("\(alertText)")
        }
    }
}

#Preview {
    LibraryView()
}
