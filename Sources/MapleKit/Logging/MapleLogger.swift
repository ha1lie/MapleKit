//
//  File.swift
//  MapleKit
//
//  Created by Hallie on 6/20/22.
//

import Foundation

/// A Logging utility to help with debugging
/// All logs sent via `MapleLogger` will appear in Maple's Log Window
public class MapleLogger {
    /// The bundle name shown with these Logs
    let bundle: String
    
    /// The Notification.Name listened for by Maple
    private static let logNotification: Notification.Name = Notification.Name(rawValue: "maple.log")
    
    /// Creates a Logger for a given Bundle name
    /// - Parameter bundle: Bundle name which will be referenced in logs
    public init(forBundle bundle: String) {
        self.bundle = bundle
    }
    
    /// Logs to Maple's central log controler
    /// - Parameter log: Log to send
    public func log(_ log: String) {
        DistributedNotificationCenter.default().post(name: MapleLogger.logNotification, object: "\(self.bundle)+++\(log)", userInfo: nil)
    }
}
