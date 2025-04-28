// Constants.swift
import SwiftUI

struct Constants {
    // Colors - adjusted for better contrast in light mode
    static let bgDark = Color(UIColor.systemGray6) // Light background
    static let bgCard = Color(UIColor.systemGray5) // Card background
    static let bgHeader = Color(UIColor.systemGray4) // Header background
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let blue = Color(hex: "#3498db")
    static let orange = Color(hex: "#e67e22")
    static let green = Color(hex: "#2ecc71")
    static let red = Color(hex: "#e74c3c")
    static let purple = Color(hex: "#8e44ad")
    static let darkPurple = Color(hex: "#8e44ad")
    static let yellow = Color(hex: "#f1c40f")
    
    // API URLs
    static let clashOfClansBaseURL = "https://api.clashofclans.com/v1"
    static let clashKingBaseURL = "https://api.clashk.ing"
    static let clashSpotBaseURL = "https://clashspot.net/en"
    
    // UI Constants
    static let cornerRadius: CGFloat = 12
    static let innerCornerRadius: CGFloat = 10
    static let buttonCornerRadius: CGFloat = 8
    
    // Return colors adjusted based on dark/light mode
    static func dynamicColor(light: Color, dark: Color) -> Color {
        @AppStorage("isDarkMode") var isDarkMode: Bool = true
        return isDarkMode ? dark : light
    }
    
    // Dynamic background
    static var background: Color {
        dynamicColor(light: bgDark, dark: Color(UIColor.systemGray6).opacity(0.9))
    }
    
    // Dynamic card background
    static var cardBackground: Color {
        dynamicColor(light: bgCard, dark: Color(UIColor.systemGray5).opacity(0.9))
    }
    
    // Dynamic header background - Using the black color from trophy progression in dark mode
    static var headerBackground: Color {
        dynamicColor(light: Color(UIColor.systemGray4), dark: Color.black)
    }
    
    // Dynamic header text color
    static var headerTextColor: Color {
        dynamicColor(light: Color.black.opacity(0.8), dark: Color.white)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extensions for formatting
extension Int {
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var percentString: String {
        return String(format: "%.2f%%", self)
    }
}

// Date formatting helpers
extension String {
    func toDate(format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}

extension Date {
    func toString(format: String = "MMM d") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
