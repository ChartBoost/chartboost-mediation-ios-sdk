iOS Change Log
==================
Check for the latest Chartboost Mediation SDK at the Chartboost website.

### Version 4.6.0 *(2023-10-12)*
----------------------------
Improvements:
- Added support for Adaptive Banners.
- Added privacy manifest.
- Added option to discard oversized ads.

Bug Fixes:
- Fixed an issue where winner prices could sometimes have rounding errors.

### Version 4.5.0 *(2023-08-31)*
----------------------------
Improvements:
- TCFv2 String is now read from `UserDefaults` and passed in the auction request. Publishers do not need to take any additional steps.
- Added support for DocC.
- No longer performing console logging on iOS 11.

We are aware of the iOS 17 changes impacting UserDefaults and are in communication with the IAB to remove TCF2.2 dependency on UserDefaults.

### Version 4.4.0 *(2023-07-27)*
----------------------------
Improvements:
- Added support for setting the console output level of SDK logs.
- Added support for custom logging handlers.

### Version 4.3.0 *(2023-06-22)*
----------------------------
Improvements:
- Added support for Rewarded Interstitials. This is available via `Helium.shared().loadFullscreenAd()` and supported only in the latest adapters. Please check each adapter's changelog to see which partners support rewarded interstitials.
- Added new ChartboostMediationFullscreenAd APIs which combine and improve the interstitial and rewarded ad APIs. Previous interstitial and rewarded ad APIs are now deprecated.
- Added `line_item_name` and `line_item_id` to `winningBidInfo`.
- Added extensive console logs for main SDK operations.

This version of the SDK is compatible with Xcode 14.1 and above, and iOS 11.0 and above.

### Version 4.2.0 *(2023-05-04)*
----------------------------
Improvements:
- Fixed punctuation in error descriptions.
- Added support for multiple instances of the same banner placement.

### Version 4.1.0 *(2023-03-23)*
----------------------------
Improvements:
- Added `Helium.initializedAdapterInfo` to get a list of initialized adapters.
- Added `partnerSDKVersion` and `partnerAdapterVersion` to the JSON for the `heliumDidReceiveInitResults` notification.
- Added CM_115 error code for Mediation initialization failure.

### Version 4.0.0 *(2023-02-23)*
----------------------------
As part of the Marketing team’s efforts to clearly articulate the use cases and customers we support by being more descriptive with our product branding, Helium is being rebranded as Chartboost Mediation.

Starting in 4.0.0, the Chartboost Mediation brand will be used in place of Helium for new additions. In the coming 4.X releases, the old Helium branding will be deprecated and the new Chartboost Mediation branding will be used to give publishers a smoother transition.

