#!/usr/bin/env swift
// Generates a 1024x1024 app-icon PNG: the 100% stamp on a teal rounded square.
// Run from repo root: swift Scripts/make-icon.swift  ->  build/AppIcon-1024.png
import AppKit
import Foundation

let size = 1024
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let stampURL = root.appendingPathComponent("Resources/stamp-100.png")
guard let stamp = NSImage(contentsOf: stampURL) else {
    FileHandle.standardError.write("missing Resources/stamp-100.png\n".data(using: .utf8)!); exit(1)
}

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Teal rounded-square background (#006D77).
let inset: CGFloat = 60
let bgRect = NSRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
NSColor(srgbRed: 0x00 / 255, green: 0x6D / 255, blue: 0x77 / 255, alpha: 1).setFill()
NSBezierPath(roundedRect: bgRect, xRadius: 180, yRadius: 180).fill()

// Centered stamp at ~72% width, preserving aspect.
let aspect = stamp.size.height / stamp.size.width
let stampW = CGFloat(size) * 0.72
let stampH = stampW * aspect
let stampRect = NSRect(
    x: (CGFloat(size) - stampW) / 2, y: (CGFloat(size) - stampH) / 2,
    width: stampW, height: stampH)
stamp.draw(in: stampRect, from: .zero, operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()
let out = root.appendingPathComponent("build/AppIcon-1024.png")
try? FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
try rep.representation(using: .png, properties: [:])!.write(to: out)
print("Wrote build/AppIcon-1024.png")
