# 공수장 디자인 시스템 "현장"

코드: `Gong/Design/Theme.swift`(토큰), `Gong/Design/Components.swift`(컴포넌트).
화면 파일은 색·글꼴·간격을 직접 쓰지 않고 `Theme.*`와 아래 컴포넌트만 조립한다.

## 콘셉트

**안전 조끼 노랑, 먹물 같은 차콜, 작업일지 종이.** 그리고 공수를 세는 방식 그대로의 **工(장인 공)** — 공수의 공이자 H빔 단면.

- 아이콘: 형광 노랑 바탕에 잉크색 工(90도 돌린 H빔 단면), 아래에 공사장 안전 띠(사선 줄무늬). 글자가 아니라 강재 기호로 읽히도록 모서리만 살짝 둥글렸다.
- 히어로 카드: 잉크 바탕 위 노랑 숫자, 윗선에 안전 띠. 이 달에 얼마 벌었는지가 가장 먼저 보인다.
- 달력: 일한 날은 현장 색으로 칠해진 "도장"처럼 보이고, 공수 숫자가 그 위에 찍힌다.
- 바탕은 흰색이 아니라 종이색(F4F1EA). 카드는 흰색으로 떠오른다. 다크 모드는 깊은 밤색에 같은 노랑.

## 원칙

사용자는 건설 현장의 일용직 근로자다. 장갑을 낀 손, 햇빛 아래의 화면, 돋보기가 필요한 눈을 기본값으로 둔다.

1. **숫자가 주인공.** 화면마다 가장 먼저 봐야 할 금액 하나를 `HeroCard`로 크게 보여준다.
2. **한 손, 한 번.** 매일 반복하는 행동(오늘 1공수 찍기)은 홈 상단의 노랑 `BigActionButton` 하나로 끝난다. 길게 누르기와 밀기는 지름길일 뿐, 모든 기능은 버튼으로도 닿아야 한다.
3. **노랑은 면, 글자는 잉크.** 형광 노랑 위에 흰 글자를 올리지 않는다. 흰 바탕 위 링크·탭 색은 진한 호박색(`accentText`)을 쓴다(라이트), 다크에서는 노랑 그대로.
4. **색은 뜻을 가진다.** 초록=받은 돈·정상 공수, 주황=아직 못 받음, 빨강=세금·공휴일·삭제, 파랑=토요일·잔업. 현장 색은 구분용이며 상태를 뜻하지 않는다.
5. **시스템 글자 크기를 따른다.** 고정 pt 글꼴은 달력 셀의 공휴일 이름(9pt)뿐. 터치 영역은 44pt 이상. 글꼴은 전부 SF Rounded.

## 토큰

### 색 `Theme.Colors`

| 토큰 | 라이트 | 다크 | 쓰임 |
|---|---|---|---|
| `brand` | #FFC400 | #FFC400 | 주요 행동 버튼, 선택된 날짜, 미입금 알림 카드 (면으로만) |
| `onBrand` | #1C1C1E | #1C1C1E | 노랑 위 글자 |
| `brandSoft` | 노랑 18% | 노랑 22% | 선택 배경 |
| `accentText` | #9A6400 | #FFC400 | 링크, 탭 선택, 툴바 (= Assets AccentColor) |
| `ink` / `onInk` / `onInkAccent` | #1C1C1E / 흰색 / #FFC400 | #26262B / 흰색 / #FFC400 | 히어로 카드 |
| `positive` | #1E8E4A | #3DD172 | 입금 완료, 1공수 |
| `warning` | #D9771B | #FF9F3D | 미입금, 태그 |
| `danger` | #D93025 | #FF6B5E | 세금, 삭제, 2공수+ |
| `saturday` | #2563EB | #6FA3FF | 토요일, 1.5공수 |
| `holiday` | = danger | | 일요일·공휴일 |
| `background` | #F4F1EA 종이 | #0F0F11 | 화면 바탕 |
| `surface` | #FFFFFF | #1C1C1F | 카드 |
| `surfaceInset` | #EFEBE2 | #2A2A2E | 카드 안 버튼 |
| `textPrimary/Secondary/Tertiary` | 1C1C1E / 6B675F / B5B0A6 | F2F2F5 / A6A6AE / 5C5C64 | 글자 위계 |
| `manUnit(_:)` | 공수 → 색 | | 0 회색, 0.5 연회색, 1 초록, 1.5 파랑, 2+ 빨강 |
| `sitePalette`, `site(_:)` | 8색 | | 현장 구분 (`Site.colorIndex`) |

