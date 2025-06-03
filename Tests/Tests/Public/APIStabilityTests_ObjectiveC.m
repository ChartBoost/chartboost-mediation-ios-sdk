// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// Public headers in ChartboostMediationSDK-Swift.h

#import <ChartboostMediationSDK/ChartboostMediationSDK-Swift.h>
#import <XCTest/XCTest.h>

// In this file, we intentionally create a lot of unused variables.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"

/// This is a compile time test, not a runtime test.
/// The tests pass as long as everything compiles without errors.
@interface APIStabilityTests_ObjectiveC : XCTestCase
@end

@implementation APIStabilityTests_ObjectiveC

- (void)stability {}

@end

// FullscreenAdLoadRequest
@interface CBMFullscreenAdLoadRequestValidator: NSObject
@end

@implementation CBMFullscreenAdLoadRequestValidator

-(instancetype)init {
    CBMFullscreenAdLoadRequest *request = [[CBMFullscreenAdLoadRequest alloc] initWithPlacement:@"" keywords:@{@"": @""} partnerSettings:@{@"": @""}];
    CBMFullscreenAdLoadRequest *request2 = [[CBMFullscreenAdLoadRequest alloc] initWithPlacement:@"" keywords:@{@"": @""}];
    NSString *placement = request.placement;
    NSDictionary<NSString *, NSString *> *keywords = request.keywords;
    NSDictionary<NSString *, id> *partnerSettings = request.partnerSettings;
    return self;
}
@end

// AdLoadResult
@interface CBMAdLoadResultValidator: NSObject
@end

@implementation CBMAdLoadResultValidator

-(instancetype)init {
    CBMAdLoadResult *result;
    CBMError *error = result.error;
    NSString *loadID = result.loadID;
    NSDictionary<NSString *, id> *metrics = result.metrics;
    return self;
}
@end

// AdShowResult
@interface CBMAdShowResultValidator: NSObject
@end

@implementation CBMAdShowResultValidator

-(instancetype)init {
    CBMAdShowResult *result;
    CBMError *error = result.error;
    NSDictionary<NSString *, id> *metrics = result.metrics;
    return self;
}
@end

// BannerAdLoadRequest
@interface CBMBannerAdLoadRequestValidator : NSObject
@end

@implementation CBMBannerAdLoadRequestValidator

-(instancetype)init {
    CBMBannerAdLoadRequest *request = [[CBMBannerAdLoadRequest alloc] initWithPlacement:@"test" size:[CBMBannerSize standard]];
    NSString *placement = request.placement;
    CBMBannerSize *size = request.size;
    return self;
}

@end

// BannerAdLoadResult
@interface CBMBannerAdLoadResultValidator : NSObject
@end

@implementation CBMBannerAdLoadResultValidator

-(instancetype)init {
    // Only way to get a result object is via the load.
    CBMBannerAdView *view = [[CBMBannerAdView alloc] init];
    CBMBannerAdLoadRequest *request = [[CBMBannerAdLoadRequest alloc] initWithPlacement:@"test" size:[CBMBannerSize standard]];
    [view loadWith:request viewController:[[UIViewController alloc] init] completion:^(CBMBannerAdLoadResult *result) {
        NSError *error = result.error;
        NSString *loadID = result.loadID;
        NSDictionary *metrics = result.metrics;
    }];

    return self;
}

@end

// BannerAdView
@interface CBMBannerAdViewValidator : NSObject <CBMBannerAdViewDelegate>
@end

@implementation CBMBannerAdViewValidator

-(instancetype)init {
    CBMBannerAdView *view = [[CBMBannerAdView alloc] init];

    view.delegate = self;

    NSDictionary *keywords = view.keywords;
    view.keywords = [[NSDictionary alloc] init];

    CBMBannerHorizontalAlignment horizontalAlignment = view.horizontalAlignment;
    view.horizontalAlignment = CBMBannerHorizontalAlignmentLeft;

    CBMBannerVerticalAlignment verticalAlignment = view.verticalAlignment;
    view.verticalAlignment = CBMBannerVerticalAlignmentTop;

    CBMBannerAdLoadRequest *request = view.request;
    NSDictionary *loadMetrics = view.loadMetrics;
    CBMBannerSize *size = view.size;
    NSDictionary *winningBidInfo = view.winningBidInfo;

    [view loadWith:request viewController:[[UIViewController alloc] init] completion:^(CBMBannerAdLoadResult *result) {

    }];
    [view reset];

    return self;
}

