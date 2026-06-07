import CoreGraphics
import Foundation
import PDFKit

/// Finds a good empty region on page 1 to place the stamp so it "breathes".
public enum WhitespaceDetector {
    /// Luminance below this counts as "ink" (content).
    public static let inkThreshold: UInt8 = 245
    /// Stamp width as a fraction of page width.
    static let stampWidthFraction: CGFloat = 0.22
    /// Keep the stamp at least this far from each edge.
    static let marginFraction: CGFloat = 0.04
    /// Long edge of the analysis raster, in pixels.
    static let rasterLongEdge: CGFloat = 1200

    /// Pure, testable core. `gray` is a grayscale buffer with a **top-left origin**
    /// (row 0 = top). Returns the best stamp window as a CGRect in pixel coords
    /// (top-left origin). Prefers the emptiest window; ties break toward the top.
    public static func bestWindow(
        gray: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int,
        winW: Int, winH: Int
    ) -> CGRect {
        return bestWindowWithInk(
            gray: gray, width: width, height: height, bytesPerRow: bytesPerRow,
            winW: winW, winH: winH
        ).rect
    }

    /// Same as `bestWindow`, but also returns how much ink lies in (and around) the
    /// chosen window. `padX`/`padY` add a breathing-room border: emptiness is judged
    /// over the window *plus* that border, so the stamp lands clear of nearby content
    /// rather than crammed right up against it. `ink == 0` means the window and its
    /// padded border are pure whitespace. The returned rect is still the stamp window.
    static func bestWindowWithInk(
        gray: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int,
        winW: Int, winH: Int, padX: Int = 0, padY: Int = 0
    ) -> (rect: CGRect, ink: Int) {
        let w = width, h = height
        let stride = w + 1

        // Integral image of the ink map for O(1) window sums.
        var integ = [Int](repeating: 0, count: (w + 1) * (h + 1))
        integ.withUnsafeMutableBufferPointer { buf in
            for y in 0..<h {
                let rowOff = (y + 1) * stride
                let prevOff = y * stride
                let base = y * bytesPerRow
                var rowSum = 0
                for x in 0..<w {
                    rowSum += gray[base + x] < inkThreshold ? 1 : 0
                    buf[rowOff + x + 1] = buf[prevOff + x + 1] + rowSum
                }
            }
        }
        func windowInk(_ x: Int, _ y: Int, _ ww: Int, _ hh: Int) -> Int {
            let x2 = x + ww, y2 = y + hh
            return integ[y2 * stride + x2] - integ[y * stride + x2]
                - integ[y2 * stride + x] + integ[y * stride + x]
        }
        // Ink over the window plus a padded border (clamped to the page), so positions
        // hugging content score worse than ones with clear space around them.
        func paddedInk(_ x: Int, _ y: Int, _ ww: Int, _ hh: Int) -> Int {
            let ax = max(0, x - padX), ay = max(0, y - padY)
            let bx = min(w, x + ww + padX), by = min(h, y + hh + padY)
            return windowInk(ax, ay, bx - ax, by - ay)
        }

        let cw = min(winW, w), ch = min(winH, h)
        let marginX = Int(CGFloat(w) * marginFraction)
        let marginY = Int(CGFloat(h) * marginFraction)
        var x0 = marginX, x1 = w - marginX - cw
        var y0 = marginY, y1 = h - marginY - ch
        if x1 < x0 { x0 = 0; x1 = max(0, w - cw) }
        if y1 < y0 { y0 = 0; y1 = max(0, h - ch) }

        let step = max(1, min(cw, ch) / 8)
        // Emptiness wins first: the window with the least ink is chosen so the stamp
        // never lands on content when clear space exists. Position only breaks
        // near-ties — the bonus for a full-height move up is smaller than the cost of
        // a single ink pixel, so the topmost *empty* window wins, but any empty
        // window always beats a higher one that overlaps content.
        let lambda = 0.5 / Double(h)
        var bestScore = Double.greatestFiniteMagnitude
        var best = CGRect(x: x0, y: y0, width: cw, height: ch)
        var bestInk = Int.max

        var y = y0
        while y <= y1 {
            var x = x0
            while x <= x1 {
                let ink = paddedInk(x, y, cw, ch)
                let score = Double(ink) + lambda * Double(y)
                if score < bestScore {
                    bestScore = score
                    best = CGRect(x: x, y: y, width: cw, height: ch)
                    bestInk = ink
                }
                x = (x == x1) ? x1 + 1 : min(x + step, x1)
            }
            y = (y == y1) ? y1 + 1 : min(y + step, y1)
        }
        return (best, bestInk)
    }

    /// Rasterizes page 1, finds the best whitespace window, and returns it in
    /// PDF point space (mediaBox, bottom-left origin).
    static func bestStampRect(
        on page: PDFPage, stampAspect: CGFloat, widthFraction: CGFloat = stampWidthFraction
    ) -> CGRect? {
        let mediaBox = page.bounds(for: .mediaBox)
        guard mediaBox.width > 0, mediaBox.height > 0 else { return nil }

        let s = rasterLongEdge / max(mediaBox.width, mediaBox.height)
        let pxW = max(1, Int((mediaBox.width * s).rounded()))
        let pxH = max(1, Int((mediaBox.height * s).rounded()))

        guard let ctx = CGContext(
            data: nil, width: pxW, height: pxH, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: pxW, height: pxH))
        ctx.saveGState()
        // A CGBitmapContext stores memory row 0 at the top, so drawing the page with
        // no extra flip yields a top-left-origin raster (row 0 = top of page), which
        // is what `bestWindow` and the pixel->PDF mapping below both assume.
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -mediaBox.origin.x, y: -mediaBox.origin.y)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()

        guard let data = ctx.data else { return nil }
        let gray = data.bindMemory(to: UInt8.self, capacity: ctx.bytesPerRow * pxH)

        // Try the requested size first, then progressively smaller stamps until one
        // lands on pure whitespace (ink == 0). Larger is preferred, so we stop at the
        // first empty fit. If nothing is ever empty (a fully dense page), fall back to
        // the least-inky window found so the stamp at least covers as little as possible.
        let sizeScales: [CGFloat] = [1.0, 0.85, 0.7, 0.55, 0.45]
        var win = CGRect.zero
        var fallback: (rect: CGRect, ink: Int)?
        for scale in sizeScales {
            let winW = max(1, Int(CGFloat(pxW) * widthFraction * scale))
            let winH = max(1, Int(CGFloat(winW) * stampAspect))
            // Require a breathing-room border around the stamp so it never crams up
            // against a logo or text — roughly half the stamp's size of clear space.
            let padX = Int(CGFloat(winW) * 0.5)
            let padY = Int(CGFloat(winH) * 0.6)
            let candidate = bestWindowWithInk(
                gray: gray, width: pxW, height: pxH, bytesPerRow: ctx.bytesPerRow,
                winW: winW, winH: winH, padX: padX, padY: padY
            )
            if candidate.ink == 0 {
                win = candidate.rect
                fallback = nil
                break
            }
            if fallback == nil || candidate.ink < fallback!.ink {
                fallback = candidate
            }
        }
        if let fallback { win = fallback.rect }

        // Pixel (top-left origin) -> PDF points (bottom-left origin).
        let pdfX = mediaBox.origin.x + win.minX / s
        let pdfW = win.width / s
        let pdfH = win.height / s
        let pdfY = mediaBox.origin.y + (CGFloat(pxH) - (win.minY + win.height)) / s
        return CGRect(x: pdfX, y: pdfY, width: pdfW, height: pdfH)
    }
}
