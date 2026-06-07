import SwiftUI

/// Page-1 preview with a draggable stamp overlay and the approve action.
struct PreviewPane: View {
    @ObservedObject var doc: StampDoc
    @EnvironmentObject var state: AppState

    @State private var pageImage: NSImage?
    @State private var pageBounds: CGRect = .zero
    @State private var dragStartRect: CGRect?

    private let nudgeStep: CGFloat = 6  // PDF points

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            previewArea
            Divider()
            footer
        }
        .background(Theme.aliceBlue)
        .task(id: doc.id) { loadPage() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.filename).font(.headline).lineLimit(1)
                    .foregroundStyle(Theme.inkNavy)
                Text(state.strings.pageCount(doc.pageCount))
                    .font(.caption).foregroundStyle(Theme.inkNavy.opacity(0.7))
            }
            Spacer()
            DeductionPicker(deduction: $doc.deduction)
                .frame(width: 180)
        }
        .padding(12)
        .background(Theme.aliceBlue)
    }

    // MARK: - Preview

    private var previewArea: some View {
        GeometryReader { geo in
            let frame = fittedImageFrame(in: geo.size)
            ZStack(alignment: .topLeading) {
                if let pageImage {
                    Image(nsImage: pageImage)
                        .resizable()
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)

                    if let stampImage = StampRenderer.image(for: doc.deduction),
                       let rect = stampViewRect(imgFrame: frame) {
                        Image(nsImage: stampImage)
                            .resizable()
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                            .gesture(dragGesture(imgFrame: frame))
                            .help(state.strings.dragStamp)
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(20)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            nudgePad
            Spacer()
            statusView
            Button {
                Task { await state.approve(doc) }
            } label: {
                Label(state.strings.approveSave, systemImage: "checkmark.seal.fill")
                    .frame(minWidth: 140)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.stormyTeal)
            .controlSize(.large)
            .disabled(state.isWriting || doc.stampRect == nil)
        }
        .padding(12)
        .background(Theme.aliceBlue)
    }

    private var nudgePad: some View {
        HStack(spacing: 6) {
            Text(state.strings.adjust).font(.caption).foregroundStyle(Theme.inkNavy.opacity(0.7))
            nudgeButton("arrow.left", dx: -nudgeStep, dy: 0)
            VStack(spacing: 4) {
                nudgeButton("arrow.up", dx: 0, dy: nudgeStep)
                nudgeButton("arrow.down", dx: 0, dy: -nudgeStep)
            }
            nudgeButton("arrow.right", dx: nudgeStep, dy: 0)
        }
    }

    private func nudgeButton(_ icon: String, dx: CGFloat, dy: CGFloat) -> some View {
        Button { nudge(dx: dx, dy: dy) } label: { Image(systemName: icon) }
            .buttonStyle(.bordered)
            .disabled(doc.stampRect == nil)
    }

    @ViewBuilder
    private var statusView: some View {
        switch doc.status {
        case .written:
            Label(state.strings.statusSaved, systemImage: "checkmark.circle.fill")
                .foregroundStyle(Theme.stormyTeal)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.tangerineDream).lineLimit(1)
        default:
            EmptyView()
        }
    }

    // MARK: - Loading

    private func loadPage() {
        pageImage = nil
        let url = doc.sourceURL
        Task.detached(priority: .userInitiated) {
            let rendered = PageRenderer.renderPage1(url)
            await MainActor.run {
                if let rendered {
                    pageImage = rendered.image
                    pageBounds = rendered.pageBounds
                }
            }
        }
    }

    // MARK: - Coordinate mapping

    private func fittedImageFrame(in size: CGSize) -> CGRect {
        guard pageBounds.width > 0, pageBounds.height > 0 else { return .zero }
        let f = min(size.width / pageBounds.width, size.height / pageBounds.height)
        let w = pageBounds.width * f, h = pageBounds.height * f
        return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
    }

    /// PDF point rect (bottom-left origin) -> view rect (top-left origin).
    private func stampViewRect(imgFrame: CGRect) -> CGRect? {
        guard let r = doc.stampRect, pageBounds.width > 0 else { return nil }
        let f = imgFrame.width / pageBounds.width
        let x = imgFrame.minX + (r.minX - pageBounds.minX) * f
        let y = imgFrame.minY + (pageBounds.maxY - r.maxY) * f
        return CGRect(x: x, y: y, width: r.width * f, height: r.height * f)
    }

    private func dragGesture(imgFrame: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard pageBounds.width > 0 else { return }
                let start = dragStartRect ?? doc.stampRect
                guard let start else { return }
                if dragStartRect == nil { dragStartRect = start }
                let f = imgFrame.width / pageBounds.width
                let nx = start.minX + value.translation.width / f
                let ny = start.minY - value.translation.height / f  // view-down = PDF-down
                doc.stampRect = clamp(CGRect(x: nx, y: ny, width: start.width, height: start.height))
            }
            .onEnded { _ in dragStartRect = nil }
    }

    private func nudge(dx: CGFloat, dy: CGFloat) {
        guard let r = doc.stampRect else { return }
        doc.stampRect = clamp(r.offsetBy(dx: dx, dy: dy))
    }

    /// Keep the stamp fully inside the page.
    private func clamp(_ rect: CGRect) -> CGRect {
        var r = rect
        r.origin.x = min(max(r.minX, pageBounds.minX), pageBounds.maxX - r.width)
        r.origin.y = min(max(r.minY, pageBounds.minY), pageBounds.maxY - r.height)
        return r
    }
}

/// Segmented 100% / 50% picker shared by the row and the preview header.
struct DeductionPicker: View {
    @Binding var deduction: DeductionLevel

    var body: some View {
        Picker("Déduction", selection: $deduction) {
            ForEach(DeductionLevel.allCases) { level in
                Text(level.label).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
