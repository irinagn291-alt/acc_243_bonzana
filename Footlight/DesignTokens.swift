import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #3C3C3C
    static let bg = Color(red: 0.235294, green: 0.235294, blue: 0.235294)
    static let bgHex = "#3C3C3C"
    /// #535353
    static let surface = Color(red: 0.325490, green: 0.325490, blue: 0.325490)
    static let surfaceHex = "#535353"
    /// #FFFFFF
    static let ink = Color(red: 1.000000, green: 1.000000, blue: 1.000000)
    static let inkHex = "#FFFFFF"
    /// #CE82FF
    static let accent = Color(red: 0.807843, green: 0.509804, blue: 1.000000)
    static let accentHex = "#CE82FF"
    /// #BABABA
    static let muted = Color(red: 0.729412, green: 0.729412, blue: 0.729412)
    static let mutedHex = "#BABABA"
    static let fontFamily = "Palatino"
}
