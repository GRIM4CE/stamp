import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isDropTargeted = false
    @State private var showSidebar = true
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            header
            HStack(spacing: 0) {
                if showSidebar {
                    DocumentListView()
                        .frame(width: 320)
                }
                detail
            }
            footer
        }
        .overlay(dropHighlight)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Stamp")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.inkNavy)
            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.inkNavy.opacity(0.7))
            .help(state.strings.settingsTitle)
        }
        // Title aligns with the sidebar's "Add documents" button (12pt inset).
        // The window's traffic-light controls float over the top-left when the
        // title bar is hidden, so push this row down to clear them vertically
        // instead of indenting it.
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.top, 28)
        .padding(.bottom, 10)
        .background(Theme.panelTint)
    }

    // MARK: - Footer

    // Pinned to the bottom of the window so the sidebar toggle stays in one fixed
    // spot whether the list is shown or hidden.
    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showSidebar.toggle() }
            } label: {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.inkNavy.opacity(0.7))
            .help(showSidebar ? state.strings.sidebarHide : state.strings.sidebarShow)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Theme.panelTint)
    }

    @ViewBuilder
    private var detail: some View {
        if let doc = state.selectedDoc {
            PreviewPane(doc: doc).id(doc.id)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 40)).foregroundStyle(Theme.tangerineDream)
                Text(state.strings.selectInvoice)
                    .foregroundStyle(Theme.inkNavy.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.aliceBlue)
        }
    }

    private var dropHighlight: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Theme.tangerineDream, lineWidth: 3)
            .padding(4)
            .opacity(isDropTargeted ? 1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: - Actions

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
