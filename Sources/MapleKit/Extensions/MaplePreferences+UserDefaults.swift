//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/14/22.
//

import Foundation
import SwiftUI

public extension UserDefaults {
    /// Save value of a Color to UserDefaults
    /// - Parameters:
    ///   - color: Color to save
    ///   - key: Key to save Color value to
    func setColor(_ color: Color, forKey key: String) {
        let cgColor = color.cgColor_
        let array = cgColor.components ?? []
        set(array, forKey: key)
    }
    
    /// Get Color value in UserDefaults
    /// - Parameter key: Key color value is stored at
    /// - Returns: Color, if previously stored
    func color(forKey key: String) -> Color? {
        guard let array = object(forKey: key) as? [CGFloat] else { return nil }
        let color = CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: array)!
        return Color(color)
    }
}
