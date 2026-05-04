import SwiftUI

enum BrainlessTheme {
    static let bg       = Color(red: 245/255, green: 242/255, blue: 236/255)
    static let bgElev   = Color(red: 251/255, green: 249/255, blue: 244/255)
    static let bgCard   = Color.white
    static let surface2 = Color(red: 237/255, green: 232/255, blue: 222/255)

    static let ink             = Color(red: 26/255, green: 23/255, blue: 20/255)
    static let inkDim          = Color(red: 26/255, green: 23/255, blue: 20/255).opacity(0.62)
    static let inkFaint        = Color(red: 26/255, green: 23/255, blue: 20/255).opacity(0.40)
    static let inkHair         = Color(red: 26/255, green: 23/255, blue: 20/255).opacity(0.10)
    static let inkHairStrong   = Color(red: 26/255, green: 23/255, blue: 20/255).opacity(0.18)

    static let accent      = Color(red: 61/255, green: 110/255, blue: 74/255)
    static let accentDeep  = Color(red: 42/255, green: 79/255, blue: 51/255)
    static let accentSoft  = Color(red: 61/255, green: 110/255, blue: 74/255).opacity(0.10)
}
