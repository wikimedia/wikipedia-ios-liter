import UIKit

public extension UIColor {
    @objc(initWithHexInteger:alpha:)
    convenience init(_ hex: Int, alpha: CGFloat) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    @objc(initWithHexInteger:)
    convenience init(_ hex: Int) {
        self.init(hex, alpha: 1)
    }
    
    class func wmf_colorWithHex(_ hex: Int) -> UIColor {
        return UIColor(hex)
    }

    // `initWithHexString:alpha:` should almost never be used. `initWithHexInteger:alpha:` is preferred.
    @objc(initWithHexString:alpha:)
    convenience init(_ hexString: String, alpha: CGFloat = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        guard hex.count == 6, Scanner(string: hex).scanHexInt64(&int) && int != UINT64_MAX else {
            assertionFailure("Unexpected issue scanning hex string: \(hexString)")
            self.init(white: 0, alpha: alpha)
            return
        }
        self.init(Int(int), alpha: alpha)
    }
    
    static let defaultShadow = UIColor(white: 0, alpha: 0.25)

    static let pitchBlack = UIColor(0x101418)

    static let base10 = UIColor(0x222222)
    static let base20 = UIColor(0x54595D)
    static let base30 = UIColor(0x72777D)
    static let base50 = UIColor(0xA2A9B1)
    static let base70 = UIColor(0xC8CCD1)
    static let base80 = UIColor(0xEAECF0)
    static let base90 = UIColor(0xF8F9FA)
    static let base100 = UIColor(0xFFFFFF)
    static let red30 = UIColor(0xB32424)
    static let red50 = UIColor(0xCC3333)
    static let red75 = UIColor(0xFF6E6E)
    static let yellow50 = UIColor(0xFFCC33)
    static let green50 = UIColor(0x00AF89)
    static let blue10 = UIColor(0x2A4B8D)
    static let blue50 = UIColor(0x3366CC)
    static let lightBlue = UIColor(0xEAF3FF)
    static let mesosphere = UIColor(0x43464A)
    static let thermosphere = UIColor(0x2E3136)
    static let stratosphere = UIColor(0x6699FF)
    static let exosphere = UIColor(0x27292D)
    static let accent = UIColor(0x00AF89)
    static let accent10 = UIColor(0x2A4B8D)
    static let amate = UIColor(0xE1DAD1)
    static let parchment = UIColor(0xF8F1E3)
    static let masi = UIColor(0x646059)
    static let papyrus = UIColor(0xF0E6D6)
    static let kraft = UIColor(0xCBC8C1)
    static let osage = UIColor(0xFF9500)
    static let sand = UIColor(0xE8DCCA)
    
    static let darkSearchFieldBackground = UIColor(0x8E8E93, alpha: 0.12)
    static let lightSearchFieldBackground = UIColor(0xFFFFFF, alpha: 0.15)

    static let masi60PercentAlpha = UIColor(0x646059, alpha:0.6)
    static let black50PercentAlpha = UIColor(0x000000, alpha:0.5)
    static let black75PercentAlpha = UIColor(0x000000, alpha:0.75)
    static let white20PercentAlpha = UIColor(white: 1, alpha:0.2)

    static let base70At55PercentAlpha = base70.withAlphaComponent(0.55)
    static let blue50At10PercentAlpha = UIColor(0x3366CC, alpha:0.1)
    static let blue50At25PercentAlpha = UIColor(0x3366CC, alpha:0.25)

    static let wmf_darkGray = UIColor(0x4D4D4B)
    static let wmf_lightGray = UIColor(0x9AA0A7)
    static let wmf_gray = UIColor.base70
    static let wmf_lighterGray = UIColor.base80
    static let wmf_lightestGray = UIColor(0xF5F5F5) // also known as refresh gray

    static let wmf_darkBlue = UIColor.blue10
    static let wmf_blue = UIColor.blue50
    static let wmf_lightBlue = UIColor.lightBlue

    static let wmf_green = UIColor.green50
    static let wmf_lightGreen = UIColor(0xD5FDF4)

    static let wmf_red = UIColor.red50
    static let wmf_lightRed = UIColor(0xFFE7E6)
    
    static let wmf_yellow = UIColor.yellow50
    static let wmf_lightYellow = UIColor(0xFEF6E7)
    
    static let wmf_orange = UIColor(0xFF5B00)
    
    static let wmf_purple = UIColor(0x7F4AB3)
    static let wmf_lightPurple = UIColor(0xF3E6FF)

    func wmf_hexStringIncludingAlpha(_ includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        var hexString = String(format: "%02X%02X%02X", Int(255.0 * r), Int(255.0 * g), Int(255.0 * b))
        if (includeAlpha) {
            hexString = hexString.appendingFormat("%02X", Int(255.0 * a))
        }
        return hexString
    }
}
