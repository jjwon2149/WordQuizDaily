# 외국인 한국어 학습자 MVP

## 목적

WordQuizDaily의 외국인 학습자용 MVP는 기존 오늘의 단어, 퀴즈, 알림 흐름을 유지하면서 학습자가 단어의 뜻과 사용 맥락을 더 쉽게 이해하도록 학습 콘텐츠를 보강하는 작업입니다.

MVP의 핵심 원칙은 로컬 데이터 기반 동작입니다. 서버, 원격 DB, CMS, 계정 기반 학습 기록은 이번 범위에서 제외하고, 앱 번들 또는 로컬 코드에 포함된 샘플 데이터를 기준으로 오늘의 단어와 퀴즈를 구성합니다.

## 유지할 기존 기능

- **오늘의 단어**: 하루에 하나의 단어를 보여주는 홈 화면 흐름을 유지합니다.
- **퀴즈**: 여러 선택지 중 정답 단어를 고르는 기본 퀴즈 흐름을 유지합니다.
- **알림**: 사용자가 알림을 켜고 학습 루틴을 이어갈 수 있는 설정 흐름을 유지합니다.
- **다국어 리소스**: 기존 한국어, 영어, 일본어 로컬라이제이션 파일을 유지합니다.

## MVP에서 바뀌는 점

- 단어 목록은 문자열 배열만 사용하는 방식에서 학습자용 필드를 가진 로컬 모델로 확장합니다.
- 뜻은 외국인 학습자가 이해하기 쉬운 영어 뜻과 쉬운 한국어 설명을 함께 제공합니다.
- 단어마다 로마자 표기, 품사, 난이도, 예문, 예문 영어 번역을 제공합니다.
- 퀴즈 오답 시 단순 정오답 판정만 하는 대신 복습 힌트 또는 오답 피드백을 제공할 수 있게 합니다.
- 네트워크 사전 API 또는 이미지 API가 실패해도 핵심 학습 콘텐츠가 표시되는 구조를 목표로 합니다.

## 범위

### 포함

- 로컬 학습 단어 모델과 샘플 데이터 기준 정의
- 오늘의 단어, 퀴즈, 알림에서 같은 로컬 단어 데이터를 재사용하는 방향 정리
- 외국인 학습자에게 필요한 화면 라벨과 피드백 문구 기준 정리
- 리뷰어가 확인할 QA 항목과 문서 링크 정리

### 제외

- 서버 API, Firebase DB, CMS 연동
- 원격 알림 스케줄링 서버 구현
- 계정, 로그인, 원격 학습 기록 저장
- 전체 단어 데이터셋 구축
- App Store 소개 문구 최종 작성
- 개인정보 처리방침 법무 검토

## 로컬 학습 데이터

오늘의 단어, 퀴즈, 알림은 같은 로컬 학습 단어 데이터를 기준으로 동작해야 합니다. MVP 샘플 데이터는 최소 30개 이상의 단어를 포함하는 것을 목표로 하며, 각 단어는 아래 필드를 갖습니다.

| 필드 | 필수 | 설명 |
| --- | --- | --- |
| `id` | 예 | 단어를 안정적으로 식별하는 고유 값 |
| `korean` | 예 | 학습할 한국어 단어 |
| `romanization` | 예 | 발음 접근성을 위한 로마자 표기 |
| `partOfSpeech` | 예 | 명사, 동사, 형용사 등 품사 |
| `difficulty` | 예 | `beginner`, `intermediate`, `advanced` 등 MVP 난이도 |
| `englishMeaning` | 예 | 가장 짧고 명확한 영어 뜻 |
| `easyKoreanDefinition` | 예 | 쉬운 한국어로 쓴 설명 |
| `exampleKorean` | 예 | 단어가 자연스럽게 쓰이는 한국어 예문 |
| `exampleEnglish` | 예 | 예문의 영어 번역 |
| `incorrectFeedback` | 예 | 오답 시 보여줄 힌트 또는 복습 피드백 |

### 샘플 데이터 형식

```json
{
  "id": "gak-o",
  "korean": "각오",
  "romanization": "gak-o",
  "partOfSpeech": "noun",
  "difficulty": "intermediate",
  "englishMeaning": "determination",
  "easyKoreanDefinition": "어려운 일을 하려고 마음을 단단히 정하는 것",
  "exampleKorean": "시험을 잘 보겠다는 각오로 공부했어요.",
  "exampleEnglish": "I studied with determination to do well on the exam.",
  "incorrectFeedback": "각오는 어떤 일을 하겠다고 마음을 굳게 정하는 뜻이에요."
}
```

## 화면별 적용 기준

### 오늘의 단어

- `korean`, `romanization`, `englishMeaning`, `easyKoreanDefinition`을 우선 표시합니다.
- 예문 영역이 있는 경우 `exampleKorean`과 `exampleEnglish`를 함께 보여줍니다.
- 하루 단어 선택은 기존처럼 로컬 저장소 또는 `UserDefaults`를 활용해 반복 표시를 제어할 수 있습니다.

### 퀴즈

- 정답 단어와 선택지는 같은 로컬 데이터 저장소에서 가져옵니다.
- 문제 설명에는 `easyKoreanDefinition`, `englishMeaning`, `exampleKorean` 중 하나 이상을 사용합니다.
- 오답 피드백에는 `incorrectFeedback`을 사용합니다.

### 알림

- 알림 설정 흐름은 유지합니다.
- MVP 알림 문구는 로컬 단어의 `korean`, `englishMeaning`, `easyKoreanDefinition`을 활용합니다.
- 서버 기반 알림 스케줄링은 MVP 구현 범위에서 제외합니다.

## 관련 문서

- [README](../README.md)
- [문서 인덱스](README.md)
- [현재 구조 분석](foreign-learner-mvp-analysis.md)
- [리뷰어 QA 체크리스트](qa/foreign-learner-mvp-checklist.md)