Improvements:
- Renamed framework module to `ChartboostMediationSDK`. Make sure to update the old `HeliumSdk` imports in your code.
- Revamped partner adapter APIs. Partner adapters are now open sourced and hosted on individual git repositories. Find the full partner list and more information on how to use the new adapters [here](https://developers.chartboost.com/docs/mediation-ios-get-started).
- Added `ChartboostMediationError` as a replacement for `HeliumError` to better identify the reason for failures and provide relevant context.
- Removed reward parameter from reward callback method `heliumRewardedAdDidGetRewardWithPlacementName:`.
- Removed the `heliumInterstitialAdWithPlacementName:didLoadWinningBidWithInfo:` callback method, moving the winning bid info to load callback methods.
- Added request identifier parameter to load callback methods.
- `load` method no longer returns the request identifier.
- `clearAd` and `clearLoaded` methods no longer return a value.

### Version 3.3.4 *(2023-03-16)*
----------------------------
Bug Fixes:
- Fixes a `EXC_BAD_ACCESS specialized _ArrayBuffer._getElementSlowPath(_:)` multithreading crash.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.12*
>- *AppLovin: ~> 11.5.0*
>- *Chartboost: 9.1*
>- *Facebook Audience Network: ~> 6.12*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.12*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.12*
>- *Yahoo: ~> 1.14*

### Version 3.3.3 *(2023-02-02)*
----------------------------
Bug Fixes:
- Fixes a bug where a fresh SDK configuration cannot be fetched if the cached configuration was corrupted.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.12*
>- *AppLovin: ~> 11.5.0*
>- *Chartboost: ~> 9.1*
>- *Facebook Audience Network: ~> 6.12*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.12*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.12*
>- *Yahoo: ~> 1.14*

### Version 3.3.2 *(2023-01-26)*
----------------------------
Improvements:
- The minimum version for Vungle has been updated to 6.12 to incorporate Vungle's bug fixes.

Bug Fixes:
- Support for Xcode 13.1 has been restored.
- Reverted Yahoo adapter to use `Verizon-Ads-StandardEdition` to support Xcode 13.1.
- Vungle adapter has been audited again and contains more safety checks.
- Pipe through Amazon Publisher Services banner and interstitial clicks.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.12*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 9.1*
>- *Facebook Audience Network: ~> 6.12*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.12*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.12*
>- *Yahoo: ~> 1.14*

### Version 3.3.1 *(2023-01-09)*
----------------------------
Bug Fixes:
- Fixes a bug in the Vungle adapter where the header bidding API versions of `addAdViewToView:withOptions:placementID:error:` and `playAd:options:placementID:error:` where not used.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.12*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 9.1*
>- *Facebook Audience Network: ~> 6.12*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.12*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.3*

### Version 3.3.0 *(2022-12-01)*
----------------------------
Improvements:
- Added ability to not initialize certain partners at Helium SDK initialization time. `start(withAppId:andAppSignature:options:delegate:)` now can take `HeliumInitializationOptions` with a `Set<String>` of partner identifiers to skip initialization.
- Added several more metrics around ad lifecycle and initialization. The new notification `com.chartboost.helium.notification.init` has been added and contains details on which partners initialized and how long it took.
- Google bidding adapter now uses the official Google bidding APIs in Google Mobile Ads SDK version 9.12.
- Chartboost adapter now uses version 9.1.0 as a minimum.
- Facebook Audience Network now uses version 6.12.0 as a minimum.
- Update the minimum required Xcode version to 14.1.
- Update the Yahoo adapter to use the new Yahoo SDK.

Bug Fixes:
- Fixed a bug in the Facebook Audience Network adapter where interstitial and rewarded `didClose:` events were not fired.
- Fixed a bug in the Facebook Audience Network adapter where the ATE setting was not being set.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.12*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 9.1*
>- *Facebook Audience Network: ~> 6.12*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.12*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.3*

### Version 3.2.0 *(2022-10-20)*
----------------------------
Improvements:
- New public API `Helium.sdkVersion` to retrieve the Helium version.

Bug Fixes:
- Internal improvements.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 3.1.0 *(2022-09-22)*
----------------------------
Improvements:
- Rate limiting added to all ad requests.
- Helium Demo app updated to be a pure SDK integration experience.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 3.0.0 *(2022-08-18)*
----------------------------
Improvements:
- Banner API updated from a load-show to a load-only paradigm. A summary of the changes is listed below:
    - `HeliumBannerView`
        - `loadAd` changed to `loadAdWithViewController:`.
        - `clearLoadedAd` renamed to `clearAd`.
        - `showAdWithViewController:` removed. Banners are now ready to show upon successful load.
        - `readyToShow` removed since it is no longer necessary.
    - `CHBHeliumBannerAdDelegate`
        - `heliumBannerAdWithPlacementName:didShowWithError:` removed since it is no longer necessary.
        - `heliumBannerAdWithPlacementName:didCloseWithError:` removed.
        - `heliumBannerAdWithPlacementName:didLoadWinningBidWithInfo:` will only be invoked when automatic refresh has been disabled for the banner placement.

- Helium impression events are now separate from partner network impression events.
- All ad formats now load their waterfalls in a sequential manner.

Bug Fixes:
- Banner automatic refresh ad loads are now tied to Helium impression events.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *Google bidding: ~> 9.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.2*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.11.0 *(2022-07-07)*
----------------------------
Improvements:
- Improved Keyword targeting support.

Bug Fixes:
- Stop sending JSON `null` values in ILRD, winning bid info, and rewarded callback payloads.
- Remove losing bids from the partner caches.
- Fixed banner refreshing when not included in a view hierarchy.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.0*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.10.1 *(2022-06-23)*
----------------------------
Bug Fixes:
- Remove losing bids from the partner caches, reducing the likelihood of an expired ad being used.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.0*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.10.0 *(2022-05-19)*
----------------------------
Improvements:
- Added `setGameEngineName:version:` to HeliumSdk to facilitate sending game engine information for Reserved Keywords Targeting.

Bug Fixes:
- Updated Mintegral to version 7.1 and fixed deprecation warnings.
- Updated AdColony to version 4.8 and fixed deprecation warnings.
- Podspec usage of `EXCLUDED_ARCHS` has been reviewed and updated where appropriate.
- Update AdMob adapter to disable mediation initialization.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.8*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.1*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.0*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.9.1 *(2022-06-23)*
----------------------------
Bug Fixes:
- Remove losing bids from the partner caches, reducing the likelihood of an expired ad being used.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.7*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.0*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.0*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.9.0 *(2022-04-21)*
----------------------------
Improvements:
- Added support for sending keywords in `HeliumInterstitialAd`, `HeliumRewardedAd`, and `HeliumBannerAd`.

Bug Fixes:
- CCPA/COPPA/GDPR privacy and consent settings are now set in real time.
- Fixed `NSNull` crash when encountering JSON `null` for a bid's `cpm_price` and `ad_revenue`.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.7*
>- *AdMob: ~> 9.1*
>- *AppLovin: ~> 11.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.9.0*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.0*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 4.0*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.8.0 *(2022-03-24)*
----------------------------
Improvements:
- Added Yahoo mediation support.
- Banner auto refresh no longer fires `didCache()`, `didReceiveWinningBid()`, and `didShow()`.
- Banner containers are now transparent.

Bug Fixes:
- Fixes for AdMob banner loading and showing.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.7*
>- *AdMob: ~> 8.0*
>- *AppLovin: ~> 10.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.4*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.0*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 3.7*
>- *Vungle: ~> 6.10*
>- *Yahoo: ~> 1.14*

### Version 2.7.1 *(2022-03-08)*
----------------------------
Note:
- No changes from 2.7.0. Version bumped to match Android and Unity platform versions.

### Version 2.7.0 *(2022-03-03)*
----------------------------
Improvements:
- Updated the Unity Ads adapter to enable per placement loading.

Bug Fixes:
- Not visible banners no longer autorefresh.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.7*
>- *AdMob: ~> 8.0*
>- *AppLovin: ~> 10.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.4*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.0*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 3.7*
>- *Vungle: ~> 6.10*

### Version 2.6.0 *(2022-02-15)*
----------------------------
Improvements:
- Impression Level Revenue Data support.
- Rewarded callback support.
- GDPR, COPPA, and CCPA integration with the UnityAds adapter.
- Reintroduced `partner-id` to the winning bid information.

Bug Fixes:
- Fixed UnityAds adapter issue where the Rewarded close event may arrive before the reward event.
- Updated the `ChartboostHeliumAdapterMintegral` podspec dependency to use `MintegralAdSDK`.
- Updated the `ChartboostHeliumAdapterFyber` podspec dependency to use `Fyber_Marketplace_SDK`.

This version of the Helium SDK includes support for the following Ad Networks:
>- *AdColony: ~> 4.7*
>- *AdMob: ~> 8.0*
>- *AppLovin: ~> 10.3*
>- *Chartboost: ~> 8.5*
>- *Facebook Audience Network: ~> 6.4*
>- *Fyber Marketplace: ~> 8.1*
>- *InMobi: ~> 10.0*
>- *ironSource: ~> 7.1*
>- *Mintegral: ~> 7.0*
>- *Tapjoy: ~> 12.8*
>- *Unity Ads: ~> 3.7*
>- *Vungle: ~> 6.10*

### Version 2.5.1 *(2022-02-03)*
----------------------------
Bug Fixes:
- Updated GDPR and CCPA handling for all networks.

### Version 2.5.0 *(2022-01-14)*
----------------------------
Improvements:
- Banner Support*
- Mintegral Header Bidding support.
- Added Fyber, InMobi, & Mintegral mediated support.
- Updated Partner SDK Dependencies.
- Various improvements and fixes.

>*Banner Support is currently supported for the following Ad Networks:
>- Chartboost
>- Facebook Audience Network
>- AdColony
>- AdMob
>- Vungle
>- AppLovin
>- Unity Ads
>- Fyber
>- InMobi
>- Mintegral

This version of the Helium SDK includes support for the following Ad Networks:
>- *Chartboost: 8.5.0*
>- *Tapjoy: 12.8.1*
>- *Facebook Audience Network: 6.9.0*
>- *AdColony: 4.7.2*
>- *AdMob: 8.13.0*
>- *Vungle: 6.10.5*
>- *AppLovin: 10.3.7*
>- *Unity Ads: 3.7.5*
>- *ironSource: 7.1.13.0*
>- *Fyber Marketplace: 8.1.1*
>- *InMobi: 10.0.1*
>- *Mintegral: 7.0.6.0*

### Version 2.3.2 *(2021-12-08)*
----------------------------
Improvements:
- AdMob v8 Support.
- Updated Partner SDK Dependencies.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.5.0*
>- *Tapjoy: 12.8.1*
>- *Facebook Audience Network: 6.9.0*
>- *AdColony: 4.7.2*
>- *AdMob: 8.13.0*
>- *Vungle: 6.10.4*
>- *AppLovin: 10.3.7*
>- *Unity Ads: 3.7.5*
>- *ironSource: 7.1.12.1*

### Version 2.3.1 *(6-24-2021)*
----------------------------
Improvements:
- Vungle Header Bidding Support.
- Updated Partner SDK Dependencies.
- Helium Adapters will now follow a `d.d.d.d` version format.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.4.2*
>- *Tapjoy: 12.8.1*
>- *Facebook Audience Network: 6.5.0*
>- *AdColony: 4.6.1*
>- *AdMob: 7.69.0*
>- *Vungle: 6.9.2*
>- *AppLovin: 10.3.1*
>- *Unity Ads: 3.7.2*
>- *ironSource: 7.1.6.1*

### Version 2.3.0 *(2-18-2021)*
----------------------------
Improvements:
- Vungle Header Bidding Support.
- Various Fixes.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.4.0*
>- *Tapjoy: 12.7.1*
>- *Facebook Audience Network: 6.2.1*
>- *AdColony: 4.5.0*
>- *AdMob: 7.69.0*
>- *Vungle: 6.9.1*
>- *AppLovin: 6.15.1*
>- *Unity Ads: 3.6.0*
>- *ironSource: 7.1.0.0*

### Version 2.2.1 *(12-18-2020)*
----------------------------
Improvements:
- Chartboost SDK 8.4.0 Support.
- Various Fixes.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.4.0*
>- *Tapjoy: 12.7.1*
>- *Facebook Audience Network: 6.2.0*
>- *AdColony: 4.4.1.1*
>- *AdMob: 7.69.0*
>- *Vungle: 6.8.1*
>- *AppLovin: 6.14.9*
>- *Unity Ads: 3.6.0*
>- *ironSource: 7.0.4.0*

### Version 2.2.0 *(11-20-2020)*
--------------------------------
Improvements:
- New clearLoadedAd API method.
- Various improvements and fixes.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.3.1*
>- *Tapjoy: 12.7.1*
>- *Facebook Audience Network: 6.2.0*
>- *AdColony: 4.4.1*
>- *AdMob: 7.67.0*
>- *Vungle: 6.8.1*
>- *AppLovin: 6.14.6*
>- *Unity Ads: 3.5.0*
>- *ironSource: 7.0.3.0*

### Version 2.1.0 *(2020-10-02)*
--------------------------------
Improvements:
- Added support for non-programmatic ads from IronSource.
- Added support for non-programmatic ads from Unity Ads.
- Built and Tested with iOS 14.

>- *Chartboost: iOS 8.3.1+*
>- *AdColony 4.3.1+*
>- *AdMob 7.65.0+*
>- *AppLovin 6.14.2+*
>- *Facebook Audience Network: 5.10.1+*
>- *ironSource: 7.0.1+*
>- *Tapjoy 12.6.1+*
>- *Unity Ads: 3.4.8+*
>- *Vungle: 6.7.1+*

### Version 2.0.1 *(2020-08-31)*
--------------------------------
Bug Fixes:
- Fixed a crash bug.

>- *Chartboost: 8.2.0+*
>- *Facebook Audience Network: 5.3+*
>- *Tapjoy: 12.2.0+*
>- *AdColony: 3.3.8+*


### Version 2.0.0 *(2020-05-29)*
--------------------------------
Improvements:
- Added support for non-programmatic ads from AdMob.
- Added support for non-programmatic ads from AppLovin.
- Added support for non-programmatic ads from Vungle.

>- *Chartboost: iOS 8.1.0+*
>- *Facebook Audience Network: 5.3+*
>- *Tapjoy: 12.2.0+*
>- *AdColony: 3.3.8+*

### Version 1.9.0 *(2020-02-27)*
--------------------------------
Improvements:
- Helium supports programmatic and non-programmatic ads from existing netowork partners.

Bug Fixes:
- 
>- *Chartboost: 8.0.1+*
>- *Facebook Audience Network: 5.3+*
>- *Tapjoy: 12.2.0+*
>- *AdColony: 3.3.8+*

### Version 1.8.0 *(2020-01-01)*
--------------------------------
Improvements:
- Helium now handles more than one bid to mitigate winning bid load failure.
- 3rd party adapters are now in separate framework modules.

Bug Fixes:
- 

>- *Chartboost: iOS 8.0.1+*
>- *Facebook Audience Network: 5.3+*
>- *Tapjoy: 12.2.0+*
>- *AdColony: 3.3.8+*

### Version 1.1.0 *(2019-10-15)*
--------------------------------
Improvements:
- Added support for AdColony.
- Added Test Mode to aid in integration.

Bug Fixes:
- Calling loadAd on an Ad Object that has already been loaded will no longer send an addition didLoadWithError: callback.
- Calling loadAd before Helium has successfully started will now throw a 'Helium Not Started' error rather than a 'Server Error'.

>- *Chartboost: 8.0.1+*
>- *Facebook Audience Network: 5.3+*
>- *Tapjoy: 12.2.0+*
>- *AdColony: 3.3.8+*


### Version 1.0.0 *(2019-8-15)*
--------------------------------
Improvements:
- Support for Chartboost.
- Support for Tapjoy.
- Support for Facebook Audience Network.
- Support for Interstitial Ads.
- Support for Rewarded Ads.
- Winning bid information.

This Helium SDK version supports the following Ad Networks:
>- *Chartboost: 8.0.1+*
>- *Tapjoy: 12.2.0+*
>- *Facebook Audience Network: 5.3+*
