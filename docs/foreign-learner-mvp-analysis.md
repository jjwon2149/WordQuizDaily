# Foreign Learner MVP Analysis

이 문서는 기존 WordQuizDaily의 오늘의 단어, 퀴즈, 알림 흐름을 유지하면서 외국인 한국어 학습자용 MVP로 확장하기 위한 코드 구조, 데이터 흐름, 작업 경계를 정리한다. 실제 Swift 구현은 이 문서의 범위 밖이며, 1차 MVP는 서버, CMS, 원격 DB 없이 로컬 학습 데이터만 사용한다.

## MVP 제약

- 홈, 퀴즈, 설정 탭 구조는 유지한다.
- 오늘의 단어, 퀴즈 출제, 알림 설정이라는 사용자 흐름은 유지한다.
- 단어 설명, 영어 뜻, 쉬운 한국어 설명, 예문, 로마자 표기, 난이도, 오답 피드백은 로컬 데이터에서 읽는다.
- 우리말샘 API와 Naver Image API는 MVP의 필수 데이터 경로가 아니어야 한다. 이미지 검색은 API 키가 있을 때만 동작하는 선택 기능으로 남길 수 있다.
- FCM 서버 스케줄링, CMS, 원격 데이터 동기화는 제외한다. 현재 코드의 로컬 백업 알림 경로를 기준으로 MVP를 완성한다.

## 현재 앱 구조

| 영역 | 주요 파일 | 현재 역할 |
| --- | --- | --- |
| 앱 진입점 | `WordQuizDaily/WordQuizDaily/WordQuizDailyApp.swift`, `AppDelegate.swift` | Firebase, AdMob, APNs, FCM delegate를 초기화하고 `ContentView`를 띄운다. |
| 탭/상태 주입 | `WordQuizDaily/WordQuizDaily/ContentView.swift` | `QuizViewModel`, `HomeViewModel`, `FCMNotificationManager`를 `@StateObject`로 생성하고 Quiz/Home/Setting 탭에 주입한다. 알림 딥링크 NotificationCenter 이벤트로 탭을 변경한다. |
| 오늘의 단어 | `Views/Home/HomeView.swift`, `Views/Home/HomeViewModel.swift` | 단어와 정의를 표시한다. ViewModel은 `HardKoreanWords`에서 단어를 뽑고 우리말샘 API로 정의를 조회한다. |
| 퀴즈 | `Views/Quiz/QuizView.swift`, `Views/Quiz/QuizViewModel.swift` | 정의, 이미지, 4지선다 선택지를 표시한다. 정답 선택 시 다음 문제를 가져오고, 오답은 별도 UI 피드백 없이 로그만 남긴다. |
| 단어 원천 | `Models/HardKoreanWords.swift`, `Models/Word/WordData.swift` | 어려운 한국어 단어 문자열 배열과 우리말샘 응답 모델이다. 학습자용 메타데이터는 없다. |
| 원격 조회 | `Network/WordNetwork.swift`, `Network/NaverNetwork.swift` | 우리말샘에서 정의를 가져오고 Naver Image API에서 이미지를 가져온다. API 키 누락 시 데이터가 비어 있을 수 있다. |
| 알림 | `Services/FCMService.swift`, `Services/FCMNotificationManager.swift`, `AppDelegate.swift`, `Views/Setting/SettingView.swift` | 권한 요청, FCM 토큰 처리, 딥링크, 토글/시간 설정, 로컬 백업 알림을 담당한다. 서버 스케줄링 메서드는 TODO와 로그만 존재한다. |
| 로컬라이제이션 | `Helpers/LocalizationHelper.swift`, `Resources/Localizations/*/Localizable.strings` | ko/en/ja 정적 UI 문구를 키 기반으로 제공한다. 동적 단어 설명은 API 또는 UserDefaults 값 그대로 표시된다. |

## 현재 데이터 흐름

### 홈

