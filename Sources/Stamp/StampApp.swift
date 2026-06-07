import StampKit
import SwiftUI

@main
struct StampApp: App {
    var body: some Scene {
        WindowGroup {
            StampRootView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}
