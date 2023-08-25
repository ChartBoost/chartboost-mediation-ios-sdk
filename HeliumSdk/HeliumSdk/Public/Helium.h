// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// Original Objective C implementation has been refactored in Swift.
// Keep this header file so that existing import statements do not cause compiler errors.
#import <ChartboostMediationSDK/HeliumImpressionData.h>

// Forward-declarations for retro-compatibility with existing integrations that relied on these definitions from old Obj-C headers.
@protocol CHBHeliumBannerAdDelegate;
@protocol HeliumInterstitialAd;
@protocol CHBHeliumInterstitialAdDelegate;
@protocol HeliumRewardedAd;
@protocol CHBHeliumRewardedAdDelegate;
@class HeliumBannerView;
@class HeliumInitializationOptions;
@class HeliumAdapterInfo;
typedef NS_ENUM(NSInteger, CHBHBannerSize);
@class ChartboostMediationError;
typedef ChartboostMediationError HeliumError __attribute__((deprecated("Use ChartboostMediationError instead.")));
@class Helium;
