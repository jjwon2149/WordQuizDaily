//
//  WordQuizWidget.swift
//  WordQuizWidget
//
//  Created by 정종원 on 3/7/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WordQuizWidgetEntryView : View {
    var entry: Provider.Entry
        
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
                
        let customUserDefaults = UserDefaults(suiteName: "group.wordQuizWidget")

        
        switch self.family {
            
        case .systemSmall:
            VStack{
                if let storedWord = customUserDefaults?.string(forKey: "TodayWord"),
                   let storedDefinition = customUserDefaults?.string(forKey: "TodayWordDefinition") {
                    
                    Spacer()

                    
                    Text(storedWord)
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    Text(storedDefinition)
                        .font(.footnote)
                    
                    Spacer()
                    
                    
                } else {
                    let _ = print("Nothing Printed")
                }
            }
            
        case .systemMedium:
            VStack{
                if let storedWord = customUserDefaults?.string(forKey: "TodayWord"),
                   let storedDefinition = customUserDefaults?.string(forKey: "TodayWordDefinition") {
                    
                    Spacer()

                    Text(storedWord)
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    Text(storedDefinition)
                        .font(.footnote)

                    
                    Spacer()
                    
                    
                } else {
                    let _ = print("Nothing Printed")
                }
            }
            
        default:
            Text(".default")
            
        }

        }
}

struct WordQuizWidget: Widget {
    let kind: String = "WordQuizWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WordQuizWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                    
            } else {
                WordQuizWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("WordQuizDaily Widget")
        .description("문해력을 높여주는 하루 한단어")
        .supportedFamilies([.systemSmall,
                            .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WordQuizWidget()
} timeline: {
    SimpleEntry(date: .now)
}
