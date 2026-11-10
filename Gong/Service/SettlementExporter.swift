//
//  SettlementExporter.swift
//  Gong
//
//  월별 정산을 카톡으로 보낼 수 있는 글과 CSV(엑셀)로 만든다.
//

import Foundation

struct MonthlySummary {
    let month: Date
    let entries: [WorkEntry]

    var workDays: Int { Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count }
    var manUnit: Double { entries.reduce(0) { $0 + $1.manUnit } }
    var taxable: Int { entries.reduce(0) { $0 + $1.taxableAmount } }
    var allowance: Int { entries.reduce(0) { $0 + $1.allowanceTotal } }
    var tax: Int { entries.reduce(0) { $0 + $1.tax } }
    var net: Int { entries.reduce(0) { $0 + $1.netAmount } }
    var unpaid: [WorkEntry] { entries.filter { !$0.isPaid } }
    var unpaidAmount: Int { unpaid.reduce(0) { $0 + $1.netAmount } }

    struct SiteLine {
        let name: String
        let days: Int
        let manUnit: Double
        let net: Int
        let unpaid: Int
    }

    var siteLines: [SiteLine] {
        Dictionary(grouping: entries) { $0.site?.name ?? Format.unassignedSite }
            .map { name, list in
                SiteLine(
                    name: name,
                    days: list.count,
                    manUnit: list.reduce(0) { $0 + $1.manUnit },
                    net: list.reduce(0) { $0 + $1.netAmount },
                    unpaid: list.filter { !$0.isPaid }.reduce(0) { $0 + $1.netAmount }
                )
            }
            .sorted { $0.manUnit != $1.manUnit ? $0.manUnit > $1.manUnit : $0.name < $1.name }
    }
}

enum SettlementExporter {

    /// 정산 문구에 쓰는 표현. `korean`이면 화면 언어와 상관없이 한국어로 만든다
    /// (외국인 근로자가 한국인 반장·사장님께 보낼 때).
    private struct Words {
        let korean: Bool

        private static let koLocale = Locale(identifier: "ko_KR")
        private static let koMonth: DateFormatter = {
            let f = DateFormatter(); f.locale = koLocale; f.dateFormat = "yyyy년 M월"; return f
        }()
        private static let koDay: DateFormatter = {
            let f = DateFormatter(); f.locale = koLocale; f.dateFormat = "M/d(E)"; return f
        }()

        func won(_ v: Int) -> String {
            korean ? "\(v.formatted(.number.locale(Self.koLocale)))원" : Format.won(v)
        }
        func gongsu(_ v: Double) -> String { korean ? "\(Format.manUnit(v))공수" : Format.gongsu(v) }
        func days(_ n: Int) -> String { korean ? "\(n)일" : Format.days(n) }
        func count(_ n: Int) -> String { korean ? "\(n)건" : Format.count(n) }
        func month(_ d: Date) -> String { korean ? Self.koMonth.string(from: d) : Format.monthTitle.string(from: d) }
        func day(_ d: Date) -> String { korean ? Self.koDay.string(from: d) : Format.shortDay.string(from: d) }
        func site(_ name: String) -> String { korean && name == Format.unassignedSite ? "현장 미지정" : name }
        func tag(_ t: WorkTag) -> String { korean ? t.rawValue : t.title }

        func header(_ month: String) -> String { korean ? "[공수장] \(month) 정산" : String(localized: "[공수장] \(month) 정산") }
        func total(_ g: String, _ d: String) -> String { korean ? "총 \(g) · \(d) 근무" : String(localized: "총 \(g) · \(d) 근무") }
        func taxable(_ w: String) -> String { korean ? "일당 합계 \(w)" : String(localized: "일당 합계 \(w)") }
        func allowance(_ w: String) -> String { korean ? "수당 합계 +\(w)" : String(localized: "수당 합계 +\(w)") }
        func tax(_ w: String) -> String { korean ? "세금 -\(w)" : String(localized: "세금 -\(w)") }
        func net(_ w: String) -> String { korean ? "실수령액 \(w)" : String(localized: "실수령액 \(w)") }
        func unpaid(_ c: String, _ w: String) -> String { korean ? "미입금 \(c) \(w)" : String(localized: "미입금 \(c) \(w)") }
        var bySite: String { korean ? "■ 현장별" : String(localized: "■ 현장별") }
        var byDay: String { korean ? "■ 일별" : String(localized: "■ 일별") }
        func unpaidNote(_ w: String) -> String { korean ? " (미입금 \(w))" : String(localized: " (미입금 \(w))") }
        var unpaidMark: String { korean ? " (미입금)" : String(localized: " (미입금)") }
    }

