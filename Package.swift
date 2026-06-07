// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Stamp",
    platforms: [.macOS(.v13)],
    targets: [
        // All app logic + UI. A library so both the app and the test runner can link it.
        .target(
            name: "StampKit",
            path: "Sources/StampKit"
        ),
        // The macOS app entry point.
        .executableTarget(
            name: "Stamp",
            dependencies: ["StampKit"],
            path: "Sources/Stamp"
        ),
        // XCTest / Swift Testing aren't available under Command Line Tools (no Xcode),
        // so tests run as a plain executable: `swift run StampTests`.
        .executableTarget(
            name: "StampTests",
            dependencies: ["StampKit"],
            path: "Tests/StampTests"
        ),
    ]
)