1. `ContentView`가 `HomeViewModel`을 생성해 `HomeView`에 `environmentObject`로 전달한다.
2. `HomeViewModel.init()`이 `fetchTodayWordOnceADay()`를 호출한다.
3. `UserDefaults.shared`에 `TodayWord`, `TodayWordDefinition`이 있으면 그대로 사용한다.
4. 저장값이 없으면 `HardKoreanWords.hardWords.randomElement()`로 단어를 고른다.
5. `WordNetwork.searchWord(_:)`가 우리말샘 API를 호출한다.
6. `WordData.channel.item.first?.sense.first?.definition`을 `toDayWordDefinition`에 넣고 UserDefaults에 저장한다.
7. `HomeView`는 단어와 정의만 표시한다.

주의할 점: `HomeViewModel`에 `updateInterval`은 있지만 현재 날짜나 저장 시각 검증에 쓰이지 않는다. 한 번 저장된 `TodayWord`가 만료되지 않으므로 MVP에서 "매일" 동작을 보장하려면 `TodayWordDate` 또는 `TodayWordID` 기반 갱신 조건이 필요하다.

### 퀴즈

1. `ContentView`가 `QuizViewModel`을 생성해 `QuizView`에 전달한다.
2. `QuizViewModel.init()`이 `fetchData()`를 호출한다.
3. `setupNewQuiz()`가 `HardKoreanWords`에서 정답 단어를 뽑고, 같은 배열에서 오답 후보를 섞어 4지선다를 만든다.
4. `WordNetwork.searchWord(_:)`로 정답 정의를 가져온다.
5. 정의 조회 후 `NaverNetwork.requestSearchImage(query:)`로 이미지를 가져온다.
6. `QuizView`는 정의, 이미지, 선택지를 표시한다.
7. `ChoiceView`는 정답이면 즉시 `fetchData()`로 다음 문제를 가져온다. 오답이면 `checkAnswer` 결과를 로그로만 남긴다.

현재 구조는 "정의만 보고 한국어 단어 고르기"에 맞춰져 있다. 외국인 학습자 MVP에서는 정답/오답 피드백과 쉬운 설명, 영어 뜻, 예문을 같은 로컬 데이터에서 가져오도록 바꿔야 한다.

### 알림

1. `AppDelegate`가 Firebase, AdMob, FCM delegate, UNUserNotificationCenter delegate를 설정하고 원격 알림을 등록한다.
2. `FCMService`는 FCM 토큰, 알림 수신, 알림 탭, 딥링크 이벤트를 Combine publisher로 노출한다.
3. `FCMNotificationManager`는 설정 화면에서 쓰는 상태를 관리한다.
4. `SettingView.NotiView`는 `isToggleOn`과 `notificationTime`을 바인딩한다.
5. 토글이 켜지면 권한 요청 후 `scheduleNotificationTime()`이 호출된다.
6. 서버 스케줄링 메서드는 현재 실제 API 호출 없이 로그만 남긴다.
7. `scheduleLocalBackupNotification()`은 `UserDefaults.shared`의 `TodayWord`, `TodayWordDefinition`으로 로컬 알림 제목/본문을 만든다.

MVP에서는 서버 스케줄링을 구현하지 않고, 로컬 백업 알림을 주 경로로 보고 단어 데이터도 로컬 repository에서 가져오도록 맞춘다.

## 외국인 학습자 MVP 데이터 모델

기존 `HardKoreanWords`는 문자열 배열이라 화면별 확장에 필요한 정보를 담기 어렵다. 새 로컬 모델을 추가하고 Home/Quiz/Notification에서 같은 모델을 읽는 방식이 가장 안전하다.

권장 필드:

