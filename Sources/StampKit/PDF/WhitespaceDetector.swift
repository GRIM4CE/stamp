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

        let cw = min(winW, w), ch = min(winH, h)
        let marginX = Int(CGFloat(w) * marginFraction)
        let marginY = Int(CGFloat(h) * marginFraction)
        var x0 = marginX, x1 = w - marginX - cw
        var y0 = marginY, y1 = h - marginY - ch
        if x1 < x0 { x0 = 0; x1 = max(0, w - cw) }
        if y1 < y0 { y0 = 0; y1 = max(0, h - ch) }

        let step = max(1, min(cw, ch) / 8)
        // Position only breaks near-ties: the bonus for a full-height move up is
        // smaller than the cost of one ink pixel, so emptiness wins first and the
        // topmost empty window wins the tie.
        let lambda = 0.5 / Double(h)
        var bestScore = Double.greatestFiniteMagnitude
        var best = CGRect(x: x0, y: y0, width: cw, height: ch)

        var y = y0
        while y <= y1 {
            var x = x0
            while x <= x1 {
                let ink = windowInk(x, y, cw, ch)
                let score = Double(ink) + lambda * Double(y)
                if score < bestScore {
                    bestScore = score
                    best = CGRect(x: x, y: y, width: cw, height: ch)
                }
                x = (x == x1) ? x1 + 1 : min(x + step, x1)
            }
            y = (y == y1) ? y1 + 1 : min(y + step, y1)
        }
        return best
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
        // Flip to a top-left origin, then map PDF points into the raster.
        ctx.translateBy(x: 0, y: CGFloat(pxH))
        ctx.scaleBy(x: 1, y: -1)
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -mediaBox.origin.x, y: -mediaBox.origin.y)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()

        guard let data = ctx.data else { return nil }
        let gray = data.bindMemory(to: UInt8.self, capacity: ctx.bytesPerRow * pxH)

        let winW = max(1, Int(CGFloat(pxW) * widthFraction))
        let winH = max(1, Int(CGFloat(winW) * stampAspect))
        let win = bestWindow(
            gray: gray, width: pxW, height: pxH, bytesPerRow: ctx.bytesPerRow,
            winW: winW, winH: winH
        )

        // Pixel (top-left origin) -> PDF points (bottom-left origin).
        let pdfX = mediaBox.origin.x + win.minX / s
        let pdfW = win.width / s
        let pdfH = win.height / s
        let pdfY = mediaBox.origin.y + (CGFloat(pxH) - (win.minY + win.height)) / s
        return CGRect(x: pdfX, y: pdfY, width: pdfW, height: pdfH)
    }
}