@end

// BannerHorizontalAlignment
@interface CMBBannerHorizontalAlignmentValidator : NSObject
@end

@implementation CMBBannerHorizontalAlignmentValidator

-(instancetype) init {
    CBMBannerHorizontalAlignment horizontalAlignment;
    horizontalAlignment = CBMBannerHorizontalAlignmentLeft;
    horizontalAlignment = CBMBannerHorizontalAlignmentCenter;
    horizontalAlignment = CBMBannerHorizontalAlignmentRight;
    return self;
}

@end

// BannerSize
@interface CBMBannerSizeValidator : NSObject
@end

@implementation CBMBannerSizeValidator

-(instancetype)init {
    CBMBannerSize *size;
    size = [CBMBannerSize standard];
    size = [CBMBannerSize medium];
    size = [CBMBannerSize leaderboard];
    size = [CBMBannerSize adaptiveWithWidth:100.0];
    size = [CBMBannerSize adaptiveWithWidth:100.0 maxHeight:100.0];
    size = [CBMBannerSize adaptive2x1WithWidth:100.0];
    size = [CBMBannerSize adaptive4x1WithWidth:100.0];
    size = [CBMBannerSize adaptive6x1WithWidth:100.0];
    size = [CBMBannerSize adaptive8x1WithWidth:100.0];
    size = [CBMBannerSize adaptive10x1WithWidth:100.0];
    size = [CBMBannerSize adaptive1x2WithWidth:100.0];
    size = [CBMBannerSize adaptive1x3WithWidth:100.0];
    size = [CBMBannerSize adaptive1x4WithWidth:100.0];
    size = [CBMBannerSize adaptive9x16WithWidth:100.0];
    size = [CBMBannerSize adaptive1x1WithWidth:100.0];

    CBMBannerType type = size.type;
    CGSize cgSize = size.size;
    CGFloat aspectRatio = size.aspectRatio;

    return self;
}

@end

// BannerType
@interface CBMBannerTypeValidator : NSObject
@end

@implementation CBMBannerTypeValidator

-(instancetype)init {
    CBMBannerType bannerType;
    bannerType = CBMBannerTypeFixed;
    bannerType = CBMBannerTypeAdaptive;
    return self;
}

@end

// BannerVerticalAlignment
@interface CBMBannerVerticalAlignmentValidator : NSObject

@end

@implementation CBMBannerVerticalAlignmentValidator

-(instancetype)init {
    CBMBannerVerticalAlignment verticalAlignment;
    verticalAlignment = CBMBannerVerticalAlignmentTop;
    verticalAlignment = CBMBannerVerticalAlignmentCenter;
    verticalAlignment = CBMBannerVerticalAlignmentBottom;
    return self;
}

@end

// ChartboostMediation
@interface ChartboostMediationValidator : NSObject

@end

@implementation ChartboostMediationValidator

-(instancetype)init {
    [ChartboostMediation setPreinitializationConfiguration:nil]; // ignore return value
    CBMError *error = [ChartboostMediation setPreinitializationConfiguration:
                       [[CBMPreinitializationConfiguration alloc] initWithSkippedPartnerIDs:@[@""]]];

    id result = [ChartboostMediation sdkVersion];
    result = [ChartboostMediation initializedAdapterInfo];
    BOOL boolResult = ChartboostMediation.discardOversizedAds;
    boolResult = ChartboostMediation.isTestModeEnabled;
    ChartboostMediation.isTestModeEnabled = false;
    return self;
}

@end

// CBMError
@interface CBMErrorValidator : NSObject

@end

@implementation CBMErrorValidator

-(instancetype)init {
    CBMError *error;
    NSString *str;
    str = error.localizedDescription;
    return self;
}

