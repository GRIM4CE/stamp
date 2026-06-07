import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            addBar
            Divider()
            if state.documents.isEmpty {
                emptyState
            } else {
                List(selection: $state.selection) {
                    ForEach(state.documents) { doc in
                        DocumentRow(doc: doc).tag(doc.id)
                    }
                }
                .listStyle(.inset)
                Divider()
                saveAllBar
            }
        }
        .background(Theme.aliceBlue)
    }

    private var addBar: some View {
        Button { addPDFs() } label: {
            Label(state.strings.addDocument, systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.stormyTeal)
        .controlSize(.large)
        .padding(12)
        .background(Theme.aliceBlue)
    }

    private var saveAllBar: some View {
        Button {
            Task { await state.approveAll() }
        } label: {
            Label(saveAllTitle, systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.stormyTeal)
        .controlSize(.large)
        .disabled(state.isWriting || state.pendingDocuments.isEmpty)
        .padding(12)
        .background(Theme.aliceBlue)
    }

    private var saveAllTitle: String {
        if state.isWriting {
            return state.strings.saving(state.batchWritten, state.batchTotal)
        }
        let count = state.pendingDocuments.count
        return count > 0 ? state.strings.saveAll(count) : state.strings.allSaved
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 38)).foregroundStyle(Theme.pearlAqua)
            Text(state.strings.noInvoices).font(.headline)
            Text(state.strings.dragHint)
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func addPDFs() {
        let urls = ImportService.pickPDFs(strings: state.strings)
        if !urls.isEmpty { state.importDocuments(urls) }
    }
}
