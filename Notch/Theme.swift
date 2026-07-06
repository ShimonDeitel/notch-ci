import SwiftUI

/// Notch's identity: a sky-blue/grass-green nursery-wall palette with a
/// warm pencil-mark wood accent (the literal doorframe pencil-notch motif)
/// — distinct from every sibling palette.
enum NOTheme {
    static let backdrop = Color(red: 0.918, green: 0.953, blue: 0.973)  // pale sky-blue
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.867, green: 0.925, blue: 0.949)
    static let ink = Color(red: 0.157, green: 0.180, blue: 0.169)       // deep forest-ink
    static let inkFaded = Color(red: 0.157, green: 0.180, blue: 0.169).opacity(0.56)
    static let rule = Color.black.opacity(0.08)

    static let sky = Color(red: 0.376, green: 0.635, blue: 0.784)
    static let skyDeep = Color(red: 0.220, green: 0.478, blue: 0.635)
    static let grass = Color(red: 0.412, green: 0.663, blue: 0.322)
    static let pencil = Color(red: 0.788, green: 0.549, blue: 0.325)    // wood-pencil tan
    static let danger = Color(red: 0.729, green: 0.290, blue: 0.243)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
