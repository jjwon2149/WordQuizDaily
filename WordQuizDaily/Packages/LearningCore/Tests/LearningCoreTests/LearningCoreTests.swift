import Foundation
import XCTest
@testable import LearningCore

final class LearningProgressTests: XCTestCase {
    func testReviewLifecycleRequiresTwoCorrectAnswersAndRewrongResetsIt() {
        var progress = LearningProgress()
        progress.record(wordID: "word", isCorrect: false, at: Date(), submissionID: UUID())
        XCTAssertEqual(progress.records["word"]?.needsReview, true)
        XCTAssertEqual(progress.records["word"]?.consecutiveCorrectAfterMistake, 0)
        progress.record(wordID: "word", isCorrect: true, at: Date(), submissionID: UUID())
        XCTAssertEqual(progress.records["word"]?.needsReview, true)
        XCTAssertEqual(progress.records["word"]?.consecutiveCorrectAfterMistake, 1)
        progress.record(wordID: "word", isCorrect: true, at: Date(), submissionID: UUID())
        XCTAssertEqual(progress.records["word"]?.needsReview, false)
        progress.record(wordID: "word", isCorrect: false, at: Date(), submissionID: UUID())
        XCTAssertEqual(progress.records["word"]?.needsReview, true)
        XCTAssertEqual(progress.records["word"]?.consecutiveCorrectAfterMistake, 0)
    }

    func testRecordIsIdempotentAndDailyAnswersCountEventsRatherThanLifetimeWordCount() {
        var progress = LearningProgress()
        var seoul = Calendar(identifier: .gregorian)
        seoul.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let first = date(2026, 9, 30, 23, 55, calendar: seoul)
        let second = date(2026, 10, 1, 0, 5, calendar: seoul)
        let firstID = UUID()

        XCTAssertTrue(progress.record(wordID: "word", isCorrect: false, at: first, submissionID: firstID))
        XCTAssertFalse(progress.record(wordID: "word", isCorrect: true, at: first, submissionID: firstID))
        XCTAssertTrue(progress.record(wordID: "word", isCorrect: true, at: second, submissionID: UUID()))

        XCTAssertEqual(progress.records["word"]?.answerCount, 2)
        XCTAssertEqual(progress.answers(on: first, calendar: seoul), 1)
        XCTAssertEqual(progress.answers(on: second, calendar: seoul), 1)
    }

    func testDailyAnswersHonorQueriedTimeZoneAndDSTBoundary() {
        var progress = LearningProgress()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let beforeSpringForward = date(2026, 3, 8, 1, 59, calendar: losAngeles)
        let afterSpringForward = date(2026, 3, 8, 3, 1, calendar: losAngeles)
        progress.record(wordID: "a", isCorrect: true, at: beforeSpringForward, submissionID: UUID())
        progress.record(wordID: "b", isCorrect: true, at: afterSpringForward, submissionID: UUID())

        XCTAssertEqual(progress.answers(on: afterSpringForward, calendar: losAngeles), 2)
        XCTAssertEqual(progress.answers(on: afterSpringForward, calendar: utc), 2)
    }

    func testReviewOrderUsesWordIDAsStableTimestampTieBreak() {
        let timestamp = Date(timeIntervalSince1970: 100)
        let records = [
            "z": WordLearningRecord(wordID: "z", answerCount: 1, lastLearnedAt: timestamp, needsReview: true),
            "a": WordLearningRecord(wordID: "a", answerCount: 1, lastLearnedAt: timestamp, needsReview: true)
        ]
        let progress = LearningProgress(records: records)
        XCTAssertEqual(progress.reviewWordIDs(validIDs: ["a", "z"]), ["a", "z"])
        XCTAssertEqual(progress.reviewWordIDs(validIDs: ["a", "z"], limit: -1), [])
    }

