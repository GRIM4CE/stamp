import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        if state.documents.isEmpty {
            emptyState
        } else {
            List(selection: $state.selection) {
                ForEach(state.documents) { doc in
                    DocumentRow(doc: doc).tag(doc.id)
                }
            }
            .listStyle(.inset)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 38)).foregroundStyle(Theme.pearlAqua)
            Text("No invoices yet").font(.headline)
            Text("Click Add PDFs or drag files here.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