| 필드 | 예시 | 사용 위치 |
| --- | --- | --- |
| `id` | `gakgwang` | UserDefaults 저장, 오늘의 단어 고정, 퀴즈 정답 추적 |
| `korean` | `각광` | 홈 단어, 퀴즈 선택지, 알림 제목 |
| `romanization` | `gakgwang` | 홈 학습 카드, 퀴즈 해설 |
| `englishMeaning` | `spotlight; attention` | 홈, 퀴즈 해설, 알림 본문 |
| `easyKoreanDefinition` | `많은 사람들의 관심을 받는 것` | 홈, 퀴즈 문제 설명 |
| `exampleKorean` | `그 배우는 새 영화로 각광을 받았다.` | 홈, 퀴즈 해설 |
| `exampleEnglish` | `The actor gained attention with the new movie.` | 홈, 퀴즈 해설 |
| `difficulty` | `beginner`, `intermediate`, `advanced` | 홈 배지, 퀴즈 필터, 후속 난이도 설정 |
| `partOfSpeech` | `noun` | 학습 정보, 선택지 품질 관리 |
| `distractorTags` | `["abstract-noun", "news"]` | 비슷한 난이도/품사의 오답 후보 생성 |
| `correctFeedback` | `정답입니다. '각광을 받다'처럼 자주 씁니다.` | 정답 후 해설 |
| `incorrectFeedback` | `뜻을 다시 보면 '관심을 받다'에 가깝습니다.` | 오답 후 피드백 |
| `imageQuery` 또는 `localImageName` | `spotlight` | 선택 이미지 경로. API 의존 없이 비워둘 수 있음 |

초기 구현은 Swift 정적 배열(`LearningWordData.swift`)이 가장 단순하다. 콘텐츠가 커지면 같은 모델을 유지한 채 번들 JSON으로 옮길 수 있다. 중요한 점은 ViewModel이 배열 구현을 직접 알지 않고 `LearningWordRepository` 같은 얇은 접근 계층을 통해 읽는 것이다.

권장 repository 책임:

- `allWords`: 전체 로컬 단어 목록
- `word(id:)`: 저장된 오늘의 단어 복원
- `wordForToday(date:)`: 날짜 기반 오늘의 단어 결정
- `quizItem(excluding:)`: 새 퀴즈 정답 선택
- `choices(for:count:)`: 난이도와 품사를 고려한 선택지 생성

## 화면별 반영 위치

### Home

주 수정 파일:

- `Views/Home/HomeViewModel.swift`
- `Views/Home/HomeView.swift`
- 신규 `Models/LearningWord.swift`
- 신규 `Models/LearningWordRepository.swift` 또는 `Models/LearningWordData.swift`

변경 방향:

- `toDayWord`와 `toDayWordDefinition` 문자열 중심 상태를 `todayWord: LearningWord?` 중심으로 전환한다.
- `WordNetwork.searchWord` 호출을 제거하거나 fallback/debug 경로로 내린다.
- UserDefaults에는 `TodayWordID`, `TodayWordDate`를 저장한다. 알림/위젯 호환이 필요하면 기존 `TodayWord`, `TodayWordDefinition`도 같은 시점에 같이 저장한다.
- 화면에는 한국어 단어, 로마자, 영어 뜻, 쉬운 한국어 설명, 예문, 난이도를 표시한다.
- 매일 갱신 기준은 로컬 날짜(`yyyy-MM-dd`)로 명확히 둔다.

### Quiz

주 수정 파일:

- `Views/Quiz/QuizViewModel.swift`
- `Views/Quiz/QuizView.swift`
- 신규 로컬 단어 모델/repository

변경 방향:

- `correctWord: String`, `choiceWord: [String]`, `correctWordDefinition: String`을 `LearningWord` 기반 상태로 전환한다.
- 문제 설명은 `easyKoreanDefinition`, `englishMeaning`, 예문 중 MVP에서 정한 유형을 사용한다.
- 선택지는 `LearningWord` 배열에서 만들되 화면에는 `korean`을 표시한다.
- 오답 선택 시 다음 문제로 넘어가지 않고 `incorrectFeedback`, 정답 단어, 로마자, 영어 뜻을 보여준다.
- 정답 선택 시에도 바로 다음 문제로 넘기기보다 `correctFeedback`을 보여준 뒤 다음 버튼으로 이동하는 편이 학습자에게 맞다.
- Naver 이미지는 있으면 보여주는 선택 보조 자료로 두고, 이미지 실패가 퀴즈 진행을 막지 않게 한다.

