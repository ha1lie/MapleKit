//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/14/22.
//

import Foundation
import SwiftUI

extension Color: MaplePreferenceCompatible {
    
    enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
    }
    
    public func encode(to encoder: Encoder) throws {
        if let parts = self.cgColor_.components {
            if parts.count == 4 {
                // Correct number of parts
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(parts[0], forKey: .red)
                try container.encode(parts[1], forKey: .green)
                try container.encode(parts[2], forKey: .blue)
                try container.encode(parts[3], forKey: .alpha)
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decodeIfPresent(CGFloat.self, forKey: .red)
        let green = try container.decodeIfPresent(CGFloat.self, forKey: .green)
        let blue = try container.decodeIfPresent(CGFloat.self, forKey: .blue)
        let alpha = try container.decodeIfPresent(CGFloat.self, forKey: .alpha)
        if let red = red, let green = green, let blue = blue, let alpha = alpha {
            self.init(NSColor(red: red, green: green, blue: blue, alpha: alpha))
        } else {
            self.init(white: 1.0)
        }
    }
    
    /// CGColor created coercively without SwiftUI slipping up
    var cgColor_: CGColor {
        NSColor(self).cgColor
    }
    
    public func saveForPreferences(withID id: String, inContainer container: String) {
        UserDefaults(suiteName: container)?.setColor(self, forKey: id)
    }
    
    public func getFromPreferences(prefWithID id: String, inContainer container: String) -> Color? {
        return UserDefaults(suiteName: container)?.color(forKey: id)
    }
}
