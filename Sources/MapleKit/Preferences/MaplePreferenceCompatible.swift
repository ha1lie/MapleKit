//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/18/22.
//

import Foundation

/// Protocol which allows any given class to be stored in preferences
public protocol MaplePreferenceCompatible: Codable {
    /// Function called when saving a value to preferences on disk
    /// - Parameters:
    ///   - id: The preference's identifier
    ///   - container: The container which this preference belongs to
    func saveForPreferences(withID id: String, inContainer container: String)
    /// Function called when retreiving a value from preferences on disk
    /// - Parameters:
    ///   - id: The preference's identifier
    ///   - container: The container which holds this preference
    /// - Returns: The value of the preference
    func getFromPreferences(prefWithID id: String, inContainer container: String) -> Self?
}

public extension MaplePreferenceCompatible {
    func saveForPreferences(withID id: String, inContainer container: String) {
        UserDefaults(suiteName: container)?.set(self, forKey: id)
    }
    
    func getFromPreferences(prefWithID id: String, inContainer container: String) -> Self? {
        return UserDefaults(suiteName: container)?.value(forKey: id) as? Self
    }
}
