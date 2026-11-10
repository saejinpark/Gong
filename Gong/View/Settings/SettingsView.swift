//
//  SettingsView.swift
//  Gong
//
//  기본값, 세금 안내, 백업/복원, 앱 정보.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

enum AppDefaults {
    static let defaultTaxModeKey = "defaultTaxMode"
    static let defaultWageKey = "defaultWage"
    static let defaultMealKey = "defaultMealAllowance"
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sites: [Site]
    @Query private var entries: [WorkEntry]

    @AppStorage(AppDefaults.defaultTaxModeKey) private var defaultTaxModeRaw: String = TaxMode.withholding.rawValue
    @AppStorage(AppDefaults.defaultWageKey) private var defaultWage: Int = 0
    @AppStorage(AppDefaults.defaultMealKey) private var defaultMeal: Int = 0

    @State private var shareFile: ShareFile? = nil
    @State private var isImporting = false
    @State private var pendingRestore: BackupDocument? = nil
    @State private var isShowingRestoreConfirm = false
    @State private var isShowingDeleteAllConfirm = false
    @State private var message: String? = nil
    @State private var errorMessage: String? = nil

    @FocusState private var focused: Bool

    private var defaultTaxMode: Binding<TaxMode> {
        Binding(
            get: { TaxMode(rawValue: defaultTaxModeRaw) ?? .withholding },
            set: { defaultTaxModeRaw = $0.rawValue }
        )
    }

    /// 지금 앱에 표시되는 언어 이름 (그 언어로)
    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "ko"
        return Locale(identifier: code).localizedString(forIdentifier: code)?.localizedCapitalized ?? code
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 기본값
                Section {
                    Picker("기본 세금 방식", selection: defaultTaxMode) {
                        ForEach(TaxMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    LabeledContent("현장 없을 때 단가") {
                        HStack {
                            TextField("0", value: $defaultWage, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focused)
                            Text("원").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("기본 식대") {
                        HStack {
                            TextField("0", value: $defaultMeal, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focused)
                            Text("원").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("새 현장·기록 기본값")
                } footer: {
                    Text("새 현장을 만들 때 미리 채워지는 값이에요. 현장마다 따로 바꿀 수 있어요.")
                }

                // MARK: - 언어
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("언어 바꾸기", systemImage: "globe")
                            Spacer()
                            Text(currentLanguageName)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                } header: {
                    Text(verbatim: "언어 · Language · 语言 · Ngôn ngữ · Язык · Til")
                } footer: {
                    Text("휴대폰 설정 > 공수장 > 언어에서 이 앱만 다른 언어로 바꿀 수 있어요.")
                }

                // MARK: - 공수란?
                Section("공수란?") {
                    Text("공수는 하루 일한 양을 세는 단위예요. 정상 근무 하루가 1공수, 반나절은 0.5공수예요. 잔업·야간·특근은 현장에서 정한 만큼 더해요(예: 1.5공수).")
                        .font(Theme.Fonts.label)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                // MARK: - 세금 안내
                Section("세금은 이렇게 계산해요") {
                    ForEach(TaxMode.allCases) { mode in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.title).font(.subheadline.bold())
                            Text(mode.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    TaxExampleRow()
                }

                // MARK: - 공휴일
                Section {
                    LabeledContent("공휴일 데이터") {
                        Text("2025 ~ \(String(HolidayService.lastSupportedYear))년")
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("설·추석 연휴, 대체공휴일, 노동절(5/1), 제헌절(7/17)까지 반영했어요. 기록마다 평일·토요일·공휴일 구분을 직접 바꿀 수도 있어요.")
                }

                // MARK: - 데이터
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        Label("백업 파일 내보내기", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        isImporting = true
                    } label: {
                        Label("백업 파일에서 복원", systemImage: "square.and.arrow.down")
                    }
                    LabeledContent("저장된 기록") {
                        Text("현장 \(sites.count)개 · 기록 \(entries.count)건")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("백업")
                } footer: {
                    Text("기록은 이 기기에만 저장돼요. 폰을 바꾸기 전에 백업 파일을 내보내 카카오톡 '나와의 채팅'이나 파일 앱에 보관해 두세요.")
                }

                Section {
                    Button(role: .destructive) {
                        isShowingDeleteAllConfirm = true
                    } label: {
                        Label("모든 기록 삭제", systemImage: "trash")
                    }
                    .disabled(sites.isEmpty && entries.isEmpty)
                }

                // MARK: - 앱 정보
                Section("앱 정보") {
                    LabeledContent("버전") {
                        Text(BackupService.appVersion).foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/saejinpark/Gong")!) {
                        Label("소스 코드 · 문의 (GitHub)", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .gongListBackground()
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("완료") { focused = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .sheet(item: $shareFile) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json, .plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("백업을 복원할까요?", isPresented: $isShowingRestoreConfirm, presenting: pendingRestore) { doc in
                Button("복원", role: .destructive) { restore(doc) }
                Button("취소", role: .cancel) { pendingRestore = nil }
            } message: { doc in
                Text("지금 저장된 기록이 모두 지워지고 백업 내용(현장 \(doc.sites.count)개, 기록 \(doc.entries.count)건, \(doc.exportedAt.formatted(date: .abbreviated, time: .shortened)) 저장)으로 바뀌어요.")
            }
            .alert("모든 기록을 삭제할까요?", isPresented: $isShowingDeleteAllConfirm) {
                Button("모두 삭제", role: .destructive) { deleteAll() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("현장과 공수 기록이 모두 지워져요. 삭제 전에 백업 파일을 내보내 두는 걸 추천해요.")
            }
            .alert("완료", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("확인") { message = nil }
            } message: {
                Text(message ?? "")
            }
            .alert("문제가 생겼어요", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("확인") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - 동작

    private func exportBackup() {
        do {
            let url = try BackupService.writeBackupFile(sites: sites, entries: entries)
            shareFile = ShareFile(url: url)
        } catch {
            errorMessage = String(localized: "백업 파일을 만들지 못했어요. \(error.localizedDescription)")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                pendingRestore = try BackupService.readDocument(from: url)
                isShowingRestoreConfirm = true
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func restore(_ doc: BackupDocument) {
        do {
            try BackupService.restore(doc, into: context)
            message = String(localized: "현장 \(doc.sites.count)개, 기록 \(doc.entries.count)건을 복원했어요.")
        } catch {
            errorMessage = String(localized: "복원에 실패했어요. \(error.localizedDescription)")
        }
        pendingRestore = nil
    }

    private func deleteAll() {
        do {
            try context.delete(model: WorkEntry.self)
            try context.delete(model: Site.self)
            try context.save()
            message = String(localized: "모든 기록을 삭제했어요.")
        } catch {
            errorMessage = String(localized: "삭제에 실패했어요. \(error.localizedDescription)")
        }
    }
}

/// 일당을 넣어보면 세금이 얼마인지 바로 보여주는 예시 행
private struct TaxExampleRow: View {
    @State private var wage: Int = 200_000

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("예시 일당")
                Spacer()
                TextField("0", value: $wage, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
                Text("원").foregroundStyle(.secondary)
            }
            ForEach(TaxMode.allCases) { mode in
                let t = PayCalculator.tax(taxable: wage, mode: mode)
                HStack {
                    Text(mode.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("세금 \(Format.won(t.total)) → 실수령 \(Format.won(wage - t.total))")
                        .font(.footnote.monospacedDigit())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Site.self, WorkEntry.self], inMemory: true)
}
