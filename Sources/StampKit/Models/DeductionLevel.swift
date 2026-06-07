import Foundation

/// The tax-deduction level the user picks per document. Selects which stamp image to apply.
enum DeductionLevel: String, CaseIterable, Identifiable {
    case full
    case half

    var id: String { rawValue }

    /// User-facing label.
    var label: String {
        switch self {
        case .full: return "100%"
        case .half: return "50%"
        }
    }

    /// Bundled PNG resource name (without extension).
    var assetName: String {
        switch self {
        case .full: return "stamp-100"
        case .half: return "stamp-50"
        }
    }
}
