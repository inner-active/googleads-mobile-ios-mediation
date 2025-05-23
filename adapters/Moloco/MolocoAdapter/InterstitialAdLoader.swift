// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMobileAds
import MolocoSDK

/// Loads and presents interstitial ads on Moloco ads SDK.
final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// The completion handler to call when interstitial ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationInterstitialLoadCompletionHandler

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?

  private let molocoInterstitialFactory: MolocoInterstitialFactory

  private var interstitialAd: MolocoInterstitial?

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler,
    molocoInterstitialFactory: MolocoInterstitialFactory
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoInterstitialFactory = molocoInterstitialFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: .adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitId = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitId = molocoAdUnitId else {
      let error = MolocoUtils.error(
        code: .invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = MolocoUtils.error(code: .nilBidResponse, description: "Nil bid response.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.interstitialAd = self.molocoInterstitialFactory.createInterstitial(
        for: molocoAdUnitId, delegate: self, watermarkData: adConfiguration.watermark)
      self.interstitialAd?.load(bidResponse: bidResponse)
    }
  }

}

// MARK: - MediationInterstitialAd

extension InterstitialAdLoader: MediationInterstitialAd {

  func present(from viewController: UIViewController) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      guard let interstitialAd = self.interstitialAd, interstitialAd.isReady else {
        let error = MolocoUtils.error(
          code: MolocoAdapterErrorCode.adNotReadyForShow, description: "Ad is not ready to be shown"
        )
        self.eventDelegate?.didFailToPresentWithError(error)
        return
      }

      self.eventDelegate?.willPresentFullScreenView()
      interstitialAd.show(from: viewController)
    }
  }

}

// MARK: - MolocoInterstitialDelegate

extension InterstitialAdLoader: MolocoInterstitialDelegate {
  func didLoad(ad: any MolocoSDK.MolocoAd) {
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportImpression()
  }

  func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    let showError =
      error
      ?? MolocoUtils.error(
        code: .adFailedToShow, description: "Ad failed to show")
    eventDelegate?.didFailToPresentWithError(showError)
  }

  func didHide(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didDismissFullScreenView()
  }

  func didClick(on ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportClick()
  }

}
