import AppKit
import CoreGraphics
import Foundation
import PDFKit

/// Renders page 1 of a PDF to an image for the preview, plus its mediaBox.
enum PageRenderer {
    static func renderPage1(_ url: URL, scale: CGFloat = 2) -> (image: NSImage, pageBounds: CGRect)? {
        guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let pxW = max(1, Int((bounds.width * scale).rounded()))
        let pxH = max(1, Int((bounds.height * scale).rounded()))

        guard let ctx = CGContext(
            data: nil, width: pxW, height: pxH, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: pxW, height: pxH))
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        page.draw(with: .mediaBox, to: ctx)

        guard let cg = ctx.makeImage() else { return nil }
        let image = NSImage(cgImage: cg, size: bounds.size)
        return (image, bounds)
    }
}