    func testReviewListLimitsToTenAndSessionKeepsUniqueOrder() {
        let records = Dictionary(uniqueKeysWithValues: (0..<12).map { index in
            let id = String(format: "%02d", index)
            return (id, WordLearningRecord(wordID: id, answerCount: 1, lastLearnedAt: Date(timeIntervalSince1970: Double(index)), needsReview: true))
        })
        let progress = LearningProgress(records: records)
        let ids = progress.reviewWordIDs(validIDs: Set(records.keys))
        XCTAssertEqual(ids.count, 10)
        var session = ReviewSession(wordIDs: ["a", "b", "a", "c"])
        XCTAssertEqual(session.wordIDs, ["a", "b", "c"])
        session.submit(isCorrect: true)
        session.submit(isCorrect: false)
        session.submit(isCorrect: true)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.correctCount, 2)
    }

    func testStorePersistsReloadsAndMigratesVersionOne() throws {
        let location = temporaryDirectory().appendingPathComponent("progress.json")
        let store = LearningRecordStore(fileURL: location)
        var progress = LearningProgress()
        let submissionID = UUID()
        progress.record(wordID: "a", isCorrect: false, at: Date(timeIntervalSince1970: 123), submissionID: submissionID)
        try store.save(progress)
        XCTAssertEqual(try store.load(), progress)

        let v1 = LearningProgress(version: 1, records: progress.records, recordedSubmissionIDs: [submissionID])
        try JSONEncoder().encode(v1).write(to: location, options: .atomic)
        let migrated = try store.load()
        XCTAssertEqual(migrated.version, LearningProgress.currentVersion)
        XCTAssertEqual(migrated.records, progress.records)
        XCTAssertEqual(migrated.recordedSubmissionIDs, [submissionID])
        XCTAssertTrue(migrated.submissionDatesByID.isEmpty)
    }

    func testFutureAlteredSchemaIsPreservedAndBlocksSave() throws {
        let location = temporaryDirectory().appendingPathComponent("progress.json")
        let original = Data(#"{"version":99,"futureRecords":{"different":true}}"#.utf8)
        try original.write(to: location)
        let store = LearningRecordStore(fileURL: location)

        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? LearningRecordStoreError, .unsupportedVersion(99))
        }
        XCTAssertEqual(try Data(contentsOf: location), original)
        XCTAssertThrowsError(try store.save(LearningProgress())) { error in
            XCTAssertEqual(error as? LearningRecordStoreError, .unsupportedVersion(99))
        }
        XCTAssertEqual(try Data(contentsOf: location), original)
    }

    func testInvalidVersionIsPreserved() throws {
        let location = temporaryDirectory().appendingPathComponent("progress.json")
        let original = Data(#"{"version":0}"#.utf8)
        try original.write(to: location)
        let store = LearningRecordStore(fileURL: location)
        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(error as? LearningRecordStoreError, .unsupportedVersion(0))
        }
        XCTAssertEqual(try Data(contentsOf: location), original)
    }

    func testCorruptionIsQuarantinedAndOriginalPathCanThenBeSaved() throws {
        let directory = temporaryDirectory()
        let location = directory.appendingPathComponent("progress.json")
        try Data("not json".utf8).write(to: location)
        let store = LearningRecordStore(fileURL: location)
        var quarantineURL: URL?

        XCTAssertThrowsError(try store.load()) { error in
            guard case .corruptFile(let url, _) = error as? LearningRecordStoreError else {
                return XCTFail("Expected corruptFile, got \(error)")
            }
            quarantineURL = url
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: location.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(quarantineURL).path))
        try store.save(LearningProgress())
        XCTAssertNoThrow(try store.load())
    }

    func testFailedQuarantinePreservesOriginalAndSaveRefusesOverwrite() throws {
        struct MoveFailure: Error {}
        let location = temporaryDirectory().appendingPathComponent("progress.json")
        let original = Data("not json".utf8)
        try original.write(to: location)
        let store = LearningRecordStore(fileURL: location) { _, _ in throw MoveFailure() }

        XCTAssertThrowsError(try store.load()) { error in
            guard case .quarantineFailed = error as? LearningRecordStoreError else {
                return XCTFail("Expected quarantineFailed, got \(error)")
            }
        }
        XCTAssertEqual(try Data(contentsOf: location), original)
        XCTAssertThrowsError(try store.save(LearningProgress())) { error in
            guard case .unsafeExistingFile = error as? LearningRecordStoreError else {
                return XCTFail("Expected unsafeExistingFile, got \(error)")
            }
        }
        XCTAssertEqual(try Data(contentsOf: location), original)
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}

