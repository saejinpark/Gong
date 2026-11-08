# 공수장 (Gong)

건설 일용직 근로자를 위한 공수 기록·정산 앱입니다. 달력에 공수를 찍고, 현장별 단가와 세금 방식으로 실수령액을 계산하고, 못 받은 돈을 추적하고, 정산 내용을 카톡이나 엑셀로 보냅니다.

- 플랫폼: iOS 17.0 이상 (iPhone, iPad)
- 기술: SwiftUI, SwiftData (기기 내 저장, 서버·로그인 없음)
- 번들 ID: `dev.geppetto.Gong`

## 기능

**공수 탭 (달력)**
- 날짜를 누르면 그 주가 펼쳐지고 그날 기록을 바로 추가·수정
- 날짜를 길게 누르면 최근 현장으로 1공수 즉시 기록
- 좌우로 밀어 달 이동, 오늘로 돌아가기 버튼
- 공휴일 이름 표시 (2025~2028년, 노동절·제헌절·대체공휴일 포함)
- 월간 요약: 총 공수·근무일, 일당·수당·세금·실수령, 미입금

**공수 입력**
- 0 / 0.5 / 1 / 1.5 / 2 프리셋 + 0.5 단위 스테퍼
- 현장을 고르면 단가·식대·세금 방식이 자동으로 채워짐
- 평일·토요일·공휴일 구분 자동 판별, 직접 변경 가능
- 여러 날 한 번에 기록 (예: 이번 주 월~금 전부 1공수)
- 식대·숙박비·교통비(비과세), 날씨, 태그(우천중단·조기퇴근 등), 메모, 입금 확인

**세금 계산 (현장·기록마다 선택)**
- 일용직 세금: 하루 15만원 공제 후 2.7% (6% × 55% 세액공제 적용) + 지방소득세 10%, 1,000원 미만 소액부징수
- 3.3% 공제: 사업소득 처리 현장
- 공제 없음
- 10원 미만 절사

**현장 탭**
- 현장별 단가, 기본 식대, 세금 방식, 위치, 메모, 진행중/종료
- 이번 달 공수, 누적 공수·실수령, 미입금 금액, 월별 기록

**정산 탭**
- 월 선택 → 공수 요약, 금액 정산, 입금 현황, 현장별 집계, 일별 기록, 날씨별 근무, 연간 합계
- 못 받은 돈 모아보기: 전체 미입금을 현장별로 묶어 보고 한 번에 입금 완료 처리
- 공유: 정산 내용을 카카오톡 등으로 보낼 수 있는 글, 엑셀(CSV) 파일

**설정 탭**
- 새 현장 기본값(세금 방식, 단가, 식대)
- 세금 계산 설명과 일당별 예시
- 백업 파일 내보내기/복원 (JSON), 모든 기록 삭제

## 프로젝트 구조

```
Gong/
├── GongApp.swift            앱 진입점, ModelContainer, -seedDemo 처리
├── ContentView.swift        탭 구성
├── Model/                   Site, WorkEntry(SwiftData), TaxMode, DayType, WeatherCondition, WorkTag
├── Service/
│   ├── PayCalculator.swift  일당·세금·실수령 계산
│   ├── HolidayService.swift 공휴일 데이터와 요일 구분
│   ├── SettlementExporter   정산 글·CSV 생성
│   ├── BackupService.swift  JSON 백업/복원
│   └── DemoData.swift       스크린샷용 샘플 데이터
├── View/
│   ├── Calendar/            CalendarView, EntryRow
│   ├── Entry/               WorkEntrySheetView
│   ├── Site/                SiteListView, SiteDetailView, SiteFormView
│   ├── Settlement/          SettlementView, UnpaidListView
│   ├── Settings/            SettingsView
│   └── Shared/              ActivityView
├── Extension/               Calendar+Month, Formatting
└── PrivacyInfo.xcprivacy    개인정보 매니페스트 (UserDefaults CA92.1)
```

## 개발

Xcode 16 이상에서 `Gong.xcodeproj`를 열어 실행합니다.

스크린샷이나 테스트용 샘플 데이터가 필요하면 스킴의 실행 인자에 `-seedDemo`를 추가하세요. 기록이 하나도 없을 때만 샘플을 넣습니다. `-inMemory`를 함께 주면 디스크에 남기지 않습니다.

```bash
xcrun simctl launch booted dev.geppetto.Gong -seedDemo
```

### 데이터 모델 변경 시

`Site`, `WorkEntry`에 속성을 추가할 때는 기본값을 반드시 지정해야 기존 사용자의 데이터가 자동 마이그레이션됩니다 (`taxModeRaw`, `createdAt`, `defaultMealAllowance`가 그 예).

### 공휴일 갱신

`HolidayService.holidays`에 연도별 날짜를 추가하고 `lastSupportedYear`를 올립니다. 설·추석·부처님오신날·대체공휴일은 매년 인사혁신처 발표를 확인하세요.

## 스토어 제출

[docs/AppStore.md](docs/AppStore.md)에 설명문, 키워드, 개인정보 응답, 심사 메모 초안이 있습니다.

## 라이선스

개인 프로젝트입니다. 문의는 GitHub 이슈로 남겨 주세요.
