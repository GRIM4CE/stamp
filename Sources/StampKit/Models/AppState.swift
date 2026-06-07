import AppKit
import Foundation
import PDFKit

@MainActor
final class AppState: ObservableObject {
    @Published var documents: [StampDoc] = []
    @Published var selection: StampDoc.ID?
    @Published var outputFolder: URL
    @Published var isWriting = false
    /// Number of documents written during the current/last batch run.
    @Published var batchWritten = 0
    @Published var batchTotal = 0

    private let outputFolderKey = "outputFolderPath"

    init() {
        if let saved = UserDefaults.standard.string(forKey: outputFolderKey) {
            outputFolder = URL(fileURLWithPath: saved, isDirectory: true)
        } else {
            outputFolder = OutputService.defaultFolder
        }
    }

    var selectedDoc: StampDoc? {
        documents.first { $0.id == selection }
    }

    func setOutputFolder(_ url: URL) {
        outputFolder = url
        UserDefaults.standard.set(url.path, forKey: outputFolderKey)
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

    /// Loads thumbnail, page count, and the auto whitespace position off the main thread.
    private func prepare(_ doc: StampDoc) {
        let url = doc.sourceURL
        let aspect = StampRenderer.aspectRatio(for: doc.deduction)
        Task.detached(priority: .userInitiated) {
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                await MainActor.run { doc.status = .failed("Couldn't open PDF") }
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
        let pending = documents.filter {
            if case .written = $0.status { return false }
            return true
        }
        await write(pending)
    }

    private func write(_ docs: [StampDoc]) async {
        guard !docs.isEmpty else { return }
        isWriting = true
        batchTotal = docs.count
        batchWritten = 0
        defer { isWriting = false }

        OutputService.ensureFolderExists(outputFolder)
        let folder = outputFolder

        for doc in docs {
            let url = doc.sourceURL
            let level = doc.deduction
            let rect = doc.stampRect
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
