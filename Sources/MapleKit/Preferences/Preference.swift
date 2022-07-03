//
//  Preference.swift
//  MapleKit
//
//  Created by Hallie on 6/1/22.
//

import Foundation
import SwiftUI

/// > An object used to represent a user's preferences within your Leaf.
///
/// Any Preference object may be used to theoretically represent a preference(eg. within your code), or for display to a user(eg. within Maple's settings app)
public class Preference: Identifiable, Hashable, Codable {
    
    /// Name of the preference displayed to the user
    public var name: String
    
    /// Description of the preference displayed to the user
    public var description: String?
    
    /// Private identifier of the preference, used to access when needed
    public var id: String
    
    /// The default `PreferenceValue` of this preference
    public var defaultValue: PreferenceValue?
    
    /// The name of the container this preference will be stored in
    public var containerName: String
    
    /// The `PreferenceType` of the value stored by this preference
    public var preferenceType: PreferenceType
    
    /// Function to run when the value of this preference changes
    private var onSet: ((_ newValue: PreferenceValue) -> Void)?
    
    /// Creates a new `Preference` object
    /// - Parameters:
    ///   - name: The name of this `Preference` displayed to the user
    ///   - description: The description of this `Preference`, if it has one
    ///   - prefType: The `PreferenceType` of this `Preference`
    ///   - defaultValue: The default `PreferenceValue`, if it improves UX to have one
    ///   - id: The unique identifier for this `Preference`
    ///   - container: The Bundle/Container name of this `Preference`, eg. the ID of the `PreferenceGroup` or `Preferences` to which it belongs
    ///   - onSet: Method to run when observing a change of this `Preference`'s value
    public init(withTitle name: String, description: String? = nil, withType prefType: PreferenceType, defaultValue: PreferenceValue? = nil, andIdentifier id: String, forContainer container: String, toRunOnSet onSet: ((_ newValue: PreferenceValue) -> Void)? = nil) {
        self.name = name
        self.description = description
        self.preferenceType = prefType
        self.defaultValue = defaultValue
        self.id = id
        self.containerName = container
        self.onSet = onSet
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(valueChanged), name: NSNotification.Name(rawValue: self.id), object: nil, suspensionBehavior: .deliverImmediately)
    }
    
    /// Runs when there is an observation of a value change
    /// - Parameter notification: The notification which triggered this run
    @objc func valueChanged(notification: Notification) {
        if let value = PreferenceValue.fromString(notification.object as? String ?? ""), let runner = self.onSet {
            //NOTE: This may seem cyclical(ex. why not call the function directly, however
            //      Consider the Leaf itself running in another function which will not
            //      be told to run it's onSet
            runner(value)
        }
    }
    
    /// Stores the value of this preference to persist. This method utilizes the `MaplePreferenceCompatible.saveForPreferences(withID:inContainer:)` method in the wrapped class within this preferences `PreferenceValue` type
    /// - Parameter val: The new `PreferenceValue` to assign to this preference
    public func setValue(_ val: PreferenceValue) {
        guard val != self.getValue() else { return } // There's got to be a more efficient way to do this, but if there is, I don't know of it
        Preferences.saveValue(val, withKey: self.id, toContainer: self.containerName)
        // Send a notification to the observers of this value
        DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: self.id), object: val.toString(), userInfo: nil, deliverImmediately: true)
    }
    
    /// Retrieve the `PreferenceValue` for this `Preference`
    /// - Returns: `PreferenceValue` for this `Preference` if found
    public func getValue() -> PreferenceValue? {
        let returnable = Preferences.valueForKey(self.id, inContainer: self.containerName)
        if returnable == nil {
            // The user's defaults didn't have anything
            return self.defaultValue
        }
        return returnable
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
    }
    
    public static func == (lhs: Preference, rhs: Preference) -> Bool {
        return lhs.id == rhs.id
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case id
        case containerName
        case defaultValue
        case preferenceType
    }
}