    /// 카카오톡 등으로 바로 보낼 수 있는 정산 문자
    static func text(for summary: MonthlySummary, includeDaily: Bool = true, korean: Bool = false) -> String {
        let w = Words(korean: korean || Format.isKorean)
        var lines: [String] = []
        lines.append(w.header(w.month(summary.month)))
        lines.append("")
        lines.append(w.total(w.gongsu(summary.manUnit), w.days(summary.workDays)))
        lines.append(w.taxable(w.won(summary.taxable)))
        if summary.allowance > 0 {
            lines.append(w.allowance(w.won(summary.allowance)))
        }
        if summary.tax > 0 {
            lines.append(w.tax(w.won(summary.tax)))
        }
        lines.append(w.net(w.won(summary.net)))
        if !summary.unpaid.isEmpty {
            lines.append(w.unpaid(w.count(summary.unpaid.count), w.won(summary.unpaidAmount)))
        }

        let sites = summary.siteLines
        if sites.count > 1 || sites.first?.name != Format.unassignedSite {
            lines.append("")
            lines.append(w.bySite)
            for s in sites {
                var line = "\(w.site(s.name)): \(w.gongsu(s.manUnit)) · \(w.days(s.days)) · \(w.won(s.net))"
                if s.unpaid > 0 { line += w.unpaidNote(w.won(s.unpaid)) }
                lines.append(line)
            }
        }

        if includeDaily {
            lines.append("")
            lines.append(w.byDay)
            for e in summary.entries.sorted(by: { $0.date < $1.date }) {
                var line = "\(w.day(e.date)) "
                if let site = e.site?.name { line += "\(site) " }
                line += "\(w.gongsu(e.manUnit)) \(w.won(e.netAmount))"
                if let tag = e.workTag { line += " [\(w.tag(tag))]" }
                if !e.memo.isEmpty { line += " - \(e.memo)" }
                line += e.isPaid ? " ✓" : w.unpaidMark
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n")
    }

    /// 엑셀에서 열리는 CSV (BOM 포함, 한글 깨짐 방지)
    static func csv(for entries: [WorkEntry]) -> String {
        let header = [
            String(localized: "날짜"), String(localized: "요일구분"), String(localized: "현장"),
            String(localized: "공수", comment: "CSV 열 이름: 공수 수량"), String(localized: "단가"),
            String(localized: "일당"), String(localized: "식대"), String(localized: "숙박비"),
            String(localized: "교통비"), String(localized: "세금방식"), String(localized: "소득세"),
            String(localized: "지방소득세"), String(localized: "실수령액"), String(localized: "입금"),
            String(localized: "날씨"), String(localized: "태그"), String(localized: "메모"),
        ]
        var rows: [String] = [header.map(escape).joined(separator: ",")]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let t = e.taxBreakdown
            let cols: [String] = [
                df.string(from: e.date),
                e.dayType.title,
                e.site?.name ?? "",
                Format.manUnit(e.manUnit),
                String(e.wage),
                String(e.taxableAmount),
                String(e.mealAllowance),
                String(e.lodgingAllowance),
                String(e.transportAllowance),
                e.taxMode.title,
                String(t.incomeTax),
                String(t.localTax),
                String(e.netAmount),
                e.isPaid ? String(localized: "완료") : String(localized: "미입금"),
                e.weatherCondition.title,
                e.workTag?.title ?? "",
                e.memo
            ]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return "\u{FEFF}" + rows.joined(separator: "\r\n")
    }

    static func writeCSVFile(entries: [WorkEntry], month: Date) throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        let name = String(localized: "공수장") + "-\(df.string(from: month)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try csv(for: entries).data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}