@end

// CBMErrorCode
@interface CBMErrorCodeValidator: NSObject
@end

@implementation CBMErrorCodeValidator

-(id)init {
    CBMErrorCode code;

    code = CBMErrorCodeInitializationFailureUnknown; // 100
    code = CBMErrorCodeInitializationFailureAborted; // 101
    code = CBMErrorCodeInitializationFailureAdBlockerDetected; // 102
    code = CBMErrorCodeInitializationFailureAdapterNotFound; // 103
    code = CBMErrorCodeInitializationFailureInvalidAppConfig; // 104
    code = CBMErrorCodeInitializationFailureInvalidCredentials; // 105
    code = CBMErrorCodeInitializationFailureNoConnectivity; // 106
    code = CBMErrorCodeInitializationFailurePartnerNotIntegrated; // 107
    code = CBMErrorCodeInitializationFailureTimeout; // 108
    code = CBMErrorCodeInitializationSkipped; // 109
    code = CBMErrorCodeInitializationFailureException; // 110
    code = CBMErrorCodeInitializationFailureViewControllerNotFound; // 111
    code = CBMErrorCodeInitializationFailureNetworkingError; // 112
    code = CBMErrorCodeInitializationFailureOSVersionNotSupported; // 113
    code = CBMErrorCodeInitializationFailureServerError; // 114
    code = CBMErrorCodeInitializationFailureInternalError; // 115
    code = CBMErrorCodeInitializationFailureInitializationInProgress; // 116
    code = CBMErrorCodeInitializationFailureInitializationDisabled; // 117

    code = CBMErrorCodePrebidFailureUnknown; // 200
    code = CBMErrorCodePrebidFailureAdapterNotFound; // 201
    code = CBMErrorCodePrebidFailureInvalidArgument; // 202
    code = CBMErrorCodePrebidFailureNotInitialized; // 203
    code = CBMErrorCodePrebidFailurePartnerNotIntegrated; // 204
    code = CBMErrorCodePrebidFailureTimeout; // 205
    code = CBMErrorCodePrebidFailureException; // 206
    code = CBMErrorCodePrebidFailureOSVersionNotSupported; // 207
    code = CBMErrorCodePrebidFailureNetworkingError; // 208

    code = CBMErrorCodeLoadFailureUnknown; // 300
    code = CBMErrorCodeLoadFailureAborted; // 301
    code = CBMErrorCodeLoadFailureAdBlockerDetected; // 302
    code = CBMErrorCodeLoadFailureAdapterNotFound; // 303
    code = CBMErrorCodeLoadFailureAuctionNoBid; // 304
    code = CBMErrorCodeLoadFailureAuctionTimeout; // 305
    code = CBMErrorCodeLoadFailureInvalidAdMarkup; // 306
    code = CBMErrorCodeLoadFailureInvalidAdRequest; // 307
    code = CBMErrorCodeLoadFailureInvalidBidResponse; // 308
    code = CBMErrorCodeLoadFailureInvalidChartboostMediationPlacement; // 309
    code = CBMErrorCodeLoadFailureInvalidPartnerPlacement; // 310
    code = CBMErrorCodeLoadFailureMismatchedAdFormat; // 311
    code = CBMErrorCodeLoadFailureNoConnectivity; // 312
    code = CBMErrorCodeLoadFailureNoFill; // 313
    code = CBMErrorCodeLoadFailurePartnerNotInitialized; // 314
    code = CBMErrorCodeLoadFailureOutOfStorage; // 315
    code = CBMErrorCodeLoadFailurePartnerNotIntegrated; // 316
    code = CBMErrorCodeLoadFailureRateLimited; // 317
    code = CBMErrorCodeLoadFailureShowInProgress; // 318
    code = CBMErrorCodeLoadFailureTimeout; // 319
    code = CBMErrorCodeLoadFailureUnsupportedAdFormat; // 320
    code = CBMErrorCodeLoadFailurePrivacyOptIn; // 321
    code = CBMErrorCodeLoadFailurePrivacyOptOut; // 322
    code = CBMErrorCodeLoadFailurePartnerInstanceNotFound; // 323
    code = CBMErrorCodeLoadFailureMismatchedAdParams; // 324
    code = CBMErrorCodeLoadFailureInvalidBannerSize; // 325
    code = CBMErrorCodeLoadFailureException; // 326
    code = CBMErrorCodeLoadFailureLoadInProgress; // 327
    code = CBMErrorCodeLoadFailureViewControllerNotFound; // 328
    code = CBMErrorCodeLoadFailureNoBannerView; // 329
    code = CBMErrorCodeLoadFailureNetworkingError; // 330
    code = CBMErrorCodeLoadFailureChartboostMediationNotInitialized; // 331
    code = CBMErrorCodeLoadFailureOSVersionNotSupported; // 332
    code = CBMErrorCodeLoadFailureServerError; // 333
    code = CBMErrorCodeLoadFailureInvalidCredentials; // 334
    code = CBMErrorCodeLoadFailureWaterfallExhaustedNoFill; // 335
    code = CBMErrorCodeLoadFailureAdTooLarge; // 336

    code = CBMErrorCodeShowFailureUnknown; // 400
    code = CBMErrorCodeShowFailureViewControllerNotFound; //401
    code = CBMErrorCodeShowFailureAdBlockerDetected; // 402
    code = CBMErrorCodeShowFailureAdNotFound; // 403
    code = CBMErrorCodeShowFailureAdExpired; // 404
    code = CBMErrorCodeShowFailureAdNotReady; // 405
    code = CBMErrorCodeShowFailureAdapterNotFound; // 406
    code = CBMErrorCodeShowFailureInvalidChartboostMediationPlacement; // 407
    code = CBMErrorCodeShowFailureInvalidPartnerPlacement; // 408
    code = CBMErrorCodeShowFailureMediaBroken; // 409
    code = CBMErrorCodeShowFailureNoConnectivity; // 410
    code = CBMErrorCodeShowFailureNoFill; // 411
    code = CBMErrorCodeShowFailureNotInitialized; // 412
    code = CBMErrorCodeShowFailureNotIntegrated; // 413
    code = CBMErrorCodeShowFailureShowInProgress; // 414
    code = CBMErrorCodeShowFailureTimeout; // 415
    code = CBMErrorCodeShowFailureVideoPlayerError; // 416
    code = CBMErrorCodeShowFailurePrivacyOptIn; // 417
    code = CBMErrorCodeShowFailurePrivacyOptOut; // 418
    code = CBMErrorCodeShowFailureWrongResourceType; // 419
    code = CBMErrorCodeShowFailureUnsupportedAdType; // 420
    code = CBMErrorCodeShowFailureException; // 421
    code = CBMErrorCodeShowFailureUnsupportedAdSize; // 422
    code = CBMErrorCodeShowFailureInvalidBannerSize; // 423

    code = CBMErrorCodeInvalidateFailureUnknown; // 500
    code = CBMErrorCodeInvalidateFailureAdNotFound; // 501
    code = CBMErrorCodeInvalidateFailureAdapterNotFound; // 502
    code = CBMErrorCodeInvalidateFailureNotInitialized; // 503
    code = CBMErrorCodeInvalidateFailurePartnerNotIntegrated; // 504
    code = CBMErrorCodeInvalidateFailureTimeout; // 505
    code = CBMErrorCodeInvalidateFailureWrongResourceType; // 506
    code = CBMErrorCodeInvalidateFailureException; // 507

    code = CBMErrorCodeUnknown; // 600
    code = CBMErrorCodePartnerError; // 601
    code = CBMErrorCodeInternal; // 602
    code = CBMErrorCodeNoConnectivity; // 603
    code = CBMErrorCodeAdServerError; // 604
    code = CBMErrorCodeInvalidArguments; // 605
    code = CBMErrorCodePreinitializationActionFailed; // 606

    return self;
}

