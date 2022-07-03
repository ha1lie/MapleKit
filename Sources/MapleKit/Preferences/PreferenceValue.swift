//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/18/22.
//

import Foundation
import SwiftUI

/// The value of a `Preference` object
public enum PreferenceValue: Codable, Equatable {
    public static func == (lhs: PreferenceValue, rhs: PreferenceValue) -> Bool {
        return lhs.toString() == rhs.toString()
    }
    
    enum CodingKeys: String, CodingKey {
        case prefValue
    }
    
    /// Errors thrown when initializing a `PreferenceValue` from a Decoder
    enum PreferenceValueError: Error {
        case nondecodable
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.toString(), forKey: .prefValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let pref = PreferenceValue.fromString(try container.decode(String.self, forKey: .prefValue)) {
            self = pref
        } else {
            throw PreferenceValueError.nondecodable
        }
    }
    
    case color(Color?)
    case string(String?)
    case bool(Bool?)
    case number(CGFloat?)
    case unknown(Any?)
    
    /// Translates this `PreferenceValue` to a String representation
    /// - Returns: String representation of this `PreferenceValue`
    public func toString() -> String {
        var value = ""
        switch self {
        case .color(let color):
            value += "color"
            if let color = color {
                if let data = try? JSONEncoder().encode(color) {
                    if let stringValue = String(data: data, encoding: .utf8) {
                        value += stringValue
                    }
                }
            }
        case .string(let string):
            value += "string\(string ?? "")"
        case .bool(let bool):
            value += "bool "
            if let bool = bool {
                value += bool ? "1" : "0"
            }
        case .number(let number):
            value += "numbe\(number ?? 0.0)"
        case .unknown(_):
            return ""
        }
        return value
    }
    
    /// Translates String representation to a `PreferenceValue` object pointing to the correct value
    /// - Parameter val: The String representation of this `PreferenceValue`
    /// - Returns: `PreferenceValue` object if val was a valid String representation
    public static func fromString(_ val: String) -> PreferenceValue? {
        let magicIndex = val.index(val.startIndex, offsetBy: 5)
        let dec = val.prefix(upTo: magicIndex)
        
        if dec.count < 5 {
            // This should not work
            return nil
        }
        
        let value = val.suffix(from: magicIndex)
        
        switch dec {
        case "string":
            // String
            return .string(String(value))
        case "bool ":
            // Bool
            return .bool(value == "1" ? true : false)
        case "numbe":
            // Number
            return .number(CGFloat(Double(value) ?? 0.0))
        case "color":
            if let data = value.data(using: .utf8) {
                return .color(try? JSONDecoder().decode(Color.self, from: data))
            }
            return .color(nil)
        default:
            return .unknown(nil)
        }
    }
}