### 글꼴 `Theme.Fonts` (모두 `design: .rounded`)

| 토큰 | 스타일 | 쓰임 |
|---|---|---|
| `heroAmount`, `screenTitle` | largeTitle heavy | 히어로 금액, 홈 "11월" |
| `amountLarge` | title2 bold | StatTile, 시트 실수령액 |
| `amount` / `amountSmall` | body / subheadline bold | 행 금액 |
| `title` | title3 bold | 카드 제목 |
| `headline`, `label`, `caption`, `caption2` | 시스템 | 본문 위계 |
| `badge` | caption2 heavy | 달력 공수 배지 |
| `dayNumber` | subheadline semibold | 달력 날짜 |

### 간격·모서리

`Spacing` 4/8/12/16/24, `Radius` 8/14/22, 카드는 22pt continuous, 칩은 캡슐. `Theme.minTapTarget = 44`.

## 컴포넌트

| 컴포넌트 | 역할 | 쓰는 곳 |
|---|---|---|
| `HazardStripe` | 안전 띠 장식 | HeroCard 윗선 |
| `GCard` | 기본 카드 | 안내 문구 |
| `HeroCard` (`.ink` / `.color`) | 큰 금액 + 설명 + 칩 | 홈, 정산, 현장 상세(현장 색) |
| `InkChip` | 히어로 위 칩 | 세금·미입금·일당 요약 |
| `ScreenHeader`, `RoundIconButton` | 직접 그리는 화면 헤더 | 홈 "11월 2026" ‹ › |
| `StatTile` | 작은 통계 | 주간 모드 |
| `MoneyText` | 금액 (plain/positive/negative/emphasis) | 모든 금액 |
| `KeyValueRow` | 라벨—값 한 줄 | 월간 요약 카드 |
| `ManUnitBadge` | 공수 배지 (compact=달력 도장) | 달력, 기록 행 |
| `PaidBadge`, `TagChip` | 상태·태그 | 기록 행 |
| `SiteDot`, `SiteLabel` | 현장 색 | 목록, 행 |
| `BigActionButton` | 노랑 주요 행동 | 오늘 1공수 찍기 |
| `ChoiceButton` | 선택 버튼 | 공수 프리셋 |
| `SectionTitle`, `EmptyStateView` | 섹션·빈 상태 | 전반 |
| `EntryRow` | 기록 한 줄 (왼쪽 현장 색 막대) | 주간, 현장 상세, 정산, 미입금 |
| `.gongListBackground()` | List/Form을 종이 바탕 위로 | 모든 리스트 화면 |

## 화면 구성 규칙

- **홈(공수)**: 시스템 내비게이션 바를 숨기고 `ScreenHeader`("11월" 크게 + 연도) → 잉크 HeroCard → 오늘 찍기 노랑 버튼(오늘 기록이 없을 때만) → 달력 카드(도장 셀) → 월간 요약 카드.
- **정산**: 월 선택 → 노랑 "못 받은 돈" 카드 → 잉크 HeroCard → 금액/입금/현장별/일별/날씨/연간.
- **현장 상세**: 현장 색 HeroCard → 정보 → 월별 기록. 목록 행은 왼쪽에 현장 색 막대.
- **시트(Form)**: 시스템 Form + 종이 바탕, 프리셋은 `ChoiceButton`, 실수령액은 `MoneyText(.emphasis, amountLarge)`.

## 새 화면을 만들 때

1. 가장 중요한 숫자가 무엇인지 정하고 HeroCard 또는 StatTile로 올린다.
2. 색은 `Theme.Colors`에서만 고른다. 새 색이 필요하면 토큰을 먼저 추가한다. 노랑 위에 흰 글자 금지.
3. 금액은 `MoneyText`, 공수는 `ManUnitBadge`, 현장은 `SiteLabel`/색 막대를 쓴다.
4. 라이트·다크, 글자 크기 "더 크게(AX1)"에서 한 번씩 확인한다.
