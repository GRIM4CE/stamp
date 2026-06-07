import AppKit
import Foundation

/// One imported PDF and its stamping state.
final class StampDoc: ObservableObject, Identifiable {
    let id = UUID()
    let sourceURL: URL

    @Published var deduction: DeductionLevel = .full
    /// Stamp position on page 1, in PDF point space (mediaBox, bottom-left origin).
    @Published var stampRect: CGRect?
    @Published var status: Status = .pending
    @Published var thumbnail: NSImage?
    @Published var pageCount: Int = 0
    /// Set when status == .written.
    @Published var outputURL: URL?

    init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }

    var filename: String { sourceURL.lastPathComponent }

    enum Status: Equatable {
        case pending
        case approved
        case written
        case failed(String)

        var isWritten: Bool { self == .written }
    }
}
