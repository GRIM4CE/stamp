import SwiftUI

/// Public entry view: owns app state and wires up the UI. The only public surface
/// the app executable needs from StampKit.
public struct StampRootView: View {
    @StateObject private var state = AppState()

    public init() {}

    public var body: some View {
        ContentView()
            .environmentObject(state)
            .frame(minWidth: 980, minHeight: 640)
            // The UI is built on fixed-light panels (Theme.aliceBlue); pin the app
            // to light mode so system-colored text/controls don't flip to white on
            // dark-mode Macs and become unreadable.
            .preferredColorScheme(.light)
    }
}
