//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/18/22.
//

import Foundation

/// Protocol which allows any given class to be stored in preferences
public protocol MaplePreferenceCompatible: Codable {
    /// Function called when saving a value to `Preferences` on disk
    /// - Parameters:
    ///   - id: The `Preference`'s identifier
    ///   - container: The container which this `Preference` belongs to
    func saveForPreferences(withID id: String, inContainer container: String)
    
    /// Function called when retreiving a value from `Preferences` on disk
    /// - Parameters:
    ///   - id: The `Preference`'s identifier
    ///   - container: The container which holds this `Preference`
    /// - Returns: The value of the `Preference`
    func getFromPreferences(prefWithID id: String, inContainer container: String) -> Self?
}

public extension MaplePreferenceCompatible { // Default implementations for most classes conforming to this protocol
    func saveForPreferences(withID id: String, inContainer container: String) {
        UserDefaults(suiteName: container)?.set(self, forKey: id)
    }
    
    func getFromPreferences(prefWithID id: String, inContainer container: String) -> Self? {
        return UserDefaults(suiteName: container)?.value(forKey: id) as? Self
    }
}