@end

// FullscreenAd
@interface CBMFullscreenAdValidator: NSObject
@end

@implementation CBMFullscreenAdValidator

-(instancetype)init {
    CBMFullscreenAd *ad;
    ad.delegate = nil;
    id<CBMFullscreenAdDelegate> delegate = ad.delegate;
    ad.customData = nil;
    NSString *data = ad.customData;
    data = ad.loadID;
    CBMFullscreenAdLoadRequest *request = ad.request;
    NSDictionary<NSString *, NSString *> *info = ad.winningBidInfo;
    [ad showWith:[[UIViewController alloc] init] completion:^(CBMAdShowResult * _Nonnull result) {
        id object = result;
    }];
    [ad invalidate];
    [CBMFullscreenAd loadWith:request completion:^(CBMFullscreenAdLoadResult * _Nonnull result) { }];
    return self;
}

@end

// FullscreenAdLoadResult
@interface CBMFullscreenAdLoadResultValidator: NSObject
@end

@implementation CBMFullscreenAdLoadResultValidator

-(instancetype)init {
    CBMFullscreenAdLoadResult *result;
    CBMFullscreenAd *ad = result.ad;
    CBMError *error = result.error;
    NSString *loadID = result.loadID;
    NSDictionary<NSString *, id> *metrics = result.metrics;
    return self;
}
@end

