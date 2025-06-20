//
//  Color+AppColors.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

extension Color {
    static let appTan = Color(hex: "#d8bfa0")
    static let appTanLight = Color(hex: "#e1c7a6")
    static let appGray = Color(hex: "#c6c4c0")
    static let appGreen = Color(hex: "#546654")
    static let appBrown = Color(hex: "#7c5e3c")
    static let appWhite = Color(hex: "#f8f5f0")
    static let appBlue = Color(hex: "#7a8fa6")
    static let appCoral = Color(hex: "#e6a692")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 216, 191, 160)
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
