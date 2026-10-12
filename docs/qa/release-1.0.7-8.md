# 우리말 단어 퀴즈 1.0.7 (8) TestFlight

2026-10-12 사용자 요청에 따라 기존 1.0.6 (7) 작업본의 학습·복습·알림·번역·위젯 변경을 광고 수정과 함께 검증해 배포했다.

- 소스 커밋: `369701d`; 관련 QA/CI 문서 커밋: `f85124f`. main에서 일반 커밋 및 push, 불필요한 병합 커밋이나 force push 없음.
- 앱·위젯: 1.0.6 (7) → 1.0.7 (8), 기존 앱 식별자와 서명 유지.
- 추가 수정: 알림 권한 결과를 `DispatchQueue.main`에서 받아 ObservableObject 화면 상태를 갱신한다.
- 커밋 범위: 학습/알림/번역/광고 소스, LearningCore 콘텐츠·테스트, 프로젝트 연결, 관련 CI·문서 36개. 비공개 설정, 빌드·캐시·생성 스크린샷, .omo/AGENTS 자료와 기존 PR 템플릿 변경은 제외해 보존.
- LearningCore 실제 XCTest: 22 PASS, 실패 0. 저장·마이그레이션·손상 보호·복습·중복 제출·날짜·출제·콘텐츠·알림 정책 검증.
- 앱 Debug simulator build 및 위젯 독립 build: PASS. ko/en/ja 문자열 각 165개 중복 키 없음, plist 검사와 diff check PASS.
- 기존 네트워크 없는 배너 소스 모형: 320×50 및 폭/로딩/실패 상태 검증 PASS.
- Release archive: PASS. 앱/위젯 bundle ID·1.0.7(8), 위젯 포함, LearningCore 리소스, 기존 프로덕션 광고 설정, 코드서명 검증 PASS.
- 아카이브: `/tmp/banner-release-WordQuizDaily.xcarchive`.
- TestFlight 업로드: `Upload succeeded`, `Uploaded WordQuizDaily`, `EXPORT SUCCEEDED`, exit 0. 서버 처리 완료 후 1.0.7 (8) 빌드 행을 확인했다. 상태는 **수출 규정 관련 문서 누락**이며 법적 신고 응답 제출과 설치 가능 상태 확인이 남았다.
- Firebase/Google SDK 6개 프레임워크의 dSYM 누락 경고가 있었으나 업로드는 성공했다. SDK 내부 충돌 심볼 해석이 제한될 수 있다.
- 실제 알림 권한/예약 및 오답→재실행→복습의 화면 조작, 큰 글자·VoiceOver, TestFlight 신규/업데이트 설치는 미검증. 공통 모델 테스트나 빌드 성공으로 해당 UI/실기기 검증까지 완료했다고 표현하지 않는다.
- 새 인증정보 생성, 법적 신고 응답 저장, 정식 심사 제출, 테스터 그룹 변경은 하지 않았다. 사진 앱 두 개의 수출 규정 응답도 계속 보류했다.

[소스 CI](https://github.com/jjwon2149/WordQuizDaily/actions/runs/38236844123) · [TestFlight](https://appstoreconnect.apple.com/apps/6505052767/testflight/ios)

- GitHub 소스 CI `38236844123`: LearningCore 테스트 및 앱·위젯 빌드 모두 success. 소스와 기존 버전 기능을 함께 검증했다.
- 추가 법적 신고 질문: “앱에서 구현하는 암호화 알고리즘의 유형은 무엇입니까?” 선택지는 독점/비표준, OS 암호화를 대체·병행하는 표준, 둘 다, 둘 다 해당 없음이다. 아무 항목도 선택·저장하지 않았다.
- 실제 빌드: https://appstoreconnect.apple.com/teams/57b5af6f-fd06-4d73-b5c6-8fffb114123e/apps/6505052767/testflight/ios/c6e8ed86-5b49-4354-aac4-f7afb48cdc93
