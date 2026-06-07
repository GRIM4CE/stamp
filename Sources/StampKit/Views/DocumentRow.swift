import SwiftUI

struct DocumentRow: View {
    @ObservedObject var doc: StampDoc

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
        }
        .padding(.vertical, 4)
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
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.pearlAqua, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusBadge: some View {
        let (text, color): (String, Color) = {
            switch doc.status {
            case .pending, .approved: return ("Ready", Theme.pearlAqua)
            case .written: return ("Saved", Theme.stormyTeal)
            case .failed: return ("Failed", Theme.tangerineDream)
            }
        }()
        return Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.25))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