// FullscreenAdQueue
@interface CBMFullscreenAdQueueValidator: NSObject
@end

@implementation CBMFullscreenAdQueueValidator

-(id)init {
    CBMFullscreenAdQueue *queue = [CBMFullscreenAdQueue queueForPlacement:@"_"];
    id delegate = queue.delegate;
    NSString *placement = queue.placement;
    BOOL next = queue.hasNextAd;
    BOOL running = queue.isRunning;
    NSDictionary<NSString*, NSString*> *keywords = queue.keywords;
    NSInteger ready = queue.numberOfAdsReady;
    NSInteger capacity = queue.queueCapacity;
    CBMFullscreenAd *ad = [queue getNextAd];
    [queue setQueueCapacity:2];
    [queue start];
    [queue stop];
    return self;
}

@end

// ImpressionData
@interface CBMImpressionDataValidator: NSObject
@end

@implementation CBMImpressionDataValidator

-(id)init {
    CBMImpressionData *data; // no public initializer
    NSString *placement;
    placement = data.placement;
    NSDictionary<NSString*, id> *jsonData;
    jsonData = data.jsonData;

    return self;
}

@end

// Notifications
@interface CBMNotificationsValidator : NSObject

@end

@implementation CBMNotificationsValidator

-(instancetype)init {
    [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.chartboostMediationDidReceiveILRD
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // Extract the ILRD payload.
        CBMImpressionData *ilrd = notification.object;
        NSString *placement __unused = ilrd.placement;
        NSDictionary *json __unused = ilrd.jsonData;
    }];

    [NSNotificationCenter.defaultCenter addObserverForName:NSNotification.chartboostMediationDidReceivePartnerAdapterInitResults
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull notification) {
        // Extract the results payload.
        NSDictionary *dictionary __unused = notification.object;
    }];
    return self;
}

@end

// PartnerAd not available in Objective-C.

// PartnerAdapter not available in Objective-C.

// PartnerAdapterInfo
@interface CBMPartnerAdapterInfoValidator : NSObject

@end

@implementation CBMPartnerAdapterInfoValidator

-(instancetype)init {
    CBMPartnerAdapterInfo *info;
    NSString *adapterVersion = info.adapterVersion;
    NSString *partnerVersion = info.partnerVersion;
    NSString *partnerName = info.partnerDisplayName;
    NSString *partnerId = info.partnerID;
    return self;
}

@end

// PartnerAdFormat not available in Objective-C.

// PartnerAdLoadRequest not available in Objective-C.

// PartnerAdLogEvent not available in Objective-C.

// PartnerConfiguration not available in Objective-C.

// PartnerLogEvent not available in Objective-C.

// PartnerAdPreBidRequest not available in Objective-C.

// PartnerBannerSize not available in Objective-C.

// PartnerErrorFactory not available in Objective-C.

// PartnerErrorMapping not available in Objective-C.

