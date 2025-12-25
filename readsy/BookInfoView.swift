//
//  BookInfoView.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/15/24.
//

import Charts
import SwiftUI

struct BookInfoView: View {
    @Bindable var book: Book
    @State var isMenuVisible: Bool = false
    
    /// The date range to show in the date picker. It allows dates from one year ago to today.
    let dateRange: ClosedRange<Date> = {
        let oneYearAgo = Calendar.current.date(
            byAdding: .year, value: -1, to: Date())!
        return oneYearAgo...Date()
    }()
    
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
            Divider()
            VStack {
                Text("__Start Date:__ \(book.startDate.formatted(date: .complete, time: .omitted))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("__End Date:__ \(book.endDate.formatted(date: .complete, time: .omitted))")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            Spacer()
            ZStack {
                // This stack holds the reading status graph
                if !isMenuVisible {
                    VStack {
                        Text("Reading Status")
                            .font(.title2)
                            .fontWeight(.bold)
                        ZStack(alignment: .center) {
                            VStack {
                                ForEach(
                                    book.readingStatus.segments, id: \.label
                                ) {
                                    data in
                                    let formattedValue = String(
                                        format: "%.1f", data.percentage)
                                    Text("\(formattedValue)% \(data.label)")
                                        .font(.title2)
                                }
                            }
                            Chart(book.readingStatus.segments, id: \.label) {
                                element in
                                SectorMark(
                                    angle: .value("Days", element.value),
                                    innerRadius: .ratio(0.618),
                                    angularInset: 1.0
                                )
                                .cornerRadius(5)
                                .foregroundStyle(
                                    by: .value("Days", element.label))

                            }
                            .chartForegroundStyleScale(
                                range: book.readingStatus.chartColors()
                            )
                            .scaledToFit()
                            .chartLegend(alignment: .center, spacing: 16)

                        }
                    }
                    .transition(
                        AnyTransition.opacity.animation(
                            .easeInOut(duration: 0.5)))
                }

                if isMenuVisible {
                    VStack {
                        Form {
                            Button("Mark Previous Days As Read") {
                                book.markPreviousDaysAsRead()
                                isMenuVisible.toggle()
                            }
                            Button("Reset Reading Status") {
                                book.resetReadStatus()
                                isMenuVisible.toggle()
                            }
                            if book.validYear == 0 {
                                DatePicker(
                                    "Change Start Date", selection: $book.startDate,
                                    in: dateRange, displayedComponents: [.date])
                            }
                        }
                    }
                    .transition(
                        AnyTransition.opacity.animation(
                            .easeInOut(duration: 0.5)))
                }
            }
            Spacer()
            Button {
                isMenuVisible.toggle()
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .navigationTitle("Book Information")
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
        BookInfoView(book: try! JSONDecoder().decode(Book.self, from: data))
    }
}
