//
//  Color+AppColors.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

extension Color {
    static let appGreenDark   = Color(hex: "#546654")
    static let appGreen       = Color(hex: "#6a7c6a")
    static let appGreenMedium = Color(hex: "#7e997e")
    static let appGreenMid    = Color(hex: "#9dbb9d")
    static let appGreenLight  = Color(hex: "#b7cbb7")
    static let appGreenPale   = Color(hex: "#dbe8db")
    static let appWhite       = Color(hex: "#f8f5f0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 84, 102, 84)
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
