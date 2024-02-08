// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @c NSNotification name for receiving ILRD events.
/// To listen for ILRD notification events, register a notification handler using this constant as the notification name.
/// @code
/// [NSNotificationCenter.defaultCenter addObserverForName:kHeliumDidReceiveILRDNotification
///                                                 object:nil
///                                                  queue:nil
///                                             usingBlock:^(NSNotification * _Nonnull notification) {
///   // Extract the ILRD payload.
///   HeliumImpressionData *ilrd = (HeliumImpressionData *)notification.object;
///   NSString *placement = ilrd.placement;
///   NSDictionary *json = ilrd.jsonData;
/// }];
/// @endcode
FOUNDATION_EXPORT NSString *const kHeliumDidReceiveILRDNotification
__attribute__((deprecated("Use `NSNotification.heliumDidReceiveILRD` instead.")));

NS_ASSUME_NONNULL_END
