// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdFactoryMock: Mock<AdFactoryMock.Method>, AdFactory {

    enum Error: Swift.Error {
        case NoBannerControllers
    }

    enum Method {
        case makeFullscreenAd
        case makeBannerController
        case makeBannerSwapController
    }

    override var defaultReturnValues: [Method : Any?] {
        [
            .makeFullscreenAd: FullscreenAd.test(),
            .makeBannerController: BannerControllerMock(),
            .makeBannerSwapController: BannerSwapControllerMock()
        ]
    }

    private var bannerControllers: [ChartboostMediationSDK.BannerControllerProtocol] = []

    override func removeAllRecords() {
        super.removeAllRecords()
        bannerControllers.removeAll()
    }

    /// Call to pop the oldest created `BannerController` off the stack.
    func popBannerController() throws -> ChartboostMediationSDK.BannerControllerProtocol {
        guard bannerControllers.count > 0 else {
            throw Error.NoBannerControllers
        }

        return bannerControllers.removeFirst()
    }

    func makeFullscreenAd(controller: any AdController, loadedAd: LoadedAd, request: FullscreenAdLoadRequest) -> FullscreenAd {
        record(.makeFullscreenAd, parameters: [controller, loadedAd, request])
    }

    func makeBannerController(request: BannerAdLoadRequest, delegate: BannerControllerDelegate?, keywords: [String : String]?, partnerSettings: [String : Any]?) -> BannerControllerProtocol {
        record(.makeBannerController, parameters: [request])

        // Save the controllers in a stack for `BannerSwapControllerTests`, where we need to:
        //   * Track states across multiple `BannerControllerMock` instances.
        //   * Ensure the `BannerControllerMock` was created with the correct request.
        let controller = BannerControllerMock(request: request)
        controller.delegate = delegate
        controller.keywords = keywords
        bannerControllers.append(controller)
        return controller
    }

    func makeBannerSwapController() -> ChartboostMediationSDK.BannerSwapControllerProtocol {
        record(.makeBannerSwapController, parameters: [])
    }
}
