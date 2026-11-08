//
//  BackupService.swift
//  Gong
//
//  기기 교체·분실 대비 JSON 백업/복원. 서버 없이 파일로만.
//

import Foundation
import SwiftData

struct BackupDocument: Codable {
    struct SiteDTO: Codable {
        var id: String
        var name: String
        var defaultWage: Int
        var startDate: Date
        var location: String
        var memo: String
        var isActive: Bool
        var taxMode: String
        var defaultMealAllowance: Int
        var colorIndex: Int?
    }

    struct EntryDTO: Codable {
        var date: Date
        var manUnit: Double
        var wage: Int
        var mealAllowance: Int
        var lodgingAllowance: Int
        var transportAllowance: Int
        var dayType: DayType
        var weatherCondition: WeatherCondition
        var workTag: WorkTag?
        var memo: String
        var isPaid: Bool
        var taxMode: String
        var siteID: String?
    }

    var version: Int = 1
    var exportedAt: Date
    var appVersion: String
    var sites: [SiteDTO]
    var entries: [EntryDTO]
}

enum BackupError: LocalizedError {
    case unreadable
    case incompatible(Int)

    var errorDescription: String? {
        switch self {
        case .unreadable: return "백업 파일을 읽을 수 없어요. 공수장에서 내보낸 파일인지 확인해 주세요."
        case .incompatible(let v): return "지원하지 않는 백업 버전(\(v))이에요. 앱을 최신 버전으로 업데이트해 주세요."
        }
    }
}

enum BackupService {

    static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    // MARK: - 내보내기

    static func makeDocument(sites: [Site], entries: [WorkEntry]) -> BackupDocument {
        var siteIDs: [PersistentIdentifier: String] = [:]
        let siteDTOs = sites.map { site -> BackupDocument.SiteDTO in
            let id = UUID().uuidString
            siteIDs[site.persistentModelID] = id
            return .init(
                id: id,
                name: site.name,
                defaultWage: site.defaultWage,
                startDate: site.startDate,
                location: site.location,
                memo: site.memo,
                isActive: site.isActive,
                taxMode: site.taxModeRaw,
                defaultMealAllowance: site.defaultMealAllowance,
                colorIndex: site.colorIndex
            )
        }
        let entryDTOs = entries
            .sorted { $0.date < $1.date }
            .map { entry -> BackupDocument.EntryDTO in
                .init(
                    date: entry.date,
                    manUnit: entry.manUnit,
                    wage: entry.wage,
                    mealAllowance: entry.mealAllowance,
                    lodgingAllowance: entry.lodgingAllowance,
                    transportAllowance: entry.transportAllowance,
                    dayType: entry.dayType,
                    weatherCondition: entry.weatherCondition,
                    workTag: entry.workTag,
                    memo: entry.memo,
                    isPaid: entry.isPaid,
                    taxMode: entry.taxModeRaw,
                    siteID: entry.site.flatMap { siteIDs[$0.persistentModelID] }
                )
            }
        return BackupDocument(exportedAt: .now, appVersion: appVersion, sites: siteDTOs, entries: entryDTOs)
    }

    /// 임시 폴더에 JSON 파일을 쓰고 URL 반환 (ShareLink 용)
    static func writeBackupFile(sites: [Site], entries: [WorkEntry]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(makeDocument(sites: sites, entries: entries))

        let name = "공수장-백업-\(Format.fileStamp.string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - 가져오기

    static func readDocument(from url: URL) throws -> BackupDocument {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else { throw BackupError.unreadable }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let doc = try? decoder.decode(BackupDocument.self, from: data) else {
            throw BackupError.unreadable
        }
        guard doc.version <= 1 else { throw BackupError.incompatible(doc.version) }
        return doc
    }

    /// 기존 데이터를 모두 지우고 백업 내용으로 교체
    static func restore(_ doc: BackupDocument, into context: ModelContext) throws {
        try context.delete(model: WorkEntry.self)
        try context.delete(model: Site.self)

        var sitesByID: [String: Site] = [:]
        for dto in doc.sites {
            let site = Site(
                name: dto.name,
                defaultWage: dto.defaultWage,
                startDate: dto.startDate,
                location: dto.location,
                memo: dto.memo,
                isActive: dto.isActive,
                taxMode: TaxMode(rawValue: dto.taxMode) ?? .withholding,
                defaultMealAllowance: dto.defaultMealAllowance,
                colorIndex: dto.colorIndex ?? 0
            )
            context.insert(site)
            sitesByID[dto.id] = site
        }
        for dto in doc.entries {
            let entry = WorkEntry(
                date: dto.date,
                manUnit: dto.manUnit,
                wage: dto.wage,
                mealAllowance: dto.mealAllowance,
                lodgingAllowance: dto.lodgingAllowance,
                transportAllowance: dto.transportAllowance,
                dayType: dto.dayType,
                weatherCondition: dto.weatherCondition,
                workTag: dto.workTag,
                memo: dto.memo,
                isPaid: dto.isPaid,
                site: dto.siteID.flatMap { sitesByID[$0] },
                taxMode: TaxMode(rawValue: dto.taxMode) ?? .withholding
            )
            context.insert(entry)
        }
        try context.save()
    }
}
