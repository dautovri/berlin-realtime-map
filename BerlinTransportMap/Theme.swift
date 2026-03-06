import SwiftUI

enum TransportTheme {
    enum Stop {
        static let haltestelleYellow = Color(hex: "#FFD800")
        static let haltestelleGreen = Color(hex: "#006F3C")
        static let shadowOpacity: Double = 0.3
    }

    enum Status {
        static let live = Color.green.opacity(0.9)
        static let cached = Color.orange.opacity(0.9)
        static let offline = Color.red.opacity(0.9)
        static let delay = Color.red
        static let cancelled = Color.red.opacity(0.5)
        static let predicted = Color.blue
    }

    enum Map {
        static let routeAccent = Color.blue
        static let routeOverlay = Color.black.opacity(0.35)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

extension Color {
    static let haltestelleYellow = Color(hex: "#FFD800")
    static let haltestelleGreen = Color(hex: "#006F3C")
}