final class DailyWordSelectorTests: XCTestCase {
    func testLegacyCacheTokenIsAcceptedOnlyForSameLocalDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let words = [word("a"), word("b"), word("c")]
        let today = date(2026, 9, 30, 23, 59, calendar: calendar)
        let cache = DailyWordCache(wordID: "b", dayToken: "2026-9-30")
        XCTAssertEqual(DailyWordSelector.select(from: words, date: today, calendar: calendar, cache: cache)?.id, "b")

        let tomorrow = date(2026, 10, 1, 0, 1, calendar: calendar)
        let expected = DailyWordSelector.select(from: words, date: tomorrow, calendar: calendar)?.id
        XCTAssertEqual(DailyWordSelector.select(from: words, date: tomorrow, calendar: calendar, cache: cache)?.id, expected)
    }

    func testDayTokenChangesAcrossDSTLocalMidnightNotElapsedSeconds() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let first = date(2026, 3, 8, 0, 30, calendar: calendar)
        let second = date(2026, 3, 9, 0, 30, calendar: calendar)
        XCTAssertNotEqual(DailyWordSelector.dayToken(for: first, calendar: calendar), DailyWordSelector.dayToken(for: second, calendar: calendar))
        XCTAssertEqual(second.timeIntervalSince(first), 23 * 60 * 60, accuracy: 1)
    }

    func testDayTokensHandleYearAndLeapDayBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertNotEqual(
            DailyWordSelector.dayToken(for: date(2026, 12, 31, 23, 59, calendar: calendar), calendar: calendar),
            DailyWordSelector.dayToken(for: date(2027, 1, 1, 0, 0, calendar: calendar), calendar: calendar)
        )
        XCTAssertNotEqual(
            DailyWordSelector.dayToken(for: date(2028, 2, 29, 12, 0, calendar: calendar), calendar: calendar),
            DailyWordSelector.dayToken(for: date(2028, 3, 1, 12, 0, calendar: calendar), calendar: calendar)
        )
    }
}

final class QuizSelectorTests: XCTestCase {
    func testRecentFallbackReleasesOldestExclusionFirst() throws {
        let words = [word("a"), word("b"), word("c")]
        let pool = QuizSelector.eligibleAnswerPool(words: words, recentIDs: ["a", "b", "c"])
        XCTAssertEqual(pool.map(\.id), ["a"])
    }

    func testAllModeChoicesMatchAnswerLevelAndPartOfSpeech() throws {
        let beginner = (0..<4).map { word("b\($0)", meaning: "beginner\($0)", level: .beginner) }
        let advanced = (0..<4).map { word("a\($0)", meaning: "advanced\($0)", level: .advanced) }
        let question = try QuizSelector.question(words: advanced + beginner, selection: .all, recentIDs: []) { _ in 0 }
        XCTAssertTrue(question.choices.allSatisfy { $0.level == question.answer.level && $0.partOfSpeech == question.answer.partOfSpeech })
    }

    func testExplicitAnswerExcludesAllMeaningSegmentsAndConflictGroups() throws {
        let answer = word("answer", meaning: "strand; clue", conflicts: ["synonym"])
        let words = [
            answer,
            word("secondary-overlap", meaning: "hint, clue"),
            word("group-overlap", meaning: "different", conflicts: ["SYNONYM"]),
            word("one", meaning: "one"), word("two", meaning: "two"), word("three", meaning: "three"), word("four", meaning: "four")
        ]
        let question = try QuizSelector.question(for: answer, words: words) { _ in 0 }
        XCTAssertFalse(question.choices.map(\.id).contains("secondary-overlap"))
        XCTAssertFalse(question.choices.map(\.id).contains("group-overlap"))
        XCTAssertEqual(question.choices.count, 4)
    }

