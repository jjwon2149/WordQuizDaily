import Foundation

public struct WordLearningRecord: Codable, Equatable, Sendable {
    public let wordID: String
    public var answerCount: Int
    public var correctCount: Int
    public var lastLearnedAt: Date
    public var needsReview: Bool
    public var consecutiveCorrectAfterMistake: Int

    public init(wordID: String, answerCount: Int = 0, correctCount: Int = 0, lastLearnedAt: Date = .distantPast, needsReview: Bool = false, consecutiveCorrectAfterMistake: Int = 0) {
        self.wordID = wordID
        self.answerCount = answerCount
        self.correctCount = correctCount
        self.lastLearnedAt = lastLearnedAt
        self.needsReview = needsReview
        self.consecutiveCorrectAfterMistake = consecutiveCorrectAfterMistake
    }

    public mutating func record(isCorrect: Bool, at date: Date) {
        answerCount += 1
        lastLearnedAt = date
        if isCorrect {
            correctCount += 1
            if needsReview {
                consecutiveCorrectAfterMistake += 1
                if consecutiveCorrectAfterMistake >= 2 { needsReview = false }
            }
        } else {
            needsReview = true
            consecutiveCorrectAfterMistake = 0
        }
    }
}

public struct LearningProgress: Codable, Equatable, Sendable {
    public static let currentVersion = 2
    public var version: Int
    public var records: [String: WordLearningRecord]
    public var recordedSubmissionIDs: Set<UUID>
    public var submissionDatesByID: [UUID: Date]

    public init(version: Int = currentVersion, records: [String: WordLearningRecord] = [:], recordedSubmissionIDs: Set<UUID> = [], submissionDatesByID: [UUID: Date] = [:]) {
        self.version = version
        self.records = records
        self.recordedSubmissionIDs = recordedSubmissionIDs
        self.submissionDatesByID = submissionDatesByID
    }

    private enum CodingKeys: String, CodingKey {
        case version, records, recordedSubmissionIDs, submissionDatesByID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        records = try container.decode([String: WordLearningRecord].self, forKey: .records)
        recordedSubmissionIDs = try container.decode(Set<UUID>.self, forKey: .recordedSubmissionIDs)
        submissionDatesByID = try container.decodeIfPresent([UUID: Date].self, forKey: .submissionDatesByID) ?? [:]
    }

    @discardableResult
    public mutating func record(wordID: String, isCorrect: Bool, at date: Date, submissionID: UUID) -> Bool {
        guard !recordedSubmissionIDs.contains(submissionID) else { return false }
        var item = records[wordID] ?? WordLearningRecord(wordID: wordID)
        item.record(isCorrect: isCorrect, at: date)
        records[wordID] = item
        recordedSubmissionIDs.insert(submissionID)
        submissionDatesByID[submissionID] = date
        return true
    }

    public func reviewWordIDs(validIDs: Set<String>, limit: Int = 10) -> [String] {
        records.values
            .filter { $0.needsReview && validIDs.contains($0.wordID) }
            .sorted {
                if $0.lastLearnedAt != $1.lastLearnedAt { return $0.lastLearnedAt < $1.lastLearnedAt }
                return $0.wordID < $1.wordID
            }
            .prefix(max(0, limit))
            .map(\.wordID)
    }

    public func answers(on date: Date, calendar: Calendar) -> Int {
        submissionDatesByID.values.lazy.filter { calendar.isDate($0, inSameDayAs: date) }.count
    }
}

public enum LearningRecordStoreError: Error, Equatable, CustomStringConvertible, Sendable {
    case unsupportedVersion(Int)
    case invalidProgress(String)
    case corruptFile(quarantineURL: URL, reason: String)
    case quarantineFailed(originalURL: URL, reason: String)
    case unsafeExistingFile(reason: String)

    public var description: String {
        switch self {
        case .unsupportedVersion(let version): return "Unsupported learning-record version: \(version)."
        case .invalidProgress(let reason): return "Invalid learning progress: \(reason)"
        case .corruptFile(let url, let reason): return "Corrupt learning progress was moved to \(url.lastPathComponent): \(reason)"
        case .quarantineFailed(let url, let reason): return "Could not quarantine \(url.lastPathComponent): \(reason)"
        case .unsafeExistingFile(let reason): return "Refusing to overwrite existing learning progress: \(reason)"
        }
    }
}

public struct LearningRecordStore: Sendable {
    typealias MoveItem = @Sendable (URL, URL) throws -> Void

    private struct VersionEnvelope: Decodable {
        let version: Int
    }

    public let fileURL: URL
    private let moveItem: MoveItem

    public init(fileURL: URL) {
        self.init(fileURL: fileURL) { source, destination in
            try FileManager.default.moveItem(at: source, to: destination)
        }
    }

