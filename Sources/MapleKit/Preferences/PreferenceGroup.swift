//
//  PreferenceGroup.swift
//  MapleKit
//
//  Created by Hallie on 6/10/22.
//

import Foundation

/// > A collection of `Preference` objects which make sense to be stored together.
///
/// A PreferenceGroup should only be used to group preferences for the sake of a user.
///
/// ## Example
///
/// Use a `PreferenceGroup` to contain all color configurations for your UI Leaf: Background Color, Foreground Color, Icon Color, etc.
public class PreferenceGroup: Identifiable, Hashable, Codable, ObservableObject {
    
    /// The container or group which these preferences belong to
    public var containerName: String
    
    /// List of `Preference` objects stored
    public var preferences: [Preference]?
    
    /// The name of the group displayed to the user
    public var name: String
    
    /// The description of the group displayed to the user
    public var description: String?
    
    /// A unique identifier of the group
    public var id: String
    
    /// Preference key which determines if this group is shown to the user
    /// The value stored by this key must have a boolean value
    public var optionallyShownKey: String?
    
    /// True if this PreferenceGroup should be shown to the user
    @Published public var canShow: Bool
    
    /// Runs when the `PreferenceValue` controlling this groups visibility changes
    /// - Parameter notification: The notification which triggered this change
    @objc func updateCanShow(notification: Notification) {
        if let allowed = PreferenceValue.fromString(notification.object as? String ?? "") {
            switch allowed {
            case .bool(let optional):
                if let optional = optional {
                    self.canShow = optional
                }
            default:
                ()
            }
        }
    }
    
    /// Store an additional `Preference` in this `PreferenceGroup`
    /// - Parameter creator: Function which creates and returns a valid `Preference` object
    /// - Returns: Self with the new `Preference` appended
    public func withPreference(_ creator: (_ groupContainer: String) -> Preference) -> PreferenceGroup {
        if self.preferences == nil {
            self.preferences = []
        }
        
        self.preferences?.append(creator(self.containerName))
        
        return self
    }
    
    public static func == (lhs: PreferenceGroup, rhs: PreferenceGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.containerName = try container.decode(String.self, forKey: .containerName)
        self.preferences = try container.decode([Preference].self, forKey: .preferences)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.id = try container.decode(String.self, forKey: .id)
        self.optionallyShownKey = try container.decodeIfPresent(String.self, forKey: .optionallyShownKey)

        if let optionalKey = self.optionallyShownKey {
            let prefVal = Preferences.valueForKey(optionalKey, inContainer: self.containerName)
            switch prefVal {
            case .bool(let boolValue):
                self.canShow = boolValue ?? false
            default:
                self.canShow = false
            }
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(updateCanShow(notification:)), name: NSNotification.Name(rawValue: optionalKey), object: nil)
        } else {
            self.canShow = true
        }
    }
    
    /// Creates a new `PreferenceGroup`
    /// - Parameters:
    ///   - name: The name of this `PreferenceGroup` displayed to the user
    ///   - description: The description of this `PreferenceGroup`, if it has one
    ///   - id: The unique identifier which refers to this `PreferenceGroup`
    ///   - container: The identifier of the containing `Preferences` object
    ///   - optionalKey: An optional argument, the key which points to a boolean `Preference` which determines the visibility of this `PreferenceGroup`
    public init(withName name: String, description: String? = nil, andIdentifier id: String, forContainer container: String, optionallyShownIfKeyIsTrue optionalKey: String? = nil) {
        self.name = name
        self.description = description
        self.id = id
        self.containerName = container
        self.optionallyShownKey = optionalKey
        if let optionalKey = self.optionallyShownKey {
            let prefVal = Preferences.valueForKey(optionalKey, inContainer: self.containerName)
            switch prefVal {
            case .bool(let boolVal):
                self.canShow = boolVal ?? false
            default:
                self.canShow = false
            }
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(updateCanShow(notification:)), name: NSNotification.Name(rawValue: optionalKey), object: nil)
        } else {
            self.canShow = true
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case containerName
        case preferences
        case name
        case description
        case id
        case optionallyShownKey
    }
}
