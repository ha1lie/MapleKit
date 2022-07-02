//
//  Preferences.swift
//  MapleKit
//
//  Created by Hallie on 6/10/22.
//

import Foundation
import SwiftUI

/// Top level preferences object
public class Preferences: Codable {
    /// Assorted preferences not belonging to any group
    public var generalPreferences: [Preference]?
    /// Groups belonging to this bundle of preferences
    public var preferenceGroups: [PreferenceGroup]?
    /// The bundle identifier these preferences are stored under
    public let bundleIdentifier: String
    /// A completion handler for when requesting a preference value from Maple using DNC
    private static var expensiveValueGetterCompletion: [String : ((PreferenceValue?) -> Void)] = [:]
    
    public init(forBundle bid: String) {
        self.generalPreferences = nil
        self.preferenceGroups = nil
        self.bundleIdentifier = bid
    }
    
    /// Add a group to the preferences object
    /// - Parameter creator: Function which returns the complete group to add
    /// - Returns: self with added PreferenceGroup
    public func withGroup(_ creator: (_ containerName: String) -> PreferenceGroup) -> Preferences {
        if self.preferenceGroups == nil {
            self.preferenceGroups = []
        }
        
        self.preferenceGroups?.append(creator(self.bundleIdentifier))
        return self
    }
    
    /// Adds an assorted preference to the leaf
    /// - Parameter creator: Function which returns the complete preference to add
    /// - Returns: self with the added preference
    public func withPreference(_ creator: (_ containerName: String) -> Preference) -> Self {
        if self.generalPreferences == nil {
            self.generalPreferences = []
        }
        self.generalPreferences?.append(creator(self.bundleIdentifier))
        return self
    }
    
    /// Get the value of a preference with it's Identification key
    /// - Parameter id: id of the preference
    /// - Returns: Value of the preference if found
    public func valueForKey(_ id: String) -> PreferenceValue? {
        return Preferences.valueForKey(id, inContainer: self.bundleIdentifier)
    }
    
    /// Gets the value of a preference in a specified container with it's id
    /// - Parameters:
    ///   - id: The id of the preference
    ///   - container: The container which stores the preference value
    /// - Returns: The value of the preference if found
    public static func valueForKey(_ id: String, inContainer container: String) -> PreferenceValue? {
        if let valueDictionary = Preferences.fetchValueDictionary(forContainer: container) {
            if let value = valueDictionary[id] {
                return PreferenceValue.fromString(value)
            }
        }
        return nil
    }
    
    /// Gets the value of a preference using DistributedNotificationCenter, which is much more expensive than another method
    /// This only fetches the value asynchronously, as it requires requests back and forth between Maple and your Leaf
    /// This method should only be used if injecting into a sandboxed process, as they won't be able to read the preferences files
    /// - Parameters:
    ///   - id: The identifier of the preference
    ///   - container: The container which holds the preference
    ///   - completion: Completion handler which gets the returned optional PreferenceValue
    public static func expensiveValueForKey(_ id: String, inContainer container: String, withCompletionHandler completion: @escaping (_ preferenceValue: PreferenceValue?) -> Void) {
        let name = Notification.Name("maple.valueRequestResponse++\(id)++\(container)")
        // Add a listener for Maple's response
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(mapleValueListener(notification:)), name: name, object: nil, suspensionBehavior: .deliverImmediately)
        // Send a notification asking for the value
        DistributedNotificationCenter.default().post(name: Notification.Name("maple.valueRequest"), object: "\(id)::\(container)")
        // Wait for listener
        Preferences.expensiveValueGetterCompletion["\(id)++\(container)"] = completion
    }
    
    /// Function called by a request listener
    /// - Parameter notification: The notification which responded to a preference value request
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
    
    /// Saves the value of a preference to users Mac
    /// - Parameters:
    ///   - val: The value of the preference to save
    ///   - key: The preference key
    ///   - container: The container to store the preference in
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
    
    /// Saves the value dictionary to the disk, updating any changes
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
    
    /// Retrieves the preference dictionary from the disk
    /// - Parameter container: The container to retrieve
    /// - Returns: A full dictionary of all stored preference values
    private static func fetchValueDictionary(forContainer container: String) -> [String : String]? {
        let fileLocation = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Maple/.prefs/\(container).json")
        if FileManager.default.fileExists(atPath: fileLocation.path) {
            if let data = try? Data(contentsOf: fileLocation) {
                return try? JSONDecoder().decode([String : String].self, from: data)
            }
        }
        return nil
    }
    
    /// Exports a machine readable file to fileName to tell Maple which preferences there are
    /// - Parameter fileName: Name of the file to output
    public func export(toFile fileName: String) {
        if let jsonData = try? JSONEncoder().encode(self) {
            FileManager.default.createFile(atPath: fileName, contents: jsonData)
        }
    }
}
