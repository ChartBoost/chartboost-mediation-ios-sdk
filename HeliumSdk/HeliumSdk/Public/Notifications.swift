// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension Notification.Name {
    /// `Notification.Name` for receiving ILRD events.
    /// To listen for ILRD notification events, register a notification handler using this constant as the notification name.
    ///
    /// ```
    /// NotificationCenter.default.addObserver(
    ///     forName: .heliumDidReceiveILRD,
    ///     object: nil,
    ///     queue: nil
    /// ) { notification in
    ///     // Extract the ILRD payload.
    ///     guard let ilrd = notification.object as? HeliumImpressionData else { return }
    ///     let placement = ilrd.placement
    ///     let json = ilrd.jsonData
    /// }
    /// ```
    public static let heliumDidReceiveILRD = Notification.Name("com.chartboost.helium.notification.ilrd")

    /// `Notification.Name` for receiving initialization result events.
    /// To listen for initialization result notification events, register a notification handler using this constant as the
    /// notification name.
    ///
    /// ```
    /// NotificationCenter.default.addObserver(
    ///     forName: .heliumDidReceiveInitResults,
    ///     object: nil,
    ///     queue: nil
    /// ) { notification in
    ///     // Extract the results payload.
    ///     guard let dictionary = notification.object as? [String: Any] else { return }
    /// }
    /// ```
    public static let heliumDidReceiveInitResults = Notification.Name(rawValue: "com.chartboost.helium.notification.init")
}

// swiftlint:disable legacy_objc_type
@objc
extension NSNotification {
    /// `NSNotification` for receiving ILRD events.
    /// To listen for ILRD notification events, register a notification handler using this constant as the notification name.
    ///
    /// ```
    /// [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.heliumDidReceiveILRD
    ///                                                 object:nil
    ///                                                  queue:nil
    ///                                             usingBlock:^(NSNotification * _Nonnull notification) {
    ///     // Extract the ILRD payload.
    ///     HeliumImpressionData *ilrd = notification.object;
    ///     NSString *placement = ilrd.placement;
    ///     NSDictionary *json = ilrd.jsonData;
    /// }];
    /// ```
    public static let heliumDidReceiveILRD = Notification.Name.heliumDidReceiveILRD

    /// `NSNotification` for receiving initialization result events.
    /// To listen for initialization result notification events, register a notification handler using this constant as the
    /// notification name.
    ///
    /// ```
    /// [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.heliumDidReceiveInitResults
    ///                                                 object:nil
    ///                                                  queue:nil
    ///                                             usingBlock:^(NSNotification * _Nonnull notification) {
    ///     // Extract the results payload.
    ///     NSDictionary *dictionary = notification.object;
    /// }];
    /// ```
    public static let heliumDidReceiveInitResults = Notification.Name.heliumDidReceiveInitResults
}
// swiftlint:enable legacy_objc_type
