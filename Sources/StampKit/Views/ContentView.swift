import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            DocumentListView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        } detail: {
            detail
        }
        .toolbar { toolbarContent }
        .overlay(dropHighlight)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    @ViewBuilder
    private var detail: some View {
        if let doc = state.selectedDoc {
            PreviewPane(doc: doc).id(doc.id)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 40)).foregroundStyle(Theme.pearlAqua)
                Text("Select an invoice to preview the stamp")
                    .foregroundStyle(Theme.stormyTeal.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.aliceBlue)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { addPDFs() } label: { Label("Add PDFs", systemImage: "plus") }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            outputFolderButton
            if state.isWriting {
                ProgressView(value: Double(state.batchWritten), total: Double(max(state.batchTotal, 1)))
                    .frame(width: 120)
            }
            Button { Task { await state.approveAll() } } label: {
                Label("Approve All", systemImage: "checkmark.seal")
            }
            .disabled(state.documents.isEmpty || state.isWriting)
        }
    }

    private var outputFolderButton: some View {
        Button { chooseOutputFolder() } label: {
            Label(state.outputFolder.lastPathComponent, systemImage: "folder")
        }
        .help("Stamped PDFs are saved to: \(state.outputFolder.path)")
    }

    private var dropHighlight: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Theme.stormyTeal, lineWidth: 3)
            .padding(4)
            .opacity(isDropTargeted ? 1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func addPDFs() {
        let urls = ImportService.pickPDFs()
        if !urls.isEmpty { state.importDocuments(urls) }
    }

    private func chooseOutputFolder() {
        if let url = ImportService.pickFolder(startingAt: state.outputFolder) {
            state.setOutputFolder(url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, url.pathExtension.lowercased() == "pdf" else { return }
                Task { @MainActor in state.importDocuments([url]) }
            }
        }
        return true
    }
}
