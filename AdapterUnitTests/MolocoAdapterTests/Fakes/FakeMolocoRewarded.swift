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

/// A fake implementation of MolocoRewarded.
final class FakeMolocoRewarded {

  // MolocoSDK.MolocoRewardedInterstitial properties.
  var rewardedDelegate: (any MolocoSDK.MolocoRewardedDelegate)?
  var fullscreenViewController: UIViewController?
  var isReady: Bool

  init() {
    // TODO(b/359236741): Implement init logic.
    self.isReady = false
  }

}

// MARK: - MolocoSDK.MolocoRewardedInterstitial

extension FakeMolocoRewarded: MolocoSDK.MolocoRewardedInterstitial {

  func show(from viewController: UIViewController) {
    // No-op.
  }

  func show(from viewController: UIViewController, muted: Bool) {
    // No-op.
  }

  func load(bidResponse: String) {
    // No-op.
  }

  func destroy() {
    // No-op.
  }

}
