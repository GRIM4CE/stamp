import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum ImportService {
    static func pickPDFs() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.message = "Choose the invoice PDFs to stamp"
        panel.prompt = "Add"
        return panel.runModal() == .OK ? panel.urls : []
    }

    static func pickFolder(startingAt start: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose where stamped PDFs are saved"
        panel.prompt = "Choose"
        if let start { panel.directoryURL = start }
        return panel.runModal() == .OK ? panel.url : nil
    }
}
