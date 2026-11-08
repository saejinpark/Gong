//
//  ActivityView.swift
//  Gong
//
//  파일(CSV, 백업 JSON)을 공유 시트로 내보내기 위한 UIActivityViewController 래퍼.
//

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// `.sheet(item:)` 로 쓰기 위한 URL 래퍼
struct ShareFile: Identifiable {
    let id = UUID()
    let url: URL
}
