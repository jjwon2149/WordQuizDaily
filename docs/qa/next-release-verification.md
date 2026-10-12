# 다음 배포 구현 및 검증 기록

2026-09-30 실행 기록. 이 문서는 [배포 계획](../next-release-plan.md)의 구현 근거와 아직 확인하지 못한 배포 조건을 구분한다.

## 실행 환경

- Xcode 27.0, build 27A266a. 이전 계획 작성 시의 라이선스 미동의 문제는 현재 재현되지 않았다.
- iOS 18.5 iPhone SE 시뮬레이터 부팅 확인. 실제 iPhone 및 TestFlight 검증과는 별개다.
- CodeGraph 도구와 CLI는 현재 세션에서 발견하지 못해 파일 검색으로 변경 범위를 조사했다. SourceKit-LSP 실행 파일은 존재한다.
- 시작 시 기존 변경: `docs/README.md`, 미추적 `.omo/`, 각 `AGENTS.md`, `docs/next-release-plan.md`. 기존 작업을 보존한다.

## 진행 상태

- 구현: 공통 로직·콘텐츠·알림·화면 연결 반영. 별도 Sol Medium 통합 리뷰에서 남은 HIGH/MEDIUM 결함 없음으로 확인했다.
- 콘텐츠: 66개(초급 20·중급 25·고급 21), 기존 40개 ID 유지. 별도 Sol Medium 편집 검토와 수정 반영 확인. [상세 검토](learning-content-review.md). 외부 언어 전문가 인증과는 구분한다.
- 핵심 테스트: 실제 XCTest 22개 통과, 실패 0개. 아래 임시 빌드 경로 명령으로 확인했다.
- 앱 및 위젯: 각각 독립 simulator build에서 `BUILD SUCCEEDED` 확인. 프로젝트 파일 plist 검사도 통과했다.
- 시뮬레이터: iOS 18.5 iPhone SE에서 앱 설치·실행 및 ko/en/ja 홈 화면을 확인했다. 세 번 재실행 후에도 신규 사용자 beginner 설정이 유지됐다. 영어 난이도·품사 간격 문제 수정 후 재확인했다.
- 호스팅된 CI 실행, 실기기 권한·알림, TestFlight 업데이트 설치, App Store 제출: 미실행.

## 실행한 검사

```sh
swift test --package-path WordQuizDaily/Packages/LearningCore --scratch-path /tmp/wordquiz-learningcore-final
xcodebuild -workspace WordQuizDaily/WordQuizDaily.xcworkspace -scheme WordQuizDaily -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wordquiz-derived build CODE_SIGNING_ALLOWED=NO
xcodebuild -workspace WordQuizDaily/WordQuizDaily.xcworkspace -scheme WordQuizWidgetExtension -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wordquiz-widget-derived build CODE_SIGNING_ALLOWED=NO
```

- 22 XCTest tests, 0 failures, 0 unexpected. 최종 재실행 시간 0.379초(빌드 시간 제외).
- 실제 번들 전체 단어 출제, 수준·품사·의미 충돌, 최근 문제 제외, 날짜·시간대·DST·기존 캐시, 저장·재로딩·버전 이전·오답 해제·중복 제출, 손상 및 미래 버전 보호를 확인했다.
- 기본 `.build` 경로는 FileProvider Finder 메타데이터로 생성 번들 CodeSign이 실패했다. 임시 경로에서 깨끗하게 빌드해 통과했으며, 기본 명령 통과로 바꾸어 기록하지 않는다.
- 한국어·영어·일본어 리소스 각 165개 키에서 중복 키 없음. 화면 렌더링 검증과는 별개다.
- 변경 파일 `git diff --check` 및 프로젝트 `plutil -lint` 통과.
- 최종 로그: `/tmp/wordquiz-learningcore-test.log`, `/tmp/wordquiz-app-build.log`, `/tmp/wordquiz-widget-build.log`.
- 빌드 경고: QuizViewModel 및 WordNetwork의 Swift 6 sendability 캡처 경고가 남아 있다. 오류는 없으며, 이번 기록으로 기존 여부를 단정하지 않는다.
- 패키지 핀 차이: workspace의 Google Mobile Ads 12.14.0 / UMP 3.1.0과 project의 12.8.0 / 3.0.0. workspace 기준 빌드를 사용하며 자동 업그레이드는 하지 않는다.

