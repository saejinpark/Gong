# 공수장 디자인 시스템

코드: `Gong/Design/Theme.swift`(토큰), `Gong/Design/Components.swift`(컴포넌트).
화면 파일은 색·글꼴·간격을 직접 쓰지 않고 `Theme.*`와 아래 컴포넌트만 조립한다.

## 원칙

사용자는 건설 현장의 일용직 근로자다. 장갑을 낀 손, 햇빛 아래의 화면, 돋보기가 필요한 눈을 기본값으로 둔다.

1. **숫자가 주인공.** 화면마다 가장 먼저 봐야 할 금액 하나를 `HeroCard`로 크게 보여준다. 나머지는 그 아래 목록이다.
2. **한 손, 한 번.** 매일 반복하는 행동(오늘 1공수 기록)은 홈 상단의 `BigActionButton` 하나로 끝난다. 길게 누르기와 밀기는 지름길일 뿐, 모든 기능은 버튼으로도 닿아야 한다.
3. **색은 뜻을 가진다.** 초록은 받은 돈·정상 공수, 주황은 아직 못 받음·주의, 빨강은 세금·공휴일·삭제, 파랑은 토요일·잔업. 현장 색은 구분용이며 상태를 뜻하지 않는다.
4. **시스템 글자 크기를 따른다.** 고정 pt 글꼴을 쓰지 않는다(달력 셀의 공휴일 이름 9pt만 예외). 터치 영역은 44pt 이상.
5. **라이트·다크 모두 1급.** 면 색은 시스템 그룹 배경 토큰을 쓰고, 브랜드색 위의 글자는 항상 흰색이다.

## 토큰

### 색 `Theme.Colors`

| 토큰 | 값 | 쓰임 |
|---|---|---|
| `brand` | AccentColor (#FFA500) | 히어로 카드, 선택 상태, 링크 버튼 |
| `brandSoft` | brand 14% | 선택된 날짜 배경 |
| `onBrand` | white | 브랜드색 위 글자 |
| `inverseSurface` / `onInverse` | label / systemBackground | 주요 행동 버튼 (히어로와 겹치지 않게) |
| `positive` | 초록 | 입금 완료, 1공수 배지 |
| `warning` | 주황 | 미입금, 태그 칩 |
| `danger` | 빨강 | 세금, 삭제, 2공수 이상 |
| `saturday` | 파랑 | 토요일, 1.5공수 |
| `holiday` | = danger | 일요일·공휴일 |
| `background` / `surface` / `surfaceInset` | systemGrouped 계열 | 화면 / 카드 / 카드 안 버튼 |
| `manUnit(_:)` | 공수 → 색 | 0 회색, 0.5 연회색, 1 초록, 1.5 파랑, 2+ 빨강 |
| `sitePalette`, `site(_:)` | 8색 | 현장 구분 점 (`Site.colorIndex`) |

### 글꼴 `Theme.Fonts`

숫자는 `design: .rounded` + `.monospacedDigit()`로 흔들리지 않게.

| 토큰 | 스타일 | 쓰임 |
|---|---|---|
| `heroAmount` | largeTitle rounded bold | HeroCard 금액 |
| `amountLarge` | title2 rounded bold | StatTile 값, 시트의 실수령액 |
| `amount` / `amountSmall` | body / subheadline rounded semibold | 행 안의 금액 |
| `title` | title3 bold | 섹션 제목 |
| `headline`, `label`, `caption`, `caption2` | 시스템 | 본문 위계 |
| `badge` | caption2 rounded bold | 달력 공수 배지 |
| `dayNumber` | footnote rounded | 달력 날짜 |

### 간격·모서리

`Spacing` 4/8/12/16/24, `Radius` 6/12/16, 카드는 16pt continuous, 칩은 캡슐. `Theme.minTapTarget = 44`.

## 컴포넌트

| 컴포넌트 | 역할 | 쓰는 곳 |
|---|---|---|
| `GCard` | 기본 카드 | 안내 문구, 요약 |
| `HeroCard` | 큰 금액 + 설명 + 칩 (그라데이션) | 달력 상단, 정산 상단, 현장 상세(현장 색) |
| `StatTile` | 작은 통계 | 주간 모드 이번 주/이번 달 |
| `MoneyText` | 금액 (plain/positive/negative/emphasis) | 모든 금액 |
| `KeyValueRow` | 라벨—값 한 줄 | 월간 요약 카드 |
| `ManUnitBadge` | 공수 배지 (compact=달력 셀) | 달력, 기록 행 |
| `PaidBadge` | 입금완료/미입금 | 기록 행 |
| `TagChip` | 짧은 라벨 (filled/outline) | 태그, 세금 방식, 히어로 안 요약 |
| `SiteDot`, `SiteLabel` | 현장 색 점 / 점+이름 | 달력 셀, 현장 목록, 기록 행 |
| `BigActionButton` | 화면의 주요 행동 1개 | 오늘 1공수 기록 |
| `ChoiceButton` | 선택 가능한 버튼 (프리셋) | 공수 프리셋 |
| `SectionTitle` | 섹션 제목 + 우측 액션 | 스크롤 화면 |
| `EmptyStateView` | 빈 상태 + 행동 | 기록 없음 |
| `EntryRow` | 공수 기록 한 줄 | 달력 주간, 현장 상세, 정산, 미입금 |

## 화면 구성 규칙

- **홈(공수)**: HeroCard(이번 달 실수령) → 오늘 기록 CTA(오늘 기록이 없을 때만) → 달력 카드 → 월간 요약 카드. 달력 셀은 날짜·현장 점·공휴일 이름·공수 배지(미입금이면 주황 점).
- **정산**: 월 선택 → 못 받은 돈 링크 → HeroCard → 금액/입금/현장별/일별/날씨/연간.
- **현장 상세**: 현장 색 HeroCard → 정보 → 월별 기록.
- **시트(Form)**: 시스템 Form을 쓰되 프리셋은 `ChoiceButton`, 실수령액은 `MoneyText(.emphasis, amountLarge)`.

## 새 화면을 만들 때

1. 가장 중요한 숫자가 무엇인지 정하고 HeroCard 또는 StatTile로 올린다.
2. 색은 `Theme.Colors`에서만 고른다. 새 색이 필요하면 토큰을 먼저 추가한다.
3. 금액은 `MoneyText`, 공수는 `ManUnitBadge`, 현장은 `SiteLabel`을 쓴다.
4. 라이트·다크, 글자 크기 "더 크게(AX1)"에서 한 번씩 확인한다.
