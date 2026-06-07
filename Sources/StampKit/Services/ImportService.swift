import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum ImportService {
    static func pickPDFs(strings: L10n) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.message = strings.pickFilesMessage
        panel.prompt = strings.pickFilesPrompt
        return panel.runModal() == .OK ? panel.urls : []
    }

    static func pickFolder(startingAt start: URL?, strings: L10n) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = strings.pickFolderMessage
        panel.prompt = strings.pickFolderPrompt
        if let start { panel.directoryURL = start }
        return panel.runModal() == .OK ? panel.url : nil
    }
}
