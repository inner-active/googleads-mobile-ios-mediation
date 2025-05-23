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
import MolocoAdapter
import MolocoSDK
import UIKit

/// A fake implementation of MolocoBannerFactory that creates a FakeBannerRewarded.
final class FakeMolocoBannerFactory {

  enum BannerApiUsed {
    case regularBanner
    case MREC
  }

  var fakeMolocoBanner: FakeMolocoBanner?

  var bannerApiUsed: BannerApiUsed?

  /// Var to capture the ad unit ID that was used to create the Moloco banner ad object.
  /// Used for assertion. It is initlialized to a value that is never asserted for.
  var adUnitIDUsedToCreateMolocoAd: String = ""

  /// The error that should occur during banner ad loading.
  let loadError: Error?

  /// Whether the banner ad fails to show.
  let shouldFailToShow: Bool

  /// The specified error that occurs during banner ad presentation.
  let showError: Error?

  /// The parameters passed here are used to create FakeMolocoBanner.
  ///
  /// See FakeMolocoBanner for how these parameters are used.
  init(loadError: Error? = nil, shouldFailToShow: Bool = false, showError: Error? = nil) {
    self.loadError = loadError
    self.shouldFailToShow = shouldFailToShow
    self.showError = showError
  }

}

// MARK: - MolocoBannerFactory

extension FakeMolocoBannerFactory: MolocoBannerFactory {

  func createBanner(for adUnit: String, delegate: MolocoBannerDelegate, watermarkData: Data?) -> (
    UIView & MolocoAd
  )? {
    bannerApiUsed = BannerApiUsed.regularBanner
    adUnitIDUsedToCreateMolocoAd = adUnit
    fakeMolocoBanner = FakeMolocoBanner(
      bannerDelegate: delegate, loadError: loadError, shouldFailToShow: shouldFailToShow,
      showError: showError)
    return fakeMolocoBanner
  }

  func createMREC(for adUnit: String, delegate: MolocoBannerDelegate, watermarkData: Data?) -> (
    UIView & MolocoAd
  )? {
    bannerApiUsed = BannerApiUsed.MREC
    adUnitIDUsedToCreateMolocoAd = adUnit
    fakeMolocoBanner = FakeMolocoBanner(
      bannerDelegate: delegate, loadError: loadError, shouldFailToShow: shouldFailToShow,
      showError: showError)
    return fakeMolocoBanner
  }
}
