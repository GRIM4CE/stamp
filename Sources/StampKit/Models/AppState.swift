import AppKit
import Foundation
import PDFKit

@MainActor
final class AppState: ObservableObject {
    @Published var documents: [StampDoc] = []
    @Published var selection: StampDoc.ID?
    @Published var outputFolder: URL
    /// When true, each stamped PDF is written next to its original instead of
    /// into `outputFolder`.
    @Published var useSourceFolder: Bool
    @Published var language: AppLanguage
    @Published var isWriting = false
    /// Number of documents written during the current/last batch run.
    @Published var batchWritten = 0
    @Published var batchTotal = 0

    private let outputFolderKey = "outputFolderPath"
    private let useSourceFolderKey = "useSourceFolder"
    private let languageKey = "appLanguage"

    /// Localized strings for the current language.
    var strings: L10n { L10n(lang: language) }

    init() {
        if let saved = UserDefaults.standard.string(forKey: outputFolderKey) {
            outputFolder = URL(fileURLWithPath: saved, isDirectory: true)
        } else {
            outputFolder = OutputService.defaultFolder
        }
        useSourceFolder = UserDefaults.standard.bool(forKey: useSourceFolderKey)
        if let raw = UserDefaults.standard.string(forKey: languageKey),
           let saved = AppLanguage(rawValue: raw) {
            language = saved
        } else {
            language = .french
        }
    }

    var selectedDoc: StampDoc? {
        documents.first { $0.id == selection }
    }

    /// Documents that haven't been written yet — the targets of a "Save All".
    var pendingDocuments: [StampDoc] {
        documents.filter {
            if case .written = $0.status { return false }
            return true
        }
    }

    func setOutputFolder(_ url: URL) {
        outputFolder = url
        UserDefaults.standard.set(url.path, forKey: outputFolderKey)
    }

    func setUseSourceFolder(_ value: Bool) {
        useSourceFolder = value
        UserDefaults.standard.set(value, forKey: useSourceFolderKey)
    }

    func setLanguage(_ value: AppLanguage) {
        language = value
        UserDefaults.standard.set(value.rawValue, forKey: languageKey)
    }

    // MARK: - Import

    func importDocuments(_ urls: [URL]) {
        let existing = Set(documents.map(\.sourceURL))
        let fresh = urls.filter { $0.pathExtension.lowercased() == "pdf" && !existing.contains($0) }
        for url in fresh {
            let doc = StampDoc(sourceURL: url)
            documents.append(doc)
            prepare(doc)
        }
        if selection == nil { selection = documents.first?.id }
    }

    /// Removes a document from the list. Only affects the in-app list — the
    /// original PDF on disk is never touched.
    func removeDocument(_ doc: StampDoc) {
        documents.removeAll { $0.id == doc.id }
        if selection == doc.id { selection = documents.first?.id }
    }

    /// Loads thumbnail, page count, and the auto whitespace position off the main thread.
    private func prepare(_ doc: StampDoc) {
        let url = doc.sourceURL
        let aspect = StampRenderer.aspectRatio(for: doc.deduction)
        Task.detached(priority: .userInitiated) {
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                await MainActor.run { doc.status = .failed("Impossible d'ouvrir le PDF") }
                return
            }
            let count = pdf.pageCount
            let thumb = page.thumbnail(of: NSSize(width: 220, height: 280), for: .mediaBox)
            let rect = WhitespaceDetector.bestStampRect(on: page, stampAspect: aspect)
            await MainActor.run {
                doc.pageCount = count
                doc.thumbnail = thumb
                doc.stampRect = rect
            }
        }
    }

    // MARK: - Approve / write

    func approve(_ doc: StampDoc) async {
        await write([doc])
    }

    func approveAll() async {
        await write(pendingDocuments)
    }

    private func write(_ docs: [StampDoc]) async {
        guard !docs.isEmpty else { return }
        isWriting = true
        batchTotal = docs.count
        batchWritten = 0
        defer { isWriting = false }

        for doc in docs {
            let url = doc.sourceURL
            let level = doc.deduction
            let rect = doc.stampRect
            let folder = useSourceFolder ? url.deletingLastPathComponent() : outputFolder
            OutputService.ensureFolderExists(folder)
            let result: Result<URL, Error> = await Task.detached(priority: .userInitiated) {
                do {
                    let out = try PDFStamper.stamp(
                        pdfAt: url, deduction: level, stampRect: rect, into: folder
                    )
                    return .success(out)
                } catch {
                    return .failure(error)
                }
            }.value

            switch result {
            case .success(let out):
                doc.status = .written
                doc.outputURL = out
                batchWritten += 1
            case .failure(let error):
                doc.status = .failed(error.localizedDescription)
            }
        }
    }
}