## 화면 증거

- 한국어 홈: 로컬 QA 자료 `AppStoreScreenshots/NextReleaseQA/home-ko.png` (생성 이미지로 이번 커밋에서 제외).
- 영어 홈: 로컬 QA 자료 `AppStoreScreenshots/NextReleaseQA/home-en.png` (생성 이미지로 이번 커밋에서 제외).
- 일본어 홈: 로컬 QA 자료 `AppStoreScreenshots/NextReleaseQA/home-ja.png` (생성 이미지로 이번 커밋에서 제외).

이 이미지는 홈 최초 화면의 시뮬레이터 QA 자료이며 App Store 제출용 최종 스크린샷이 아니다. Debug 테스트 광고가 표시된다. 답변 버튼·복습 완료·초기화·알림 권한을 실제 조작한 증거로 사용하지 않는다.

## 남은 검증과 계획 차이

- 앱 어댑터 XCTest 및 XCUITest 타깃은 추가하지 않았다. 공통 패키지 테스트는 앱 UI 및 실제 알림 시스템의 통합 동작을 대신하지 않는다. 계획의 어댑터 테스트 조건은 미완료다.
- CUA의 허용 앱 목록에서 Simulator를 사용할 수 없어 화면 클릭 기반 QA를 수행하지 못했다. simctl 설치·실행·스크린샷 확인만 수행했다.
- 실제 오답 제출부터 재실행·복습 해제까지의 UI 시나리오, 기록 초기화·저장 실패 UI, 오프라인 기기 시나리오, 자정 위젯 표시, 큰 글자·VoiceOver, 알림 권한 및 예약은 추가 검증이 필요하다.
- 호스팅된 CI는 설정만 추가했으며 실행 결과를 확인하지 않았다.
- 사용자 요청으로 업로드 이력을 확인하고 앱·위젯을 1.0.6 (7)로 변경했다. Release archive 및 TestFlight 업로드는 완료했다. TestFlight 신규·업데이트 설치와 App Store 심사 제출은 미실행이다.

## 릴리스 노트 초안

- 틀린 단어를 저장하고 짧은 복습으로 다시 학습할 수 있습니다.
- 수준별 퀴즈와 동사·형용사를 포함한 학습 콘텐츠를 추가했습니다.
- 홈에서 오늘 푼 문제와 복습할 단어를 확인할 수 있습니다.
- 위젯의 날짜별 단어와 학습 알림 처리를 개선했습니다.

아직 배포되지 않은 변경의 초안이며 제출 전 실제 QA 결과와 일치하는지 확인합니다.

## 배포 판단

로컬 구현과 핵심 자동 검증은 진행됐으나 배포 준비 완료로 판정하지 않는다. 위 미실행 조건을 확인한 뒤 제출 후보를 확정해야 한다. 코드 커밋·푸시·App Store 심사 제출은 수행하지 않았다. TestFlight 업로드는 아래 후속 기록과 같이 완료했다.

## TestFlight 업로드 후속 기록

2026-09-30 22:23 KST, 사용자 요청으로 버전 및 빌드 번호를 올리고 업로드했다.

- 기존 최신 업로드: 1.0.5 (6), App Store Connect에서 확인.
- 새 앱 및 위젯: 모두 1.0.6 (7).
- 아카이브 점검에서 기존 Embed Foundation Extensions 단계가 비어 있어 위젯이 앱에 포함되지 않는 문제를 발견했다. 위젯 포함 설정을 수정하고 재아카이브했다. 최종 아카이브의 PlugIns에 위젯이 포함되며 두 버전·빌드가 일치함을 확인했다.
- 최종 Release archive 성공, 업로드 로그의 Upload succeeded 및 EXPORT SUCCEEDED 확인.
- App Store Connect TestFlight 목록에 1.0.6 (7)이 등록됐으며 확인 시점 상태는 처리 중.
- Firebase 및 Google 배포 SDK 6개 프레임워크의 dSYM 누락 경고가 있었다. 업로드는 성공했으나 해당 SDK 내부 충돌의 심볼 분석이 제한될 수 있다.
- 아카이브: `/tmp/WordQuizDaily-1.0.6-7-complete.xcarchive`.
- 테스터 초대·그룹 변경·외부 테스트 심사·App Store 심사 제출은 수행하지 않았다.
