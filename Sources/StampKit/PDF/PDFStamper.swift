import CoreGraphics
import Foundation
import PDFKit

public enum PDFStamper {
    enum StampError: LocalizedError {
        case cannotOpen
        case noPages
        case missingStampImage
        case renderFailed
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .cannotOpen: return "Couldn't open the PDF."
            case .noPages: return "The PDF has no pages."
            case .missingStampImage: return "The stamp image is missing."
            case .renderFailed: return "Couldn't render the stamped page."
            case .writeFailed: return "Couldn't save the stamped PDF."
            }
        }
    }

    /// Burns the stamp onto page 1 (flattened, permanent) and writes a new PDF
    /// into `folder`. Originals are never modified. Returns the output URL.
    static func stamp(
        pdfAt url: URL, deduction: DeductionLevel, stampRect: CGRect?, into folder: URL
    ) throws -> URL {
        guard let stamp = StampRenderer.cgImage(for: deduction) else {
            throw StampError.missingStampImage
        }
        return try self.stamp(pdfAt: url, stampImage: stamp, stampRect: stampRect, into: folder)
    }

    /// Core stamping with an explicit image (used by tests and by the public API above).
    public static func stamp(
        pdfAt url: URL, stampImage stamp: CGImage, stampRect: CGRect?, into folder: URL
    ) throws -> URL {
        guard let doc = PDFDocument(url: url) else { throw StampError.cannotOpen }
        guard let page = doc.page(at: 0) else { throw StampError.noPages }

        let aspect = CGFloat(stamp.height) / CGFloat(stamp.width)
        let mediaBox = page.bounds(for: .mediaBox)
        let rect = stampRect
            ?? WhitespaceDetector.bestStampRect(on: page, stampAspect: aspect)
            ?? fallbackRect(in: mediaBox, aspect: aspect)

        // Re-render page 1 through a CGPDFContext, drawing the stamp into the
        // content stream so it becomes a permanent, non-deletable part of the page.
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { throw StampError.renderFailed }
        var box = mediaBox
        guard let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw StampError.renderFailed
        }
        ctx.beginPDFPage(nil)
        page.draw(with: .mediaBox, to: ctx)   // original content (stays vector)
        ctx.draw(stamp, in: rect)             // burn the stamp (same PDF point space)
        ctx.endPDFPage()
        ctx.closePDF()

        guard let stamped = PDFDocument(data: data as Data),
              let newPage = stamped.page(at: 0) else { throw StampError.renderFailed }
        doc.removePage(at: 0)
        doc.insert(newPage, at: 0)   // other pages untouched

        let out = OutputService.uniqueURL(for: url, in: folder)
        guard doc.write(to: out) else { throw StampError.writeFailed }
        return out
    }

    /// Top-right placement used only if whitespace detection fails entirely.
    private static func fallbackRect(in mediaBox: CGRect, aspect: CGFloat) -> CGRect {
        let w = mediaBox.width * WhitespaceDetector.stampWidthFraction
        let h = w * aspect
        let margin = mediaBox.width * WhitespaceDetector.marginFraction
        return CGRect(
            x: mediaBox.maxX - margin - w,
            y: mediaBox.maxY - margin - h,
            width: w, height: h
        )
    }
}
