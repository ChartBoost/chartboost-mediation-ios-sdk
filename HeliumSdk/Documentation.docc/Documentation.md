# ``ChartboostMediationSDK``

For more information on the Chartboost Mediation SDK, see [Chartboost Developers](https://developers.chartboost.com/docs/mediation-ios-get-started).

## Topics

### Initializing the SDK

- ``Helium``
- ``HeliumSdkDelegate``
- ``HeliumInitializationOptions``
- ``HeliumAdapterInfo``
- ``PartnerIdentifier``

### Ad Request and Response

Objects used for request and response of both banner and fullscreen ads.

- ``HeliumKeywords``
- ``ChartboostMediationAdLoadRequest``
- ``ChartboostMediationAdLoadResult``

### Banner Ads

- ``ChartboostMediationBannerView``
- ``ChartboostMediationBannerViewDelegate``
- ``ChartboostMediationBannerSize``
- ``ChartboostMediationBannerType``
- ``ChartboostMediationBannerLoadRequest``
- ``ChartboostMediationBannerLoadResult``
- ``ChartboostMediationBannerHorizontalAlignment``
- ``ChartboostMediationBannerVerticalAlignment``

### Legacy Banner Ads

The legacy interfaces for banner ads. These will be removed in a future release.

- ``HeliumBannerAd``
- ``HeliumBannerAdDelegate``
- ``HeliumBannerView``
- ``CHBHBannerSize``

### Fullscreen Ads

- ``ChartboostMediationFullscreenAd``
- ``ChartboostMediationFullscreenAdDelegate``
- ``ChartboostMediationFullscreenAdLoadResult``
- ``ChartboostMediationAdShowResult``

### Interstial and Rewarded Ads

The legacy interfaces for interstitial and rewarded ads. These will be removed in a future release.

- ``HeliumInterstitialAd``
- ``CHBHeliumInterstitialAdDelegate``
- ``HeliumRewardedAd``
- ``CHBHeliumRewardedAdDelegate``

### Notifications

- ``HeliumImpressionData``

### Handling Errors

- ``ChartboostMediationError``
- ``HeliumError``
- ``HeliumErrorCode``

### Logging

- ``LogEntry``
- ``LogHandler``
- ``LogLevel``

### Creating Adapters

The following types are used when creating adapters, and should not be needed in most implementations.

- ``AdFormat``
- ``GDPRConsentStatus``
- ``IABLeaderboardAdSize``
- ``IABMediumAdSize``
- ``IABStandardAdSize``
- ``PartnerAdLoadRequest``
- ``PartnerAdLogEvent``
- ``PartnerAdapter``
- ``PartnerAdapterStorage``
- ``PartnerAd``
- ``PartnerAdDelegate``
- ``PartnerAdLogEvent``
- ``PartnerConfiguration``
- ``PartnerEventDetails``
- ``PartnerLogEvent``
- ``PreBidRequest``