### Notifications

주 수정 파일:

- `Services/FCMNotificationManager.swift`
- `Services/FCMService.swift`
- `Views/Setting/SettingView.swift`는 UI 변경이 있을 때만 수정

변경 방향:

- MVP에서는 `sendNotificationScheduleToServer()`와 `cancelServerNotifications()`를 실제 요구사항으로 보지 않는다.
- 로컬 알림 본문은 `LearningWordRepository.wordForToday(date:)` 또는 저장된 `TodayWordID`에서 가져온다.
- `getLocalizedNotificationContent`는 `TodayWordDefinition` 문자열 대신 `englishMeaning` 또는 쉬운 한국어 설명을 언어별 템플릿에 넣는다.
- 앱 시작 시 자동 권한 요청과 설정 화면 토글 요청이 중복될 수 있으므로, 후속 UX 이슈에서 권한 요청 시점을 정리한다.

### Localization

주 수정 파일:

- `Helpers/LocalizationHelper.swift`
- `Resources/Localizations/ko.lproj/Localizable.strings`
- `Resources/Localizations/en.lproj/Localizable.strings`
- `Resources/Localizations/ja.lproj/Localizable.strings`

변경 방향:

- 정적 UI 레이블은 기존 `LocalizationKeys.Word`의 `meaning`, `pronunciation`, `example`, `difficulty`를 재사용한다.
- 학습 콘텐츠 자체는 로컬 데이터의 `englishMeaning`, `easyKoreanDefinition`, `exampleKorean`, `exampleEnglish`에 둔다. 모든 콘텐츠를 `.strings`로 분산시키면 번역 누락과 키 충돌 위험이 커진다.
- en/ja `Localizable.strings`에는 일부 키가 중복 정의되어 있다. 학습자 MVP 문구를 추가하기 전에 중복 키 정리를 별도 이슈로 처리하는 편이 안전하다.

## 유지할 기능과 바꿀 기능

유지:

- `ContentView`의 Quiz/Home/Setting 3탭 구조
- `NavigationStack` 기반 화면 구성
- 알림 토글과 시간 선택 UI
- `UserDefaults.shared` 앱 그룹 저장 방식
- `LocalizationKeys`와 `Localizable.strings` 기반 정적 문구 처리
- 기존 `WordNetwork`, `NaverNetwork` 파일은 후속 비교나 fallback을 위해 당장 삭제하지 않음

변경:

- `HardKoreanWords` 문자열 배열 직접 의존을 typed local learning data 의존으로 전환
- 우리말샘 API 정의를 MVP 필수 경로에서 제거
- 오늘의 단어 캐시를 날짜 기준으로 갱신
- 퀴즈 오답 피드백 UI 추가
- 알림 본문을 로컬 학습 데이터 기반으로 생성
- 이미지 검색 실패 또는 API 키 누락이 퀴즈 로딩을 막지 않도록 분리

## 병렬 개발 경계

| 작업 영역 | 주 소유 파일 | 충돌 위험 | 권장 경계 |
| --- | --- | --- | --- |
| 로컬 데이터 모델 | 신규 `Models/LearningWord*.swift`, 기존 `Models/HardKoreanWords.swift` | 높음 | 한 명이 모델과 seed 데이터를 소유한다. 다른 작업자는 repository API만 사용한다. |
| 홈 화면 | `HomeViewModel.swift`, `HomeView.swift` | 중간 | 데이터 모델 PR 이후 작업한다. 알림용 UserDefaults 키 변경은 알림 담당과 합의한다. |
| 퀴즈 | `QuizViewModel.swift`, `QuizView.swift` | 중간 | Home과 같은 repository를 읽되 UI 상태는 Quiz 안에서만 관리한다. |
| 알림 | `FCMNotificationManager.swift`, `FCMService.swift` | 중간 | 서버 TODO 구현은 하지 않는다. 로컬 알림 콘텐츠와 권한 UX만 다룬다. |
| 로컬라이제이션 | `LocalizationHelper.swift`, 각 `Localizable.strings` | 높음 | 기능 PR과 분리해 키 추가/중복 정리를 전담한다. |
| 네트워크 정리 | `WordNetwork.swift`, `NaverNetwork.swift` | 낮음 | MVP 기능 전환 후 선택적으로 비활성화하거나 fallback으로 보존한다. |
| 앱 진입/탭 | `ContentView.swift`, `WordQuizDailyApp.swift` | 낮음 | repository를 environment로 주입할 필요가 생길 때만 수정한다. |

