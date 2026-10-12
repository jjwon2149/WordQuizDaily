import WidgetKit
import SwiftUI
import LearningCore

struct Provider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.wordQuizWidget")

    func placeholder(in context: Context) -> SimpleEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents)
                ?? calendar.date(byAdding: .day, value: 1, to: now) else {
            completion(Timeline(entries: [entry(for: now)], policy: .atEnd))
            return
        }
        let followingMidnight = calendar.date(byAdding: .day, value: 1, to: nextMidnight) ?? nextMidnight.addingTimeInterval(86_400)
        completion(Timeline(entries: [entry(for: now), entry(for: nextMidnight)], policy: .after(followingMidnight)))
    }

    private func entry(for date: Date) -> SimpleEntry {
        let cache: DailyWordCache? = defaults?.string(forKey: "TodayLearningWordID").flatMap { id in
            defaults?.string(forKey: "TodayLearningWordDate").map { DailyWordCache(wordID: id, dayToken: $0) }
        }
        let selected = DailyWordSelector.select(from: LearningWordCatalog.bundled.words, date: date, calendar: .current, cache: cache)
        return SimpleEntry(date: date, word: selected?.word ?? "—", definition: selected?.easyKoreanDefinition ?? "")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let word: String
    let definition: String
}

struct WordQuizWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            Text(entry.word)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(entry.definition)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}

struct WordQuizWidget: Widget {
    let kind = "WordQuizWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WordQuizWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("WordQuizDaily Widget")
        .description("문해력을 높여주는 하루 한 단어")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WordQuizWidget()
} timeline: {
    SimpleEntry(date: .now, word: "균형", definition: "한쪽으로 치우치지 않고 알맞게 맞는 상태예요.")
}
