// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// Public headers in ChartboostMediationSDK.h
#import <ChartboostMediationSDK/Helium.h>
#import <ChartboostMediationSDK/HeliumDelegates.h>
#import <ChartboostMediationSDK/HeliumImpressionData.h>
#import <ChartboostMediationSDK/HeliumInitResultsEvent.h>

#import <ChartboostMediationSDK/ChartboostMediationSDK-Swift.h>
#import <XCTest/XCTest.h>

/// This is a compile time test, not a runtime test.
/// The tests pass as long as everything compiles without errors.
@interface APIStabilityTests_ObjectiveC : XCTestCase
@end

@interface APIStabilityTests_ObjectiveC (HeliumSdkDelegate) <HeliumSdkDelegate>
@end

@interface APIStabilityTests_ObjectiveC (CHBHeliumBannerAdDelegate) <CHBHeliumBannerAdDelegate>
@end

@interface APIStabilityTests_ObjectiveC (CHBHeliumInterstitialAdDelegate) <CHBHeliumInterstitialAdDelegate>
@end

@interface APIStabilityTests_ObjectiveC (CHBHeliumRewardedAdDelegate) <CHBHeliumRewardedAdDelegate>
@end

@implementation APIStabilityTests_ObjectiveC

/// API stability test for `Helium`.
- (void)stability_Helium {
    Helium *helium = Helium.sharedHelium;
    id result; // for suppressing the "unused result" warning

    [helium startWithAppId:@"" options:nil delegate:nil];
    [helium startWithAppId:@"" options:[[HeliumInitializationOptions alloc] initWithSkippedPartnerIdentifiers:nil] delegate:self];

    [helium startWithAppId:@"" andAppSignature:@"" options:nil delegate:nil];
    [helium startWithAppId:@"" andAppSignature:@"" options:[[HeliumInitializationOptions alloc] initWithSkippedPartnerIdentifiers:nil] delegate:self];

    result = [helium interstitialAdProviderWithDelegate:nil andPlacementName:@""];
    result = [helium interstitialAdProviderWithDelegate:self andPlacementName:@""];

    result = [helium rewardedAdProviderWithDelegate:nil andPlacementName:@""];
    result = [helium rewardedAdProviderWithDelegate:self andPlacementName:@""];

    result = [helium bannerProviderWithDelegate:nil andPlacementName:@"" andSize:CHBHBannerSize_Standard];
    result = [helium bannerProviderWithDelegate:self andPlacementName:@"" andSize:CHBHBannerSize_Standard];

    ChartboostMediationAdLoadRequest *request = [[ChartboostMediationAdLoadRequest alloc] initWithPlacement:@"" keywords:@{}];
    [helium loadFullscreenAdWithRequest:request completion:^(ChartboostMediationFullscreenAdLoadResult * _Nonnull result) { }];

    [helium setSubjectToGDPR:NO];
    [helium setSubjectToCoppa:NO];
    [helium setUserHasGivenConsent:NO];
    [helium setCCPAConsent:NO];

    result = helium.userIdentifier;
    helium.userIdentifier = nil;

    [helium setGameEngineName:nil version:nil];

    result = [Helium sdkVersion];

    result = [helium initializedAdapterInfo];

    NSDictionary<NSString *, NSNumber *> *partnerConsents = helium.partnerConsents;
    helium.partnerConsents = partnerConsents;
}

/// API stability test for notifications.
- (void)stability_notifications {
    [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.heliumDidReceiveILRD
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // Extract the ILRD payload.
        HeliumImpressionData *ilrd = notification.object;
        NSString *placement = ilrd.placement;
        NSDictionary *json = ilrd.jsonData;
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:kHeliumDidReceiveILRDNotification // deprecated
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // no op
    }];

    [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.heliumDidReceiveInitResults
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // Extract the results payload.
        NSDictionary *dictionary = notification.object;
    }];
    [NSNotificationCenter.defaultCenter addObserverForName:kHeliumDidReceiveInitResultsNotification // deprecated
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // no op
    }];
}

@end

#pragma mark - Mock Implementation

@implementation APIStabilityTests_ObjectiveC (HeliumSdkDelegate)

- (void)heliumDidStartWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

@end

@implementation APIStabilityTests_ObjectiveC (CHBHeliumBannerAdDelegate)

- (void)heliumBannerAdWithPlacementName:(NSString * _Nonnull)placementName requestIdentifier:(NSString * _Nonnull)requestIdentifier winningBidInfo:(NSDictionary<NSString *,id> * _Nullable)winningBidInfo didLoadWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

@end

@implementation APIStabilityTests_ObjectiveC (CHBHeliumInterstitialAdDelegate)

- (void)heliumInterstitialAdWithPlacementName:(NSString * _Nonnull)placementName didCloseWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

- (void)heliumInterstitialAdWithPlacementName:(NSString * _Nonnull)placementName didShowWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

- (void)heliumInterstitialAdWithPlacementName:(NSString * _Nonnull)placementName requestIdentifier:(NSString * _Nonnull)requestIdentifier winningBidInfo:(NSDictionary<NSString *,id> * _Nullable)winningBidInfo didLoadWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

@end

@implementation APIStabilityTests_ObjectiveC (CHBHeliumRewardedAdDelegate)

- (void)heliumRewardedAdDidGetRewardWithPlacementName:(NSString * _Nonnull)placementName {
    // no op
}

- (void)heliumRewardedAdWithPlacementName:(NSString * _Nonnull)placementName didCloseWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

- (void)heliumRewardedAdWithPlacementName:(NSString * _Nonnull)placementName didShowWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

- (void)heliumRewardedAdWithPlacementName:(NSString * _Nonnull)placementName requestIdentifier:(NSString * _Nonnull)requestIdentifier winningBidInfo:(NSDictionary<NSString *,id> * _Nullable)winningBidInfo didLoadWithError:(ChartboostMediationError * _Nullable)error {
    // no op
}

@end
