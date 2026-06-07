// Lightweight test runner (XCTest/Swift Testing are unavailable under Command Line
// Tools). Run with: swift run StampTests
import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import StampKit

var failures = 0
func check(_ condition: Bool, _ message: String) {
    if condition {
        print("  ✓ \(message)")
    } else {
        print("  ✗ \(message)")
        failures += 1
    }
}

func test(_ name: String, _ body: () throws -> Void) {
    print("• \(name)")
    do { try body() } catch { print("  ✗ threw: \(error)"); failures += 1 }
}

let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // StampTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // repo root
let samplePDF = repoRoot.appendingPathComponent("temp/sample-pdf-invoice.pdf")

func makeStampImage() -> CGImage {
    let w = 300, h = 130
    let ctx = CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(red: 0.75, green: 0.12, blue: 0.16, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    return ctx.makeImage()!
}

func tempFolder() -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("stamptest-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

// MARK: - WhitespaceDetector

test("WhitespaceDetector picks an empty region biased to the top") {
    let w = 200, h = 200
    var buf = [UInt8](repeating: 255, count: w * h)
    for y in 0..<90 { for x in 0..<90 { buf[y * w + x] = 0 } }  // top-left black block

    let win = buf.withUnsafeBufferPointer { ptr in
        WhitespaceDetector.bestWindow(
            gray: ptr.baseAddress!, width: w, height: h, bytesPerRow: w, winW: 40, winH: 40)
    }
    var ink = 0
    for y in Int(win.minY)..<Int(win.maxY) {
        for x in Int(win.minX)..<Int(win.maxX) where buf[y * w + x] < WhitespaceDetector.inkThreshold {
            ink += 1
        }
    }
    check(ink == 0, "chosen window is empty")
    check(win.minX > 90 && win.minY < 90, "window clears the black corner and sits near the top (top bias)")
}

test("WhitespaceDetector returns an in-bounds window on an all-white field") {
    let w = 120, h = 160
    let buf = [UInt8](repeating: 255, count: w * h)
    let win = buf.withUnsafeBufferPointer { ptr in
        WhitespaceDetector.bestWindow(
            gray: ptr.baseAddress!, width: w, height: h, bytesPerRow: w, winW: 30, winH: 30)
    }
    check(win.minX >= 0 && win.minY >= 0 && win.maxX <= CGFloat(w) && win.maxY <= CGFloat(h),
          "window stays within bounds")
}

// MARK: - PDFStamper

if FileManager.default.fileExists(atPath: samplePDF.path) {
    test("PDFStamper preserves pages and text, burns stamp, leaves original") {
        let original = try Data(contentsOf: samplePDF)
        let inDoc = PDFDocument(url: samplePDF)!
        let originalPageCount = inDoc.pageCount
        let originalText = inDoc.page(at: 0)?.string ?? ""

        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let out = try PDFStamper.stamp(
            pdfAt: samplePDF, stampImage: makeStampImage(), stampRect: nil, into: folder)

        check(FileManager.default.fileExists(atPath: out.path), "output file written")
        let outDoc = PDFDocument(url: out)!
        check(outDoc.pageCount == originalPageCount, "page count unchanged (\(outDoc.pageCount))")
        if !originalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let outText = outDoc.page(at: 0)?.string ?? ""
            check(!outText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  "page 1 text preserved")
        }
        check(outDoc.page(at: 0)?.annotations.isEmpty ?? true,
              "stamp is flattened, not a deletable annotation")
        check(try! Data(contentsOf: samplePDF) == original, "original file untouched")
    }

    test("PDFStamper gives a unique name on collision") {
        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let image = makeStampImage()
        let first = try PDFStamper.stamp(pdfAt: samplePDF, stampImage: image, stampRect: nil, into: folder)
        let second = try PDFStamper.stamp(pdfAt: samplePDF, stampImage: image, stampRect: nil, into: folder)
        check(first != second, "second output has a distinct name")
        check(FileManager.default.fileExists(atPath: first.path)
              && FileManager.default.fileExists(atPath: second.path), "both files exist")
    }
} else {
    print("• Skipping PDFStamper tests (sample PDF not found at \(samplePDF.path))")
}

// MARK: - Visual artifacts (real stamp art + real whitespace placement)
// Produces /tmp PNGs of stamped page 1 for manual inspection.

func loadCGImage(_ url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func renderPage1PNG(_ pdf: URL, to out: URL, scale: CGFloat = 1.5) {
    guard let doc = PDFDocument(url: pdf), let page = doc.page(at: 0) else { return }
    let b = page.bounds(for: .mediaBox)
    let pxW = Int(b.width * scale), pxH = Int(b.height * scale)
    let ctx = CGContext(data: nil, width: pxW, height: pxH, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(gray: 1, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: pxW, height: pxH))
    ctx.scaleBy(x: scale, y: scale); ctx.translateBy(x: -b.origin.x, y: -b.origin.y)
    page.draw(with: .mediaBox, to: ctx)
    guard let img = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)
    else { return }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("  → wrote \(out.path)")
}

if FileManager.default.fileExists(atPath: samplePDF.path) {
    print("• Visual artifacts")
    let folder = tempFolder()
    for (asset, tag) in [("stamp-100", "100"), ("stamp-50", "50")] {
        let stampURL = repoRoot.appendingPathComponent("Resources/\(asset).png")
        if let img = loadCGImage(stampURL) {
            if let out = try? PDFStamper.stamp(pdfAt: samplePDF, stampImage: img, stampRect: nil, into: folder) {
                renderPage1PNG(out, to: URL(fileURLWithPath: "/tmp/stamp-preview-\(tag).png"))
            }
        }
    }
    // Second sample, to confirm placement generalizes.
    let sample2 = repoRoot.appendingPathComponent("temp/Downloadable-PDF-Invoices-Add-On-Samples.pdf")
    if FileManager.default.fileExists(atPath: sample2.path),
       let img = loadCGImage(repoRoot.appendingPathComponent("Resources/stamp-100.png")),
       let out = try? PDFStamper.stamp(pdfAt: sample2, stampImage: img, stampRect: nil, into: folder) {
        renderPage1PNG(out, to: URL(fileURLWithPath: "/tmp/stamp-preview-sample2.png"))
    }
}

print(failures == 0 ? "\nAll tests passed." : "\n\(failures) check(s) FAILED.")
exit(failures == 0 ? 0 : 1)
