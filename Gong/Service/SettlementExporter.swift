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
        Dictionary(grouping: entries) { $0.site?.name ?? "현장 미지정" }
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

    /// 카카오톡 등으로 바로 보낼 수 있는 정산 문자
    static func text(for summary: MonthlySummary, includeDaily: Bool = true) -> String {
        var lines: [String] = []
        lines.append("[공수장] \(Format.monthTitle.string(from: summary.month)) 정산")
        lines.append("")
        lines.append("총 \(Format.manUnit(summary.manUnit))공수 · \(summary.workDays)일 근무")
        lines.append("일당 합계 \(Format.won(summary.taxable))")
        if summary.allowance > 0 {
            lines.append("수당 합계 +\(Format.won(summary.allowance))")
        }
        if summary.tax > 0 {
            lines.append("세금 -\(Format.won(summary.tax))")
        }
        lines.append("실수령액 \(Format.won(summary.net))")
        if !summary.unpaid.isEmpty {
            lines.append("미입금 \(summary.unpaid.count)건 \(Format.won(summary.unpaidAmount))")
        }

        let sites = summary.siteLines
        if sites.count > 1 || sites.first?.name != "현장 미지정" {
            lines.append("")
            lines.append("■ 현장별")
            for s in sites {
                var line = "\(s.name): \(Format.manUnit(s.manUnit))공수 · \(s.days)일 · \(Format.won(s.net))"
                if s.unpaid > 0 { line += " (미입금 \(Format.won(s.unpaid)))" }
                lines.append(line)
            }
        }

        if includeDaily {
            lines.append("")
            lines.append("■ 일별")
            for e in summary.entries.sorted(by: { $0.date < $1.date }) {
                var line = "\(Format.shortDay.string(from: e.date)) "
                if let site = e.site?.name { line += "\(site) " }
                line += "\(Format.manUnit(e.manUnit))공수 \(Format.won(e.netAmount))"
                if let tag = e.workTag { line += " [\(tag.rawValue)]" }
                if !e.memo.isEmpty { line += " - \(e.memo)" }
                line += e.isPaid ? " ✓" : " (미입금)"
                lines.append(line)
            }
        }
        return lines.joined(separator: "\n")
    }

    /// 엑셀에서 열리는 CSV (BOM 포함, 한글 깨짐 방지)
    static func csv(for entries: [WorkEntry]) -> String {
        let header = ["날짜", "요일구분", "현장", "공수", "단가", "일당", "식대", "숙박비", "교통비",
                      "세금방식", "소득세", "지방소득세", "실수령액", "입금", "날씨", "태그", "메모"]
        var rows: [String] = [header.joined(separator: ",")]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let t = e.taxBreakdown
            let cols: [String] = [
                df.string(from: e.date),
                e.dayType.rawValue,
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
                e.isPaid ? "완료" : "미입금",
                e.weatherCondition.rawValue,
                e.workTag?.rawValue ?? "",
                e.memo
            ]
            rows.append(cols.map(escape).joined(separator: ","))
        }
        return "\u{FEFF}" + rows.joined(separator: "\r\n")
    }

    static func writeCSVFile(entries: [WorkEntry], month: Date) throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        let name = "공수장-\(df.string(from: month)).csv"
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