가장 충돌이 나기 쉬운 파일은 `HardKoreanWords.swift`, `QuizViewModel.swift`, `Localizable.strings`다. 특히 `HardKoreanWords.swift`는 긴 배열 파일이므로 MVP 데이터 추가를 이 파일에 직접 누적하기보다 새 파일을 만드는 편이 좋다.

## 후속 이슈 제안

1. 로컬 학습 데이터 모델과 repository 추가
   - 산출물: `LearningWord`, `LearningWordRepository`, 초기 seed 단어 20~50개.
   - 리뷰 기준: 홈/퀴즈/알림이 공통으로 쓸 수 있는 필드가 있고, API 키 없이 테스트 가능해야 한다.

2. 홈 화면을 외국인 학습자용 카드로 전환
   - 산출물: 오늘의 단어, 로마자, 영어 뜻, 쉬운 한국어 설명, 예문, 난이도 표시.
   - 리뷰 기준: 날짜가 바뀌면 단어가 바뀌고, 같은 날짜에는 재실행해도 같은 단어가 유지되어야 한다.

3. 퀴즈를 로컬 데이터와 피드백 기반으로 전환
   - 산출물: 로컬 선택지 생성, 정답/오답 피드백, 다음 문제 전환.
   - 리뷰 기준: 오답 선택 시 정답과 해설이 보이고, 이미지/API 실패와 무관하게 퀴즈가 진행되어야 한다.

4. 알림 콘텐츠를 로컬 학습 데이터 기반으로 정리
   - 산출물: 로컬 오늘의 단어 알림 제목/본문, 저장 키 정리.
   - 리뷰 기준: 서버 API 없이 알림 예약이 가능하고, 저장된 오늘의 단어와 알림 내용이 일치해야 한다.

5. 로컬라이제이션 키 추가와 중복 정리
   - 산출물: 학습 카드/피드백 UI에 필요한 ko/en/ja 키.
   - 리뷰 기준: 새 키가 세 언어 파일에 모두 존재하고, 기존 중복 키로 인한 의도치 않은 표시 변경이 없어야 한다.

6. 원격 API 경로 fallback화 또는 제거 판단
   - 산출물: `WordNetwork`, `NaverNetwork`를 MVP 필수 경로에서 분리.
   - 리뷰 기준: API 키가 없어도 홈과 퀴즈의 핵심 학습 경험이 동작해야 한다.

## 검토 체크리스트

- 앱 시작 후 Home 탭이 로컬 오늘의 단어를 표시하는가?
- 같은 날짜에는 오늘의 단어가 유지되고 날짜 변경 시 갱신되는가?
- Quiz 탭이 API 없이 정답, 선택지, 해설을 만들 수 있는가?
- 오답 선택 시 학습자가 이해할 수 있는 피드백이 표시되는가?
- 알림 본문이 저장된 오늘의 단어와 같은 로컬 데이터에서 생성되는가?
- ko/en/ja 정적 UI 문구가 모두 존재하는가?
- `HardKoreanWords` 직접 참조가 새 repository로 점진적으로 줄어드는가?
- Naver/우리말샘 API 실패가 홈/퀴즈 핵심 화면을 빈 상태로 만들지 않는가?
