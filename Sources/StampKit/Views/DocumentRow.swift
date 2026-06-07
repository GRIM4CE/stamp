import SwiftUI

struct DocumentRow: View {
    @ObservedObject var doc: StampDoc
    @EnvironmentObject var state: AppState
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
            VStack(alignment: .leading, spacing: 6) {
                Text(doc.filename).lineLimit(1).font(.body.weight(.medium))
                HStack(spacing: 8) {
                    DeductionPicker(deduction: $doc.deduction).frame(width: 120)
                    statusBadge
                }
            }
            Spacer(minLength: 0)
            removeButton
        }
        .padding(.vertical, 4)
        .onHover { isHovering = $0 }
    }

    private var removeButton: some View {
        Button { state.removeDocument(doc) } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.inkNavy.opacity(0.4))
        }
        .buttonStyle(.plain)
        .help(state.strings.remove)
        .opacity(isHovering ? 1 : 0)
    }

    private var thumbnail: some View {
        Group {
            if let thumb = doc.thumbnail {
                Image(nsImage: thumb).resizable().aspectRatio(contentMode: .fit)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .frame(width: 46, height: 60)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.tangerineDream, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusBadge: some View {
        let style: (text: String, fg: Color, bg: Color) = {
            switch doc.status {
            case .pending, .approved: return (state.strings.statusReady, Theme.stormyTeal, Theme.pearlAqua.opacity(0.35))
            case .written: return (state.strings.statusSaved, .white, Theme.stormyTeal)
            case .failed: return (state.strings.statusFailed, Theme.inkNavy, Theme.almondSilk)
            }
        }()
        return Text(style.text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(style.bg)
            .foregroundStyle(style.fg)
            .clipShape(Capsule())
    }
}
