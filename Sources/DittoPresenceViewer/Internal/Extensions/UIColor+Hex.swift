//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

#if canImport(UIKit)
import UIKit

extension UIColor {

    /**
     Construct a `UIColor` object from a web-style hexadecimal color
     code (e.g. `"#00BC7F"`).

     - Parameter hex: A hex string in the format `"#RRGGBB"`.
     - Returns: A `UIColor` if `hex` was valid, otherwise `nil`.
     */
    convenience init?(hex: String) {
        let charsToTrim = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "#"))
        let hexString = hex.trimmingCharacters(in: charsToTrim)

        guard hexString.count == 6 else {
            assertionFailure("Invalid hex code used as color")
            return nil
        }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgbValue) else {
            assertionFailure("Invalid hex code used as color")
            return nil
        }

        self.init(red:   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8)  / 255.0,
                  blue:  CGFloat((rgbValue & 0x0000FF) >> 0)  / 255.0,
                  alpha: 1.0)
    }

    /**
     Converts a `UIColor` object into a web-style hexadecimal color code.

     - Returns: A tuple containing a hex string in the format `"#RRGGBB"` and
       an opacity value.
     */
    func toHexString() -> (String, Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let hexString = String(format:"#%06X",
                               (Int)(r * 255) << 16 |
                               (Int)(g * 255) <<  8 |
                               (Int)(b * 255) <<  0)
        return (hexString, Double(a))
    }

}
#endif
