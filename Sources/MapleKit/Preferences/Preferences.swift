//
//  Preferences.swift
//  MapleKit
//
//  Created by Hallie on 6/10/22.
//

import Foundation
import SwiftUI

/// > Top level object containing all Preferences and metadata for your Leaf
///
/// This class also contains most of the logic for dealing with the value of given preferences
public class Preferences: Codable {
    
    /// Assorted `Preference` objects belonging to this bundle
    public var generalPreferences: [Preference]?
    
    /// Assorted `PreferenceGroup` objects belonging to this bundle
    public var preferenceGroups: [PreferenceGroup]?
    
    /// The bundle identifier associated with these `Preferences`
    public let bundleIdentifier: String
    
    /// A completion handler for when requesting a preference value from Maple using DNC
    private static var expensiveValueGetterCompletion: [String : ((PreferenceValue?) -> Void)] = [:]
    
    /// Creates an empty `Preferences` object
    /// - Parameter bid: The unique identifier which contains these preferences. It's recommended to use the Bundle Identifier of your Leaf
    public init(forBundle bid: String) {
        self.generalPreferences = nil
        self.preferenceGroups = nil
        self.bundleIdentifier = bid
    }
    
    /// Add a `PreferenceGroup` to the `Preferences` object
    /// - Parameter creator: Method which returns a valid `PreferenceGroup` object to add
    /// - Returns: Self with the new `PreferenceGroup` appended
    public func withGroup(_ creator: (_ containerName: String) -> PreferenceGroup) -> Preferences {
        if self.preferenceGroups == nil {
            self.preferenceGroups = []
        }
        
        self.preferenceGroups?.append(creator(self.bundleIdentifier))
        return self
    }
    
    /// Store an additional `Preference` in this `Preferences` object
    /// - Parameter creator: Function which creates and returns a valid `Preference` object
    /// - Returns: Self with the new `Preference` appended
    public func withPreference(_ creator: (_ containerName: String) -> Preference) -> Self {
        if self.generalPreferences == nil {
            self.generalPreferences = []
        }
        self.generalPreferences?.append(creator(self.bundleIdentifier))
        return self
    }
    
    /// Get the `PreferenceValue` of a given `Preference` using it's identifier
    /// - Parameter id: Unique identifier of the `Preference`
    /// - Returns: `PreferenceValue` if found
    public func valueForKey(_ id: String) -> PreferenceValue? {
        return Preferences.valueForKey(id, inContainer: self.bundleIdentifier)
    }
    
    /// Get the `PreferenceValue` of a given `Preference` using it's identifier
    /// - Parameters:
    ///   - id: Unique identifier of the `Preference`
    ///   - container: The container or `Preferences` unique identifier of which it belongs
    /// - Returns: `PreferenceValue` if found
    public static func valueForKey(_ id: String, inContainer container: String) -> PreferenceValue? {
        if let valueDictionary = Preferences.fetchValueDictionary(forContainer: container) {
            if let value = valueDictionary[id] {
                return PreferenceValue.fromString(value)
            }
        }
        return nil
    }
    
    /// Gets the value of a preference using DistributedNotificationCenter, which is much more expensive than another method
    /// This only fetches the value asynchronously, as it requires multiple requests back and forth between Maple and your Leaf
    /// This method should only be used if injecting into a [Sandboxed Process](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox/), as they won't be able to read the preferences files outside of their Sandbox
    /// - Parameters:
    ///   - id: Unique identifier of the `Preference`
    ///   - container: The container or `Preferences` unique identifier of which it belongs
    ///   - completion: Completion handler run when the optional `PreferenceValue` is returned
    public static func expensiveValueForKey(_ id: String, inContainer container: String, withCompletionHandler completion: @escaping (_ preferenceValue: PreferenceValue?) -> Void) {
        let name = Notification.Name("maple.valueRequestResponse++\(id)++\(container)")
        // Add a listener for Maple's response
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(mapleValueListener(notification:)), name: name, object: nil, suspensionBehavior: .deliverImmediately)
        // Send a notification asking for the value
        DistributedNotificationCenter.default().post(name: Notification.Name("maple.valueRequest"), object: "\(id)::\(container)")
        // Wait for listener
        Preferences.expensiveValueGetterCompletion["\(id)++\(container)"] = completion
    }
    
    /// **DNC** DistributedNotificationCenter listener's method
    /// - Parameter notification: The Notification which responded to a preference value request from `static expensiveValueForKey(_:inContainer:withCompletionHandler:)`
    @objc private static func mapleValueListener(notification: Notification) {
        if let response = notification.object as? String {
            guard notification.name.rawValue.count > 28 else { return }
            let pieces = notification.name.rawValue.suffix(from: notification.name.rawValue.index(notification.name.rawValue.startIndex, offsetBy: 28))
            if let comp = Preferences.expensiveValueGetterCompletion[String(pieces)] {
                comp(PreferenceValue.fromString(response))
            }
            Preferences.expensiveValueGetterCompletion[String(pieces)] = nil
        }
    }
    
    /// Saves the `PreferenceValue` of a `Preference` to the user's Mac
    /// - Parameters:
    ///   - val: `PreferenceValue` object to store
    ///   - key: The unique identifier of the `Preference` with which to associate this `PreferenceValue`
    ///   - container: The container or `Preferences` unique identifier of which it belongs
    public static func saveValue(_ val: PreferenceValue, withKey key: String, toContainer container: String) {
        //NOTE: Can only store [String : String] in these files :( begging for swift 5.7
        if key != "nil" && container != "nil" {
            let value = val.toString()
            if var valueDictionary = Preferences.fetchValueDictionary(forContainer: container) {
                valueDictionary[key] = value
                Preferences.saveValueDictionary(valueDictionary, toContainer: container)
            } else {
                Preferences.saveValueDictionary([key : value], toContainer: container)
            }
        }
    }
    
    /// **DNC** Saves the value dictionary to the disk, updating any changes
    /// - Parameters:
    ///   - dict: The dictionary of keys and preference values
    ///   - container: The container in which to store the preference
    private static func saveValueDictionary(_ dict: [String : String], toContainer container: String) {
        let fileLocation = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Maple/.prefs/\(container).json")
        if let data = try? JSONEncoder().encode(dict) {
            if FileManager.default.fileExists(atPath: fileLocation.path) {
                try? FileManager.default.removeItem(at: fileLocation)
            }
            
            try? FileManager.default.createDirectory(at: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Maple/.prefs/"), withIntermediateDirectories: true)
            
            FileManager.default.createFile(atPath: fileLocation.path, contents: data)
        }
    }
    
    /// **DNC** Retrieves the preference dictionary from the disk
    /// - Parameter container: The unique identifier of the container or `Preferences` bundle to retreive
    /// - Returns: A full dictionary of all stored `PreferenceValue`s and their unique identifiers
    private static func fetchValueDictionary(forContainer container: String) -> [String : String]? {
        let fileLocation = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Maple/.prefs/\(container).json")
        if FileManager.default.fileExists(atPath: fileLocation.path) {
            if let data = try? Data(contentsOf: fileLocation) {
                return try? JSONDecoder().decode([String : String].self, from: data)
            }
        }
        return nil
    }
    
    /// Writes a JSON-formatted file readable by Maple to communicate nessecary preferences between your Leaf and Maple app
    /// - Parameter fileName: Path of the file to output
    public func export(toFile fileName: String) {
        if let jsonData = try? JSONEncoder().encode(self) {
            FileManager.default.createFile(atPath: fileName, contents: jsonData)
        }
    }
}
