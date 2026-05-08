//
//  LearningWordRepository.swift
//  WordQuizDaily
//

import Foundation

enum LearningWordValidationError: Equatable, CustomStringConvertible {
    case emptyData
    case duplicateKoreanWord(String)
    case missingRequiredField(word: String, field: String)

    var description: String {
        switch self {
        case .emptyData:
            return "Learning word data is empty."
        case .duplicateKoreanWord(let word):
            return "Duplicate Korean word: \(word)"
        case .missingRequiredField(let word, let field):
            return "Missing \(field) for word: \(word)"
        }
    }
}

protocol LearningWordProviding {
    var words: [LearningWord] { get }
    var koreanWords: [String] { get }

    func word(id: String) -> LearningWord?
    func word(korean: String) -> LearningWord?
    func word(for date: Date, calendar: Calendar) -> LearningWord?
    func randomWord(excluding excludedIDs: Set<String>) -> LearningWord?
    func choices(for correctWord: LearningWord, count: Int) -> [LearningWord]
}

struct LearningWordRepository: LearningWordProviding {
    static let shared = LearningWordRepository()

    let words: [LearningWord]
    let validationErrors: [LearningWordValidationError]

    init(words: [LearningWord] = LearningWordSampleData.words) {
        self.validationErrors = Self.validate(words)
        self.words = Self.validUniqueWords(from: words)
    }

    var koreanWords: [String] {
        words.map(\.korean)
    }

    var isAvailable: Bool {
        !words.isEmpty
    }

    func word(id: String) -> LearningWord? {
        words.first { $0.id == id }
    }

    func word(korean: String) -> LearningWord? {
        words.first { $0.korean == korean }
    }

    func word(for date: Date = Date(), calendar: Calendar = .current) -> LearningWord? {
        guard !words.isEmpty else { return nil }

        let startOfDay = calendar.startOfDay(for: date)
        let dayNumber = Int(startOfDay.timeIntervalSince1970 / 86_400)
        let index = ((dayNumber % words.count) + words.count) % words.count
        return words[index]
    }

    func randomWord(excluding excludedIDs: Set<String> = []) -> LearningWord? {
        words.filter { !excludedIDs.contains($0.id) }.randomElement()
    }

    func choices(for correctWord: LearningWord, count: Int = 4) -> [LearningWord] {
        guard count > 1 else { return [correctWord] }

        let targetCount = min(count, max(words.count, 1))
        let distractors = words
            .filter { $0.id != correctWord.id }
            .shuffled()
            .prefix(max(targetCount - 1, 0))

        return ([correctWord] + Array(distractors)).shuffled()
    }

    static func validate(_ words: [LearningWord]) -> [LearningWordValidationError] {
        guard !words.isEmpty else { return [.emptyData] }

        var errors: [LearningWordValidationError] = []
        var seenKoreanWords = Set<String>()

        for word in words {
            for field in word.requiredTextFields {
                if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append(.missingRequiredField(word: word.korean, field: field.name))
                }
            }

            if !seenKoreanWords.insert(word.korean).inserted {
                errors.append(.duplicateKoreanWord(word.korean))
            }
        }

        return errors
    }

    private static func validUniqueWords(from words: [LearningWord]) -> [LearningWord] {
        var seenKoreanWords = Set<String>()

        return words.filter { word in
            let hasAllRequiredFields = word.requiredTextFields.allSatisfy {
                !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            guard hasAllRequiredFields else { return false }
            return seenKoreanWords.insert(word.korean).inserted
        }
    }
}

