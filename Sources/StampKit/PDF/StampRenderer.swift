import AppKit
import Foundation

/// Loads the bundled stamp PNGs.
enum StampRenderer {
    /// Cached so repeated stamping/preview doesn't re-decode. Accessed from both the
    /// main actor (preview) and background tasks (batch stamping), so guard with a lock.
    private static var cache: [String: NSImage] = [:]
    private static let lock = NSLock()

    static func image(for deduction: DeductionLevel) -> NSImage? {
        let name = deduction.assetName
        lock.lock()
        let cached = cache[name]
        lock.unlock()
        if let cached { return cached }

        let url = Bundle.main.url(forResource: name, withExtension: "png")
            // Dev fallback: when run via `swift run` from the repo, Bundle.main has no
            // resources, so look beside the working directory.
            ?? devResourceURL(name)
        guard let url, let image = NSImage(contentsOf: url) else { return nil }
        lock.lock()
        cache[name] = image
        lock.unlock()
        return image
    }

    private static func devResourceURL(_ name: String) -> URL? {
        let candidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/\(name).png")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    static func cgImage(for deduction: DeductionLevel) -> CGImage? {
        guard let image = image(for: deduction) else { return nil }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    /// height / width of the stamp art. Falls back to the known badge ratio if the asset is missing.
    static func aspectRatio(for deduction: DeductionLevel) -> CGFloat {
        guard let image = image(for: deduction), image.size.width > 0 else {
            return 686.0 / 1586.0
        }
        return image.size.height / image.size.width
    }
}