    func testExplicitAnswerRejectsWhenNoPairwiseCompatibleTripleExists() {
        let answer = word("answer", meaning: "answer")
        let words = [
            answer,
            word("one", meaning: "one", conflicts: ["shared"]),
            word("two", meaning: "two", conflicts: ["shared"]),
            word("three", meaning: "three", conflicts: ["shared"]),
            word("four", meaning: "four", conflicts: ["shared"])
        ]
        XCTAssertThrowsError(try QuizSelector.question(for: answer, words: words)) { error in
            XCTAssertEqual(error as? QuizSelectionError, .insufficientChoices)
        }
    }
}

final class CatalogTests: XCTestCase {
    func testBundledCatalogMeetsReleaseCountsAndBuildsQuestionForEveryWord() throws {
        guard case .success(let catalog) = LearningWordCatalog.bundledResult else {
            return XCTFail("Bundled catalog failed validation: \(String(describing: LearningWordCatalog.bundledLoadError))")
        }
        XCTAssertGreaterThanOrEqual(catalog.words.count, 60)
        for level in LearningLevel.allCases {
            XCTAssertGreaterThanOrEqual(catalog.words.filter { $0.level == level }.count, 20)
            for part in PartOfSpeech.allCases {
                XCTAssertGreaterThanOrEqual(catalog.words.filter { $0.level == level && $0.partOfSpeech == part }.count, 4)
            }
        }
        for answer in catalog.words {
            let question = try QuizSelector.question(for: answer, words: catalog.words) { _ in 0 }
            XCTAssertEqual(question.choices.count, 4)
            XCTAssertEqual(Set(question.choices.map(\.id)).count, 4)
            XCTAssertTrue(question.choices.allSatisfy { $0.level == answer.level && $0.partOfSpeech == answer.partOfSpeech })
            for other in question.choices where other.id != answer.id {
                XCTAssertFalse(LearningWordCatalog.conflicts(answer, other), "\(answer.id) conflicts with \(other.id)")
            }
        }
    }

    func testMissingConflictMetadataDecodesAsEmpty() throws {
        let data = try JSONSerialization.data(withJSONObject: [[
            "id": "a", "word": "가", "englishMeaning": "go", "easyKoreanDefinition": "definition",
            "romanization": "ga", "partOfSpeech": "verb", "level": "beginner", "example": "example",
            "exampleTranslation": "translation", "incorrectFeedback": "feedback"
        ]])
        let result = LearningWordCatalog.decode(data: data, enforceReleaseMinimums: false)
        guard case .success(let catalog) = result else { return XCTFail("Expected successful decoding") }
        XCTAssertEqual(catalog.words.first?.conflictGroupIDs, [])
    }

    func testMalformedCatalogReturnsRecoverableError() {
        let result = LearningWordCatalog.decode(data: Data("{".utf8))
        guard case .failure(.invalidJSON) = result else { return XCTFail("Expected invalidJSON") }
    }
}

final class SupportingPolicyTests: XCTestCase {
    func testRequestIdentityGateRejectsStaleRequest() {
        var gate = RequestIdentityGate()
        let stale = gate.begin()
        let current = gate.begin()
        XCTAssertFalse(gate.accepts(stale))
        XCTAssertTrue(gate.accepts(current))
    }

    func testNotificationScheduleRequiresToggleAndAuthorization() {
        XCTAssertFalse(NotificationSchedulePolicy.shouldSchedule(toggleOn: false, authorized: false))
        XCTAssertFalse(NotificationSchedulePolicy.shouldSchedule(toggleOn: true, authorized: false))
        XCTAssertFalse(NotificationSchedulePolicy.shouldSchedule(toggleOn: false, authorized: true))
        XCTAssertTrue(NotificationSchedulePolicy.shouldSchedule(toggleOn: true, authorized: true))
    }
}

private func word(_ id: String, meaning: String? = nil, level: LearningLevel = .beginner, part: PartOfSpeech = .noun, conflicts: [String] = []) -> LearningWord {
    LearningWord(id: id, word: id, englishMeaning: meaning ?? id, easyKoreanDefinition: "definition \(id)", romanization: id, partOfSpeech: part, level: level, example: "example \(id)", exampleTranslation: "translation \(id)", incorrectFeedback: "feedback \(id)", conflictGroupIDs: conflicts)
}

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}
