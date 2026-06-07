#!/usr/bin/env swift
// Rasterizes the provided SVG stamps to high-res, alpha-trimmed PNGs.
// Run once during development: swift Scripts/rasterize-stamps.swift
// Output: Resources/stamp-100.png, Resources/stamp-50.png

import AppKit
import Foundation

let targetWidth: CGFloat = 1800 // high-res; downscaled when drawn into the PDF

struct Job { let svg: String; let png: String }
let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let jobs = [
    Job(svg: "temp/stamp-100.svg", png: "Resources/stamp-100.png"),
    Job(svg: "temp/stamp-50.svg",  png: "Resources/stamp-50.png"),
]

// Render an NSImage into an ARGB bitmap at the given pixel size.
func bitmap(from image: NSImage, pxWidth: Int, pxHeight: Int) -> NSBitmapImageRep? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pxWidth, pixelsHigh: pxHeight,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
    rep.size = NSSize(width: pxWidth, height: pxHeight)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pxWidth, height: pxHeight),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Find the tight bounding box of non-transparent pixels.
func alphaBounds(_ rep: NSBitmapImageRep) -> CGRect {
    let w = rep.pixelsWide, h = rep.pixelsHigh
    var minX = w, minY = h, maxX = -1, maxY = -1
    for y in 0..<h {
        for x in 0..<w {
            if let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.01 {
                if x < minX { minX = x }; if x > maxX { maxX = x }
                if y < minY { minY = y }; if y > maxY { maxY = y }
            }
        }
    }
    if maxX < 0 { return CGRect(x: 0, y: 0, width: w, height: h) }
    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

for job in jobs {
    let svgURL = repoRoot.appendingPathComponent(job.svg)
    guard let image = NSImage(contentsOf: svgURL) else {
        FileHandle.standardError.write("ERROR: NSImage could not load \(job.svg)\n".data(using: .utf8)!)
        exit(1)
    }
    let aspect = image.size.height / max(image.size.width, 1)
    let pxW = Int(targetWidth)
    let pxH = Int((targetWidth * aspect).rounded())
    guard let full = bitmap(from: image, pxWidth: pxW, pxHeight: pxH) else { exit(1) }

    // Trim transparent margins.
    let box = alphaBounds(full)
    let trimmedW = Int(box.width), trimmedH = Int(box.height)
    guard let trimmed = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: trimmedW, pixelsHigh: trimmedH,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { exit(1) }
    trimmed.size = NSSize(width: trimmedW, height: trimmedH)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: trimmed)
    // colorAt/alphaBounds use a top-left origin; AppKit drawing uses bottom-left.
    // Offset so the box's bottom edge (bottom-left y = pxH - box.maxY) lands at y=0.
    full.draw(in: NSRect(x: -box.minX, y: box.maxY - CGFloat(pxH), width: CGFloat(pxW), height: CGFloat(pxH)))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = trimmed.representation(using: .png, properties: [:]) else { exit(1) }
    let outURL = repoRoot.appendingPathComponent(job.png)
    try? FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: outURL)
    print("Wrote \(job.png) \(trimmedW)x\(trimmedH) (from \(Int(image.size.width))x\(Int(image.size.height)))")
}
