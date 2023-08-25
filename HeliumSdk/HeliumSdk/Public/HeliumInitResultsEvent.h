// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @c NSNotification name for receiving initialization result events.
/// To listen for initialization result notification events, register a notification handler using this constant as the notification name.
/// @code
/// [NSNotificationCenter.defaultCenter addObserverForName:kHeliumDidReceiveInitResultsNotification
///                                                 object:nil
///                                                  queue:nil
///                                             usingBlock:^(NSNotification * _Nonnull notification) {
///   // Extract the results payload.
///   NSDictionary *results = (NSDictionary *)notification.object;
/// }];
/// @endcode
FOUNDATION_EXPORT NSString *const kHeliumDidReceiveInitResultsNotification
__attribute__((deprecated("Use `NSNotification.heliumDidReceiveInitResults` instead.")));

NS_ASSUME_NONNULL_END
