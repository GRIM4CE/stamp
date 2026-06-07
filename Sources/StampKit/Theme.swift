import SwiftUI

/// App color palette (provided by the user).
enum Theme {
    static let stormyTeal = Color(hex: 0x006D77)
    static let pearlAqua = Color(hex: 0x83C5BE)
    static let aliceBlue = Color(hex: 0xEDF6F9)
    static let almondSilk = Color(hex: 0xFFDDD2)
    static let tangerineDream = Color(hex: 0xE29578)
    /// Dark navy for text on the light panels (which use fixed-light backgrounds,
    /// so we can't rely on the appearance-adaptive system label colors).
    static let inkNavy = Color(hex: 0x14213D)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