// PreinitializationConfiguration
@interface CBMPreinitializationConfigurationValidator: NSObject
@end

@implementation CBMPreinitializationConfigurationValidator

-(id)init {
    CBMPreinitializationConfiguration *config
        = [[CBMPreinitializationConfiguration alloc] initWithSkippedPartnerIDs:@[@"pid1", @"pid2"]];
    NSSet<NSString*> *skippedPartnerIDs;
    skippedPartnerIDs = config.skippedPartnerIDs;
    return self;
}

@end

#pragma mark - Protocols

// BannerAdViewDelegate
@interface CBMBannerAdViewDelegateValidator : NSObject<CBMBannerAdViewDelegate>

@end

@implementation CBMBannerAdViewDelegateValidator

- (void)didClickWithBannerView:(CBMBannerAdView * _Nonnull)bannerView {}
- (void)didRecordImpressionWithBannerView:(CBMBannerAdView * _Nonnull)bannerView {}
- (void)willAppearWithBannerView:(CBMBannerAdView * _Nonnull)bannerView {}

@end

@interface CBMBannerAdViewDelegateValidator2: NSObject <CBMFullscreenAdDelegate>
@end

@implementation CBMBannerAdViewDelegateValidator2
// No implementations to validate that all methods are optional
@end

// FullscreenAdDelegate
@interface CBMFullscreenAdDelegateValidator : NSObject<CBMFullscreenAdDelegate>

@end

@implementation CBMFullscreenAdDelegateValidator
- (void)didClickWithAd:(CBMFullscreenAd * _Nonnull)ad {}
- (void)didCloseWithAd:(CBMFullscreenAd * _Nonnull)ad error:(CBMError *)error {}
- (void)didExpireWithAd:(CBMFullscreenAd * _Nonnull)ad {}
- (void)didRecordImpressionWithAd:(CBMFullscreenAd * _Nonnull)ad {}
- (void)didRewardWithAd:(CBMFullscreenAd * _Nonnull)ad {}

@end

@interface CBMFullscreenAdDelegateValidator2: NSObject <CBMFullscreenAdDelegate>
@end

@implementation CBMFullscreenAdDelegateValidator2
// No implementations to validate that all methods are optional
@end

// FullscreenAdQueueDelegate
@interface CBMFullscreenAdQueueDelegateValidator : NSObject<CBMFullscreenAdQueueDelegate>

@end

@implementation CBMFullscreenAdQueueDelegateValidator

- (void)fullscreenAdQueue:(CBMFullscreenAdQueue * _Nonnull)adQueue didFinishLoadingWithResult:(CBMAdLoadResult *)result numberOfAdsReady:(NSInteger)numberOfAdsReady {}
- (void)fullscreenAdQueueDidRemoveExpiredAd:(CBMFullscreenAdQueue * _Nonnull)adQueue numberOfAdsReady:(NSInteger)numberOfAdsReady {}

@end

@interface CBMFullscreenAdQueueDelegateValidator2 : NSObject<CBMFullscreenAdQueueDelegate>

@end

@implementation CBMFullscreenAdQueueDelegateValidator2
// No implementations to validate that all methods are optional
@end

// PartnerAd not available in Objective-C.

// PartnerAdapter not available in Objective-C.

// PartnerAdapterConfiguration
@interface CBMPartnerAdapterConfigurationValidator : NSObject <CBMPartnerAdapterConfiguration>

@end

@implementation CBMPartnerAdapterConfigurationValidator

+ (NSString * _Nonnull)adapterVersion { return @""; }
+ (NSString * _Nonnull)partnerDisplayName { return @""; }
+ (NSString * _Nonnull)partnerID { return @""; }
+ (NSString * _Nonnull)partnerSDKVersion { return @""; }

@end

// PartnerAdapterStorage not available in Objective-C.

// PartnerAdDelegate not available in Objective-C.

// PartnerBannerAd not available in Objective-C.

// PartnerErrorFactory not available in Objective-C.

// PartnerErrorMapping not available in Objective-C.

// PartnerFullscreenAd not available in Objective-C.

#pragma clang diagnostic pop