    init(fileURL: URL, moveItem: @escaping MoveItem) {
        self.fileURL = fileURL
        self.moveItem = moveItem
    }

    public func load() throws -> LearningProgress {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return LearningProgress() }
        let data = try Data(contentsOf: fileURL)
        let version: Int
        do {
            version = try JSONDecoder().decode(VersionEnvelope.self, from: data).version
        } catch {
            try quarantineCorruptFile(reason: error.localizedDescription)
        }
        guard (1...LearningProgress.currentVersion).contains(version) else {
            throw LearningRecordStoreError.unsupportedVersion(version)
        }
        let decoded: LearningProgress
        do {
            decoded = try JSONDecoder().decode(LearningProgress.self, from: data)
        } catch {
            try quarantineCorruptFile(reason: error.localizedDescription)
        }
        if let problem = Self.validationProblem(in: decoded) {
            try quarantineCorruptFile(reason: problem)
        }
        var migrated = decoded
        migrated.version = LearningProgress.currentVersion
        return migrated
    }

    public func save(_ progress: LearningProgress) throws {
        guard progress.version == LearningProgress.currentVersion else {
            throw LearningRecordStoreError.unsupportedVersion(progress.version)
        }
        if let problem = Self.validationProblem(in: progress) {
            throw LearningRecordStoreError.invalidProgress(problem)
        }
        try verifyExistingFileCanBeReplaced()
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(progress).write(to: fileURL, options: [.atomic])
    }

    private func verifyExistingFileCanBeReplaced() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let data: Data
        do { data = try Data(contentsOf: fileURL) }
        catch { throw LearningRecordStoreError.unsafeExistingFile(reason: error.localizedDescription) }
        let version: Int
        do { version = try JSONDecoder().decode(VersionEnvelope.self, from: data).version }
        catch { throw LearningRecordStoreError.unsafeExistingFile(reason: error.localizedDescription) }
        guard (1...LearningProgress.currentVersion).contains(version) else {
            throw LearningRecordStoreError.unsupportedVersion(version)
        }
        let existing: LearningProgress
        do { existing = try JSONDecoder().decode(LearningProgress.self, from: data) }
        catch { throw LearningRecordStoreError.unsafeExistingFile(reason: error.localizedDescription) }
        if let problem = Self.validationProblem(in: existing) {
            throw LearningRecordStoreError.unsafeExistingFile(reason: problem)
        }
    }

    private func quarantineCorruptFile(reason: String) throws -> Never {
        let quarantine = fileURL.deletingLastPathComponent().appendingPathComponent(fileURL.lastPathComponent + ".corrupt-" + UUID().uuidString)
        do { try moveItem(fileURL, quarantine) }
        catch { throw LearningRecordStoreError.quarantineFailed(originalURL: fileURL, reason: error.localizedDescription) }
        throw LearningRecordStoreError.corruptFile(quarantineURL: quarantine, reason: reason)
    }

    private static func validationProblem(in progress: LearningProgress) -> String? {
        for (key, record) in progress.records {
            if key != record.wordID { return "Record key \(key) does not match word id \(record.wordID)." }
            if record.answerCount < 0 { return "Negative answer count for \(record.wordID)." }
            if record.correctCount < 0 || record.correctCount > record.answerCount { return "Invalid correct count for \(record.wordID)." }
            if record.consecutiveCorrectAfterMistake < 0 { return "Negative review streak for \(record.wordID)." }
            if !record.lastLearnedAt.timeIntervalSinceReferenceDate.isFinite { return "Invalid last-learned date for \(record.wordID)." }
        }
        if !Set(progress.submissionDatesByID.keys).isSubset(of: progress.recordedSubmissionIDs) {
            return "Submission dates contain unknown ids."
        }
        if progress.submissionDatesByID.values.contains(where: { !$0.timeIntervalSinceReferenceDate.isFinite }) {
            return "Submission dates contain a non-finite value."
        }
        return nil
    }
}

public struct ReviewSession: Equatable, Sendable {
    public let wordIDs: [String]
    public private(set) var currentIndex = 0
    public private(set) var correctCount = 0

    public init(wordIDs: [String]) {
        var seen = Set<String>()
        self.wordIDs = wordIDs.filter { seen.insert($0).inserted }
    }

    public var currentWordID: String? { wordIDs.indices.contains(currentIndex) ? wordIDs[currentIndex] : nil }
    public var isComplete: Bool { currentIndex >= wordIDs.count }

    public mutating func submit(isCorrect: Bool) {
        guard !isComplete else { return }
        if isCorrect { correctCount += 1 }
        currentIndex += 1
    }
}
