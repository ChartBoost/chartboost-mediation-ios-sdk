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

/// API stability test for the Chartboost Mediation SDK.
- (void)stability_Mediation {
    Helium *mediation = Helium.sharedHelium;
    id result; // for suppressing the "unused result" warning

    [mediation startWithAppId:@"" options:nil delegate:nil];
    [mediation startWithAppId:@"" options:[[HeliumInitializationOptions alloc] initWithSkippedPartnerIdentifiers:nil] delegate:self];

    [mediation startWithAppId:@"" andAppSignature:@"" options:nil delegate:nil];
    [mediation startWithAppId:@"" andAppSignature:@"" options:[[HeliumInitializationOptions alloc] initWithSkippedPartnerIdentifiers:nil] delegate:self];

    result = [mediation interstitialAdProviderWithDelegate:nil andPlacementName:@""];
    result = [mediation interstitialAdProviderWithDelegate:self andPlacementName:@""];

    result = [mediation rewardedAdProviderWithDelegate:nil andPlacementName:@""];
    result = [mediation rewardedAdProviderWithDelegate:self andPlacementName:@""];

    result = [mediation bannerProviderWithDelegate:nil andPlacementName:@"" andSize:CHBHBannerSize_Standard];
    result = [mediation bannerProviderWithDelegate:self andPlacementName:@"" andSize:CHBHBannerSize_Standard];

    ChartboostMediationAdLoadRequest *request = [[ChartboostMediationAdLoadRequest alloc] initWithPlacement:@"" keywords:@{}];
    [mediation loadFullscreenAdWithRequest:request completion:^(ChartboostMediationFullscreenAdLoadResult * _Nonnull result) { }];

    [mediation setSubjectToGDPR:NO];
    [mediation setSubjectToCoppa:NO];
    [mediation setUserHasGivenConsent:NO];
    [mediation setCCPAConsent:NO];

    result = mediation.userIdentifier;
    mediation.userIdentifier = nil;

    [mediation setGameEngineName:nil version:nil];

    result = [Helium sdkVersion];

    result = [mediation initializedAdapterInfo];

    NSDictionary<NSString *, NSNumber *> *partnerConsents = mediation.partnerConsents;
    mediation.partnerConsents = partnerConsents;

    BOOL boolResult = Helium.isTestModeEnabled; // Implicit conversion of 'BOOL' (aka '_Bool') to 'id' is disallowed with ARC
    Helium.isTestModeEnabled = false;
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
