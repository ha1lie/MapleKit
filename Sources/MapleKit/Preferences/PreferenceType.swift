//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/18/22.
//

import Foundation

/// The type of value which a `Preference` object stores
public enum PreferenceType: Codable {
    case color
    case string
    case bool
    case number
    case unknown
}
