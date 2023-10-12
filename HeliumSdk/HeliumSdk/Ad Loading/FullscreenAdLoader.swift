// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Loads full screen ads using a request and returning a load result.
protocol FullscreenAdLoader {
    
    /// Loads a Chartboost Mediation fullscreen ad using the information provided in the request.
    func loadFullscreenAd(with request: ChartboostMediationAdLoadRequest, completion: @escaping (ChartboostMediationFullscreenAdLoadResult) -> Void)
}

/// Configuration settings for FullscreenAdLoader.
protocol FullscreenAdLoaderConfiguration {
    /// Returns the ad format associated to the given Chartboost Mediation placement.
    func adFormat(forPlacement placement: String) -> AdFormat?
}

final class AdLoader: FullscreenAdLoader {
    
    @Injected(\.adControllerFactory) private var adControllerFactory
    @Injected(\.adLoaderConfiguration) private var configuration
    @Injected(\.adFactory) private var adFactory
    @Injected(\.taskDispatcher) private var taskDispatcher
    
    func loadFullscreenAd(with request: ChartboostMediationAdLoadRequest, completion: @escaping (ChartboostMediationFullscreenAdLoadResult) -> Void) {
        
        func completionOnMain(_ result: ChartboostMediationFullscreenAdLoadResult) {
            taskDispatcher.async(on: .main) {   // all user callbacks on main
                completion(result)
            }
        }
        
        // Get the ad format that corresponds to the requested placement
        guard let adFormat = configuration.adFormat(forPlacement: request.placement) else {
            completionOnMain(self.makeLoadResult(error: ChartboostMediationError(code: .loadFailureInvalidChartboostMediationPlacement)))
            return
        }
        
        // Fail if the ad format is banner, since we are supposedly loading a fullscreen ad
        guard isFullscreenFormat(adFormat) else {
            completionOnMain(self.makeLoadResult(error: ChartboostMediationError(code: .loadFailureMismatchedAdFormat)))
            return
        }
        
        // Get a new ad controller with its own ad storage
        let adController = adControllerFactory.makeAdController()
        
        // Load through ad controller
        // Note the ad controller instance is retained by the completion block until the load operation finishes,
        // after that it is the fullscreen ad instance that keeps a strong reference to it and it's the publisher's
        // responsibility to keep the fullscreen ad instance alive.
        // Once the fullscreen ad is deallocated, the ad controller is deallocated too, which triggers the invalidation
        // of the loaded PartnerAd and its deallocation on the partner controller.
        let loadRequest = makeLoadRequest(request: request, adFormat: adFormat)
        adController.loadAd(request: loadRequest, viewController: nil) { [weak self, adController] result in
            guard let self = self else { return }
            
            let loadResult: ChartboostMediationFullscreenAdLoadResult
            switch result.result {
            case .success(let ad):
                // Create the ad instance shared with the user
                let fullscreenAd = self.adFactory.makeFullscreenAd(request: request, winningBidInfo: ad.bidInfo, controller: adController)
                
                // When loadAd() exits early because another ad was already loaded, it returns the identifier for
                // the already-completed request, not the one for the request that was passed at the same time as this callback.
                // Thus if an ad is already loaded when the user tries to load an ad, we return the identifier for the
                // request that completed the load, since that is the one we share with backend and partner adapters.
                loadResult = self.makeLoadResult(
                    ad: fullscreenAd,
                    error: nil,
                    loadID: ad.request.loadID,
                    metrics: result.metrics
                )
            case .failure(let error):
                loadResult = self.makeLoadResult(
                    ad: nil,
                    error: error,
                    loadID: loadRequest.loadID,
                    metrics: result.metrics
                )
            }
            
            // Report back result
            completionOnMain(loadResult)
        }
    }
    
    /// Validates that the format is compatible with fullscreen ads.
    private func isFullscreenFormat(_ adFormat: AdFormat) -> Bool {
        // An exhaustive switch makes sure that we don't forget to handle new format cases
        switch adFormat {
        case .interstitial, .rewarded, .rewardedInterstitial:
            return true
        case .banner, .adaptiveBanner:
            return false
        }
    }
    
    /// Creates a new load request for the ad controller.
    private func makeLoadRequest(request: ChartboostMediationAdLoadRequest, adFormat: AdFormat) -> HeliumAdLoadRequest {
        HeliumAdLoadRequest(
            adSize: nil,    // nil means full-screen
            adFormat: adFormat,
            keywords: request.keywords,
            heliumPlacement: request.placement,
            loadID: UUID().uuidString
        )
    }
    
    private func makeLoadResult(ad: ChartboostMediationFullscreenAd? = nil, error: ChartboostMediationError?, loadID: String = "", metrics: RawMetrics? = nil) -> ChartboostMediationFullscreenAdLoadResult {
        ChartboostMediationFullscreenAdLoadResult(
            ad: ad,
            error: error,
            loadID: loadID,
            metrics: metrics
        )
    }
}
