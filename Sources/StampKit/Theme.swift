import SwiftUI

/// App color palette (provided by the user).
enum Theme {
    static let stormyTeal = Color(hex: 0x006D77)
    static let pearlAqua = Color(hex: 0x83C5BE)
    static let aliceBlue = Color(hex: 0xEDF6F9)
    static let almondSilk = Color(hex: 0xFFDDD2)
    static let tangerineDream = Color(hex: 0xE29578)
    /// A hair-deeper aqua than aliceBlue (a soft teal tint), used to set the
    /// header/footer apart from the body without a hard outline.
    static let panelTint = Color(hex: 0xDAEBEF)
    /// Dark navy for text on the light panels (which use fixed-light backgrounds,
    /// so we can't rely on the appearance-adaptive system label colors).
    static let inkNavy = Color(hex: 0x14213D)
}

/// Primary call-to-action style: deep teal fill (006d77) with white text (~6:1 contrast).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Content(configuration: configuration) }

    private struct Content: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Theme.stormyTeal)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(configuration.isPressed ? 0.85 : 1)
                .opacity(isEnabled ? 1 : 0.4)
                .contentShape(Rectangle())
        }
    }
}

/// Secondary action style: white fill with a teal glyph and a soft aqua border.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Content(configuration: configuration) }

    private struct Content: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.stormyTeal)
                .padding(.vertical, 7)
                .padding(.horizontal, 11)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.pearlAqua.opacity(0.55), lineWidth: 1))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .opacity(isEnabled ? 1 : 0.4)
                .contentShape(Rectangle())
        }
    }
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
