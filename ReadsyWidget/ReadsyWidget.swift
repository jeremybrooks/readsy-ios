//
//  ReadsyWidget.swift
//  ReadsyWidget
//
//  Created by Jeremy Brooks on 12/21/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> ReadsyTimelineEntry {
        ReadsyTimelineEntry(
            date: .now,
            status: "Read something new every day.",
            emoji: AppConstants.readingUnknownEmoji,
            bookCount: -1,
            unreadPageCount: -1,
            caughtUpCount: -1
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ReadsyTimelineEntry) -> ()) {
        let entry = ReadsyTimelineEntry(
            date: .now,
            status: "Reading status unknown.",
            emoji: AppConstants.readingUnknownEmoji,
            bookCount: -1,
            unreadPageCount: -1,
            caughtUpCount: -1)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ReadsyTimelineEntry] = []
        
        let defaults = UserDefaults(suiteName: AppConstants.groupUserDefaultsIdentifier)
        
        
        let unreadPageCount = defaults?.integer(forKey: GroupDefaultsKeys.unreadPageCount) ?? -1
        let readingStatusIcons = defaults?.string(forKey: GroupDefaultsKeys.readingStatusIcons) ?? AppConstants.readingUnknownEmoji
        let bookCount = defaults?.integer(forKey: GroupDefaultsKeys.bookCount) ?? 0
        let caughtUpBookCount = defaults?.integer(forKey: GroupDefaultsKeys.caughtUpBookCount) ?? 0
        
        
        var statusMessage: String = ""
        switch unreadPageCount {
        case -1:
            statusMessage = "Tap to read."
        case 0:
            statusMessage = "You are all up to date!"
        case 1:
            statusMessage = "You have 1 page to read."
        default:
            statusMessage = "You have \(unreadPageCount) pages to read."
        }
        
        
        // first timeline entry is status for date "now"
        entries.append(ReadsyTimelineEntry(
            date: .now,
            status: statusMessage,
            emoji: readingStatusIcons,
            bookCount: bookCount,
            unreadPageCount: unreadPageCount,
            caughtUpCount: caughtUpBookCount));
        
        
        // next timeline entry is for midnight
        var nextDayEmoji = ""
        if (bookCount > 0) {
            for _ in 1...bookCount {
                nextDayEmoji.append(AppConstants.readingNotCompleteEmoji)
            }
        } else {
            nextDayEmoji = AppConstants.readingUnknownEmoji
        }
        
        // tomorrow at midnight is one day added to the start of day
        // for the current date
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
        
        print(tomorrow)
        entries.append(ReadsyTimelineEntry(
            date: tomorrow,
            status: "It's a new day. Time to read!",
            emoji: nextDayEmoji,
            bookCount: bookCount,
            unreadPageCount: -1,
            caughtUpCount: 0))
        
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
    
    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}

struct ReadsyTimelineEntry: TimelineEntry {
    let date: Date
    let status: String
    let emoji: String
    let bookCount: Int
    let unreadPageCount: Int
    let caughtUpCount: Int
}

struct ReadsyWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        // check for bookCount == 0 here to avoid divide by zero
        // errors when calculating the value of the gauge
        let gaugeValue = entry.bookCount == 0 ? 0.0 : Double(entry.caughtUpCount) / Double(entry.bookCount)
        
        switch family {
        case .accessoryCircular:
            VStack {
                Gauge(value: gaugeValue) {
                    Image(systemName: "book")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.green)
            }
        case .accessoryRectangular:
            HStack {
                Gauge(value: gaugeValue) {
                    Image(systemName: "book")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.green)
                VStack {
                    Text(entry.emoji)
                        .font(.footnote)
                    if (entry.unreadPageCount == 1) {
                        Text("1 page")
                            .font(.footnote)
                    } else if (entry.unreadPageCount > 1) {
                        Text("\(entry.unreadPageCount) pages")
                            .font(.footnote)
                    }
                }
            }
        case .accessoryInline:
            VStack {
                if (entry.unreadPageCount > 0) {
                    Text("\(entry.emoji)(\(entry.unreadPageCount))")
                } else {
                    Text("\(entry.emoji)")
                }
            }
            
        case .systemSmall:
            VStack {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .multilineTextAlignment(.center)
                    .bold()
                    .padding(.bottom, 2)
                Text(entry.emoji)
                    .font(.title)
                    .padding(.bottom, 2)
                Text(entry.status)
                    .multilineTextAlignment(.leading)
            }
        case .systemMedium:
            HStack {
                Gauge(value: gaugeValue) {
                    Image(systemName: "book")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.green)
                .padding(5)
                
                VStack {
                    Text(entry.date.formatted(date: .long, time: .omitted))
                        .multilineTextAlignment(.center)
                        .bold()
                        .padding(.bottom, 2)
                    Text(entry.emoji)
                        .font(.title)
                        .padding(.bottom, 2)
                    Text(entry.status)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 2)
                }
            }
        default: // .systemLarge and .systemExtraLarge
            VStack {
                HStack {
                    Gauge(value: gaugeValue) {
                        Image(systemName: "book")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.green)
                    .padding(.bottom, 20)
                }
                
                VStack {
                    Text(entry.date.formatted(date: .complete, time: .omitted))
                        .multilineTextAlignment(.center)
                        .bold()
                        .padding(5)
                    Text(entry.emoji)
                        .font(.title)
                        .padding(5)
                    Text(entry.status)
                        .multilineTextAlignment(.leading)
                        .padding(5)
                }
                
            }
        }
    }
}

struct ReadsyWidget: Widget {
    let kind: String = "ReadsyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ReadsyWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ReadsyWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Readsy Widget")
        .description("Shows your Readsy reading status.")
        .supportedFamilies([.accessoryCircular,
                            .accessoryRectangular,
                            .accessoryInline,
                            .systemSmall,
                            .systemMedium,
                            .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    ReadsyWidget()
} timeline: {
    ReadsyTimelineEntry(
        date: .now,
        status: "You have 2 pages to read.",
        emoji: "\(AppConstants.readingCompleteEmoji)\(AppConstants.readingNotCompleteEmoji)\(AppConstants.readingNotCompleteEmoji)",
        bookCount: 3,
        unreadPageCount: 1,
        caughtUpCount: 1
    )
}
