import Foundation

enum OutputService {
    static var defaultFolder: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Factures tamponnées", isDirectory: true)
    }

    static func ensureFolderExists(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// `<original>-stamped.pdf`, appending ` 2`, ` 3`, … on collision so originals
    /// and prior outputs are never overwritten.
    static func uniqueURL(for source: URL, in folder: URL) -> URL {
        let base = source.deletingPathExtension().lastPathComponent + "-stamped"
        var candidate = folder.appendingPathComponent(base).appendingPathExtension("pdf")
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(base) \(n)").appendingPathExtension("pdf")
            n += 1
        }
        return candidate
    }
}