private enum LearningWordSampleData {
    static let words: [LearningWord] = [
        LearningWord(
            korean: "가닥",
            englishMeaning: "strand; clue",
            simpleKoreanDefinition: "여러 부분 중 하나의 줄기나 방향이에요.",
            romanization: "gadak",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "문제를 풀 가닥이 조금 보였어요.",
            exampleTranslation: "I started to see a clue for solving the problem.",
            incorrectFeedback: "가닥은 물건의 한 줄기나 문제를 풀 실마리를 말해요."
        ),
        LearningWord(
            korean: "갈등",
            englishMeaning: "conflict",
            simpleKoreanDefinition: "생각이나 마음이 서로 맞지 않아 생기는 어려움이에요.",
            romanization: "galdeung",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "두 친구 사이에 작은 갈등이 생겼어요.",
            exampleTranslation: "A small conflict arose between the two friends.",
            incorrectFeedback: "갈등은 사람이나 생각이 서로 부딪히는 상황이에요."
        ),
        LearningWord(
            korean: "견본",
            englishMeaning: "sample",
            simpleKoreanDefinition: "전체를 보여 주기 위해 먼저 내놓는 작은 예예요.",
            romanization: "gyeonbon",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "직원이 천 견본을 보여 주었어요.",
            exampleTranslation: "The employee showed a fabric sample.",
            incorrectFeedback: "견본은 상품이나 자료를 대표해서 보여 주는 예시예요."
        ),
        LearningWord(
            korean: "결핍",
            englishMeaning: "lack; deficiency",
            simpleKoreanDefinition: "꼭 필요한 것이 충분하지 않은 상태예요.",
            romanization: "gyeolpip",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "수면 결핍은 건강에 나쁜 영향을 줘요.",
            exampleTranslation: "Lack of sleep has a bad effect on health.",
            incorrectFeedback: "결핍은 필요한 것이 모자란 상태를 뜻해요."
        ),
        LearningWord(
            korean: "고정관념",
            englishMeaning: "stereotype",
            simpleKoreanDefinition: "쉽게 바뀌지 않는 굳은 생각이에요.",
            romanization: "gojeonggwan-nyeom",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "고정관념을 버리면 새로운 방법이 보여요.",
            exampleTranslation: "If you let go of stereotypes, you can see new methods.",
            incorrectFeedback: "고정관념은 사실을 보기 전에 이미 정해 둔 생각이에요."
        ),
        LearningWord(
            korean: "관행",
            englishMeaning: "customary practice",
            simpleKoreanDefinition: "오랫동안 반복되어 보통의 방식처럼 된 일이에요.",
            romanization: "gwanhaeng",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "회사는 오래된 관행을 바꾸기로 했어요.",
            exampleTranslation: "The company decided to change an old practice.",
            incorrectFeedback: "관행은 사람들이 계속 해 와서 익숙해진 방식이에요."
        ),
        LearningWord(
            korean: "균형",
            englishMeaning: "balance",
            simpleKoreanDefinition: "한쪽으로 치우치지 않고 알맞게 맞는 상태예요.",
            romanization: "gyunhyeong",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "일과 휴식의 균형이 중요해요.",
            exampleTranslation: "Balance between work and rest is important.",
            incorrectFeedback: "균형은 두 쪽이 알맞게 맞는 상태를 말해요."
        ),
        LearningWord(
            korean: "기틀",
            englishMeaning: "foundation",
            simpleKoreanDefinition: "어떤 일을 시작하고 세우는 바탕이에요.",
            romanization: "giteul",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "초기 연구가 새 기술의 기틀이 되었어요.",
            exampleTranslation: "Early research became the foundation of the new technology.",
            incorrectFeedback: "기틀은 일이 이루어질 수 있게 하는 기본 바탕이에요."
        ),
        LearningWord(
            korean: "까닭",
            englishMeaning: "reason",
            simpleKoreanDefinition: "어떤 일이 생기게 된 이유예요.",
            romanization: "kkadak",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "그가 늦은 까닭을 설명했어요.",
            exampleTranslation: "He explained the reason he was late.",
            incorrectFeedback: "까닭은 왜 그런 일이 있었는지를 말하는 단어예요."
        ),
        LearningWord(
            korean: "낭패",
            englishMeaning: "trouble; failure",
            simpleKoreanDefinition: "일이 뜻대로 되지 않아 어려워진 상황이에요.",
            romanization: "nangpae",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "지갑을 두고 와서 큰 낭패를 봤어요.",
            exampleTranslation: "I was in big trouble because I left my wallet behind.",
            incorrectFeedback: "낭패는 계획과 달라서 곤란해지는 일을 뜻해요."
        ),
        LearningWord(
            korean: "논거",
            englishMeaning: "basis of an argument",
            simpleKoreanDefinition: "주장을 뒷받침하는 이유나 근거예요.",
            romanization: "nongeo",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "그 발표에는 분명한 논거가 필요해요.",
            exampleTranslation: "That presentation needs clear grounds for its argument.",
            incorrectFeedback: "논거는 의견을 믿게 해 주는 이유나 자료예요."
        ),
        LearningWord(
            korean: "단서",
            englishMeaning: "clue",
            simpleKoreanDefinition: "문제를 풀 수 있게 도와주는 작은 정보예요.",
            romanization: "danseo",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "사진 속 날짜가 중요한 단서였어요.",
            exampleTranslation: "The date in the photo was an important clue.",
            incorrectFeedback: "단서는 답을 찾는 데 도움이 되는 정보예요."
        ),
        LearningWord(
            korean: "당부",
            englishMeaning: "earnest request",
            simpleKoreanDefinition: "꼭 지켜 달라고 부탁하는 말이에요.",
            romanization: "dangbu",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "선생님은 안전을 조심하라는 당부를 했어요.",
            exampleTranslation: "The teacher made an earnest request to be careful about safety.",
            incorrectFeedback: "당부는 중요하게 생각해서 꼭 해 달라고 부탁하는 말이에요."
        ),
        LearningWord(
            korean: "돌파구",
            englishMeaning: "breakthrough",
            simpleKoreanDefinition: "어려운 상황을 벗어날 수 있는 방법이에요.",
            romanization: "dolpagu",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "팀은 문제 해결의 돌파구를 찾았어요.",
            exampleTranslation: "The team found a breakthrough for solving the problem.",
            incorrectFeedback: "돌파구는 막힌 상황을 뚫고 나갈 방법이에요."
        ),
        LearningWord(
            korean: "맥락",
            englishMeaning: "context",
            simpleKoreanDefinition: "말이나 일이 이어지는 흐름과 배경이에요.",
            romanization: "maengnak",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "문장의 맥락을 보면 뜻을 알 수 있어요.",
            exampleTranslation: "You can understand the meaning by looking at the context of the sentence.",
            incorrectFeedback: "맥락은 앞뒤 내용과 상황의 흐름이에요."
        ),
        LearningWord(
            korean: "모순",
            englishMeaning: "contradiction",
            simpleKoreanDefinition: "두 말이나 행동이 서로 맞지 않는 상태예요.",
            romanization: "mosun",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "그의 설명에는 작은 모순이 있었어요.",
            exampleTranslation: "There was a small contradiction in his explanation.",
            incorrectFeedback: "모순은 서로 함께 맞을 수 없는 말이나 상황이에요."
        ),
        LearningWord(
            korean: "밑바탕",
            englishMeaning: "basis; groundwork",
            simpleKoreanDefinition: "겉으로 보이는 것 아래에 있는 기본 바탕이에요.",
            romanization: "mitbatang",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "신뢰는 좋은 관계의 밑바탕이에요.",
            exampleTranslation: "Trust is the groundwork of a good relationship.",
            incorrectFeedback: "밑바탕은 어떤 것을 가능하게 하는 기본 바탕이에요."
        ),
        LearningWord(
            korean: "배려",
            englishMeaning: "consideration",
            simpleKoreanDefinition: "다른 사람의 마음이나 상황을 생각해 주는 일이에요.",
            romanization: "baeryeo",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "작은 배려가 큰 힘이 될 수 있어요.",
            exampleTranslation: "A small act of consideration can be a big help.",
            incorrectFeedback: "배려는 다른 사람을 생각해서 조심하고 도와주는 마음이에요."
        ),
        LearningWord(
            korean: "번영",
            englishMeaning: "prosperity",
            simpleKoreanDefinition: "사람이나 나라가 잘되고 넉넉해지는 일이에요.",
            romanization: "beonyeong",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "도시의 번영은 많은 사람의 노력으로 이루어졌어요.",
            exampleTranslation: "The city's prosperity was achieved through many people's efforts.",
            incorrectFeedback: "번영은 점점 잘되고 풍요로워지는 상태예요."
        ),
        LearningWord(
            korean: "본보기",
            englishMeaning: "example; model",
            simpleKoreanDefinition: "따라 하거나 참고할 만한 좋은 예예요.",
            romanization: "bonbogi",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "그 선수는 어린이들에게 좋은 본보기예요.",
            exampleTranslation: "That athlete is a good role model for children.",
            incorrectFeedback: "본보기는 다른 사람이 보고 배울 만한 예시예요."
        ),
        LearningWord(
            korean: "상생",
            englishMeaning: "mutual benefit",
            simpleKoreanDefinition: "서로 도우며 함께 잘되는 일이에요.",
            romanization: "sangsaeng",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "두 회사는 상생을 위한 협약을 맺었어요.",
            exampleTranslation: "The two companies made an agreement for mutual benefit.",
            incorrectFeedback: "상생은 한쪽만이 아니라 서로 함께 이익을 얻는 일이에요."
        ),
        LearningWord(
            korean: "성향",
            englishMeaning: "tendency",
            simpleKoreanDefinition: "생각이나 행동이 자주 향하는 방향이에요.",
            romanization: "seonghyang",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "그는 새로운 일을 좋아하는 성향이 있어요.",
            exampleTranslation: "He has a tendency to like new things.",
            incorrectFeedback: "성향은 어떤 쪽으로 자주 생각하거나 행동하는 특징이에요."
        ),
        LearningWord(
            korean: "안목",
            englishMeaning: "good eye; insight",
            simpleKoreanDefinition: "좋고 나쁨을 알아보는 눈이나 능력이에요.",
            romanization: "anmok",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "그 디자이너는 색을 고르는 안목이 뛰어나요.",
            exampleTranslation: "The designer has an excellent eye for choosing colors.",
            incorrectFeedback: "안목은 가치를 알아보고 판단하는 능력을 말해요."
        ),
        LearningWord(
            korean: "여유",
            englishMeaning: "room; composure",
            simpleKoreanDefinition: "시간이나 마음, 돈 등이 넉넉한 상태예요.",
            romanization: "yeoyu",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "아침에 여유가 있어서 커피를 마셨어요.",
            exampleTranslation: "I had enough time in the morning, so I drank coffee.",
            incorrectFeedback: "여유는 부족하지 않고 조금 남거나 마음이 급하지 않은 상태예요."
        ),
        LearningWord(
            korean: "연대",
            englishMeaning: "solidarity",
            simpleKoreanDefinition: "같은 목표를 위해 서로 힘을 합하는 일이에요.",
            romanization: "yeondae",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "시민들은 이웃과의 연대를 보여 주었어요.",
            exampleTranslation: "The citizens showed solidarity with their neighbors.",
            incorrectFeedback: "연대는 혼자가 아니라 함께 책임지고 돕는 관계예요."
        ),
        LearningWord(
            korean: "염두",
            englishMeaning: "consideration; mind",
            simpleKoreanDefinition: "마음속에 두고 생각하는 것이에요.",
            romanization: "yeomdu",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "비용을 염두에 두고 계획을 세워야 해요.",
            exampleTranslation: "You should make a plan with the cost in mind.",
            incorrectFeedback: "염두는 어떤 일을 마음속에 두고 생각한다는 뜻이에요."
        ),
        LearningWord(
            korean: "요인",
            englishMeaning: "factor",
            simpleKoreanDefinition: "어떤 결과가 생기게 하는 중요한 원인이에요.",
            romanization: "yoin",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "날씨는 매출에 영향을 주는 요인 중 하나예요.",
            exampleTranslation: "Weather is one of the factors that affects sales.",
            incorrectFeedback: "요인은 결과에 영향을 주는 원인이나 조건이에요."
        ),
        LearningWord(
            korean: "우려",
            englishMeaning: "concern",
            simpleKoreanDefinition: "나쁜 일이 생길까 걱정하는 마음이에요.",
            romanization: "uryeo",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "전문가들은 안전 문제에 우려를 나타냈어요.",
            exampleTranslation: "Experts expressed concern about safety issues.",
            incorrectFeedback: "우려는 앞으로 문제가 생길까 봐 걱정하는 마음이에요."
        ),
        LearningWord(
            korean: "위기",
            englishMeaning: "crisis",
            simpleKoreanDefinition: "매우 위험하거나 어려운 순간이에요.",
            romanization: "wigi",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "회사는 위기를 기회로 바꾸려고 노력했어요.",
            exampleTranslation: "The company tried to turn the crisis into an opportunity.",
            incorrectFeedback: "위기는 상황이 나빠져서 위험하고 중요한 때를 말해요."
        ),
        LearningWord(
            korean: "유래",
            englishMeaning: "origin",
            simpleKoreanDefinition: "어떤 말이나 일이 처음 시작된 곳이나 이유예요.",
            romanization: "yurae",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "이 축제의 유래를 알고 싶어요.",
            exampleTranslation: "I want to know the origin of this festival.",
            incorrectFeedback: "유래는 어떤 것이 어디에서 시작되었는지를 뜻해요."
        ),
        LearningWord(
            korean: "의도",
            englishMeaning: "intention",
            simpleKoreanDefinition: "무엇을 하려고 마음먹은 생각이에요.",
            romanization: "uido",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "그 말의 의도를 바로 이해하지 못했어요.",
            exampleTranslation: "I did not immediately understand the intention of those words.",
            incorrectFeedback: "의도는 어떤 행동이나 말 뒤에 있는 목적이에요."
        ),
        LearningWord(
            korean: "인내",
            englishMeaning: "patience",
            simpleKoreanDefinition: "힘들어도 참고 기다리는 마음이에요.",
            romanization: "innae",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "언어 공부에는 인내가 필요해요.",
            exampleTranslation: "Language study requires patience.",
            incorrectFeedback: "인내는 어려움을 참고 견디는 힘이에요."
        ),
        LearningWord(
            korean: "자립",
            englishMeaning: "independence",
            simpleKoreanDefinition: "다른 사람에게 기대지 않고 스스로 서는 일이에요.",
            romanization: "jarip",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "그 단체는 청년들의 자립을 돕고 있어요.",
            exampleTranslation: "The organization is helping young people become independent.",
            incorrectFeedback: "자립은 스스로 생활하거나 일을 해 나가는 상태예요."
        ),
        LearningWord(
            korean: "자부심",
            englishMeaning: "pride",
            simpleKoreanDefinition: "자기 자신이나 자신이 한 일을 좋게 여기는 마음이에요.",
            romanization: "jabusim",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "그는 자신의 일에 큰 자부심을 느껴요.",
            exampleTranslation: "He feels great pride in his work.",
            incorrectFeedback: "자부심은 자신이나 자기 일에 대해 긍정적으로 느끼는 마음이에요."
        ),
        LearningWord(
            korean: "장점",
            englishMeaning: "strength; advantage",
            simpleKoreanDefinition: "좋거나 뛰어난 점이에요.",
            romanization: "jangjeom",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "이 앱의 장점은 사용하기 쉽다는 거예요.",
            exampleTranslation: "The strength of this app is that it is easy to use.",
            incorrectFeedback: "장점은 좋은 점이고, 단점은 부족한 점이에요."
        ),
        LearningWord(
            korean: "전망",
            englishMeaning: "outlook; prospect",
            simpleKoreanDefinition: "앞으로 어떻게 될지 보는 생각이나 예상이에요.",
            romanization: "jeonmang",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "내년 경제 전망은 아직 불확실해요.",
            exampleTranslation: "Next year's economic outlook is still uncertain.",
            incorrectFeedback: "전망은 미래 상황을 바라보거나 예상하는 말이에요."
        ),
        LearningWord(
            korean: "절차",
            englishMeaning: "procedure",
            simpleKoreanDefinition: "일을 처리하는 정해진 순서예요.",
            romanization: "jeolcha",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "신청 절차를 천천히 확인하세요.",
            exampleTranslation: "Please check the application procedure carefully.",
            incorrectFeedback: "절차는 어떤 일을 하기 위해 따라야 하는 순서예요."
        ),
        LearningWord(
            korean: "중재",
            englishMeaning: "mediation",
            simpleKoreanDefinition: "다투는 사람들 사이에서 문제를 풀도록 돕는 일이에요.",
            romanization: "jungjae",
            partOfSpeech: "noun",
            difficulty: .advanced,
            exampleSentence: "선생님의 중재로 두 학생이 화해했어요.",
            exampleTranslation: "The two students reconciled through the teacher's mediation.",
            incorrectFeedback: "중재는 갈등이 있는 양쪽 사이에서 해결을 돕는 일이에요."
        ),
        LearningWord(
            korean: "지름길",
            englishMeaning: "shortcut",
            simpleKoreanDefinition: "목적지까지 더 빨리 가는 길이나 방법이에요.",
            romanization: "jireumgil",
            partOfSpeech: "noun",
            difficulty: .beginner,
            exampleSentence: "역까지 가는 지름길을 알려 주세요.",
            exampleTranslation: "Please tell me the shortcut to the station.",
            incorrectFeedback: "지름길은 더 짧고 빠르게 갈 수 있는 길이에요."
        ),
        LearningWord(
            korean: "차별",
            englishMeaning: "discrimination",
            simpleKoreanDefinition: "사람을 이유 없이 다르게 대하고 불리하게 하는 일이에요.",
            romanization: "chabyeol",
            partOfSpeech: "noun",
            difficulty: .intermediate,
            exampleSentence: "우리는 차별 없는 사회를 원해요.",
            exampleTranslation: "We want a society without discrimination.",
            incorrectFeedback: "차별은 어떤 사람을 공평하지 않게 대하는 일이에요."
        )
    ]
}
