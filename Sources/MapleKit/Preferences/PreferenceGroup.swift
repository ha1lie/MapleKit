//
//  PreferenceGroup.swift
//  MapleKit
//
//  Created by Hallie on 6/10/22.
//

import Foundation

/// A group of preferences which store data related to each other
public class PreferenceGroup: Identifiable, Hashable, Codable, ObservableObject {
    /// The container or group which these preferences belong to
    public var containerName: String
    /// Preferences which this group contains
    public var preferences: [Preference]?
    /// The name of the group presented to the user
    public var name: String
    /// The description of the group presented to the user
    public var description: String?
    /// Identifier of the group
    /// Req: Must be unique
    public var id: String
    /// Preference key which determines if this group is shown to the user
    /// The value stored by this key must have a boolean value
    public var optionallyShownKey: String?
    /// True if this PreferenceGroup should be shown to the user
    @Published public var canShow: Bool
    
    /// Runs when the value of the preference controlling this groups visibility changes
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
    
    /// Add a preference to the group
    /// - Parameter creator: The function which returns the preference to add
    /// - Returns: The preference group with the above preference added(self)
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
