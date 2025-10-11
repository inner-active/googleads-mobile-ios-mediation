#import "GADMAdapterFyberNativeAd.h"

#import <IASDKCore/IASDKCore.h>

#import <stdatomic.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberUtils.h"

@interface GADMAdapterFyberNativeAd () <GADMediationNativeAd, IANativeAdDelegate>
@end

@implementation GADMAdapterFyberNativeAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationNativeLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationNativeAdEventDelegate> _delegate;

  /// DT Exchange Native Ad Spot to be loaded.
    IANativeAdSpot *_nativeAdSpot;
    IANativeAdAssets *_nativeAdAssets;
}

- (instancetype)initWithAdConfiguration:
    (nonnull GADMediationNativeAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadNativeAdWithCompletionHandler:
    (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationNativeLoadCompletionHandler originalAdLoadHandler = [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler =
      ^id<GADMediationNativeAdEventDelegate>(id<GADMediationNativeAd> nativeAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationNativeAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(nativeAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  GADMAdapterFyberNativeAd *__weak weakSelf = self;
  GADMAdapterFyberInitializeWithAppId(
      _adConfiguration.credentials.settings[GADMAdapterFyberApplicationID],
      ^(NSError *_Nullable error) {
        GADMAdapterFyberNativeAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          GADMAdapterFyberLog("Failed to initialize DT Exchange SDK: %@",
                              error.localizedDescription);
          strongSelf->_loadCompletionHandler(nil, error);
          return;
        }

        [self loadNativeAd];
      });
}

- (void)loadNativeAd {
  GADMAdapterFyberNativeAd *__weak weakSelf = self;


  NSString *bidResponse = _adConfiguration.bidResponse;
  IAAdRequest *request;
  // Bidding flow only for native ads
  request = GADMAdapterFyberBuildRequestWithAdConfiguration(_adConfiguration);
  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterFyberSpotID];
    
  IASDKCore.sharedInstance.mediationType = [[IAMediationAdMob alloc] init];
    
  _nativeAdSpot = [IANativeAdSpot build:^(id<IANativeAdSpotBuilder> _Nonnull builder) {
      builder.adRequest = request;
      builder.delegate = self;
      if (spotID.length) {
          builder.userInfo = @{@"DTSpotID": spotID};
      }
  }];

  [_nativeAdSpot loadAdWithMarkup:bidResponse withCompletion:^(IANativeAdAssets *nativeAdAssets, NSError *error) {
      GADMAdapterFyberNativeAd *strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      
        if (!error) {
            strongSelf->_nativeAdAssets = nativeAdAssets;
            
            strongSelf->_loadCompletionHandler(self, nil);
        } else {
            if (error) {
              GADMAdapterFyberLog("Failed to initialize DT Exchange SDK: %@",
                                  error.localizedDescription);
              strongSelf->_loadCompletionHandler(nil, error);
              return;
            }
        }
    }];
}

#pragma mark - GADMediationNativeAd

// TODO: is needed?

//- (BOOL)handlesUserClicks {
//    return YES;
//}
//
//- (BOOL)handlesUserImpressions {
//    return YES;
//}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)headline {
    return _nativeAdAssets.adTitle;
}

- (NSArray<GADNativeAdImage *> *)images {
    UIView *mediaView = _nativeAdAssets.mediaView;
    
    if ([mediaView isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)mediaView;
        
        if (imageView.image) {
            GADNativeAdImage *mappedImage = [GADNativeAdImage.alloc initWithImage:imageView.image];
            return @[mappedImage];
        }
    }
    return @[];
}

- (NSString *)body {
    return _nativeAdAssets.adDescription;
}

- (GADNativeAdImage *)icon {
    UIImageView *iconImageView = (UIImageView *)_nativeAdAssets.appIcon;
    return [GADNativeAdImage.alloc initWithImage:iconImageView.image];
}

- (NSString *)callToAction {
    return _nativeAdAssets.callToActionText;
}

- (NSDecimalNumber *)starRating {
    return _nativeAdAssets.rating ? [NSDecimalNumber decimalNumberWithDecimal:_nativeAdAssets.rating.decimalValue] : nil;
}

- (UIView *)mediaView {
    return _nativeAdAssets.mediaView;
}

- (BOOL)hasVideoContent {
    return ![_nativeAdAssets.mediaView isKindOfClass:[UIImageView class]];
}

- (CGFloat)mediaContentAspectRatio {
    return _nativeAdAssets.mediaAspectRatio.floatValue;
}

//not supported by DTExchange
- (NSString *)store {
    return nil;
}

//not supported by DTExchange
- (NSString *)price {
    return nil;
}

//not supported by DTExchange
- (NSString *)advertiser {
    return nil;
}

//not supported by DTExchange
- (NSDictionary<NSString *,id> *)extraAssets {
    return nil;
}

//not supported by DTExchange
- (UIView *)adChoicesView {
    return nil;
}

- (void)didRenderInView:(UIView *)view clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)clickableAssetViews nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier,UIView *> *)nonclickableAssetViews viewController:(UIViewController *)viewController {
    
    // TODO: nonclickableAssetViews is relevant for us?
    
    static const NSInteger ViewTagTitle = 1;
    static const NSInteger ViewTagMediaView = 2;
    static const NSInteger ViewTagIcon = 4;
    static const NSInteger ViewTagDescription = 5;
    static const NSInteger ViewTagRating = 6;
    static const NSInteger ViewTagCta = 7;
    
    __block UIView *mediaView = nil;
    __block UIView *iconView = nil;
    NSMutableArray<UIView *> *otherClickableViews = NSMutableArray.array;
    
    // Map GADNativeAssetIdentifier -> ViewTag
    NSDictionary<GADNativeAssetIdentifier, NSNumber *> *assetToTagMap = @{
        GADNativeHeadlineAsset: @(ViewTagTitle),
        GADNativeCallToActionAsset: @(ViewTagCta),
        GADNativeIconAsset: @(ViewTagIcon),
        GADNativeBodyAsset: @(ViewTagDescription),
        GADNativeStarRatingAsset: @(ViewTagRating),
//        GADNativeImageAsset: @(ViewTagMediaView), // TODO: needed for image too?
        GADNativeMediaViewAsset: @(ViewTagMediaView)
    };

    
    // Enumerate clickableAssetViews
    [clickableAssetViews enumerateKeysAndObjectsUsingBlock:^(GADNativeAssetIdentifier assetIdentifier, UIView *assetView, BOOL *stop) {
        NSNumber *tagNumber = assetToTagMap[assetIdentifier];
        
        if (tagNumber) {
            assetView.tag = tagNumber.integerValue;
            [otherClickableViews addObject:assetView];
        }
        
        switch (tagNumber.intValue) {
            case ViewTagMediaView:
                mediaView = assetView;
                break;
            case ViewTagIcon:
                iconView = assetView;
                break;
            default:
                break;
        }
    }];

    
    [_nativeAdAssets registerViewForInteraction:view
                                          mediaView:mediaView
                                           iconView:iconView
                                     clickableViews:otherClickableViews];
}

- (void)didRecordImpression {
    
}

#pragma mark - IANativeAdDelegate

//TODO: are more callbacks needed?

- (UIViewController *)iaParentViewControllerForAdSpot:(IANativeAdSpot *)adSpot {
    return _adConfiguration.topViewController;
}

- (void)iaNativeAdDidReceiveClick:(IANativeAdSpot *)adSpot origin:(NSString *)origin {
    [_delegate reportClick];
}

- (void)iaNativeAdWillLogImpression:(IANativeAdSpot *)adSpot {
  [_delegate reportImpression];
}

- (void)iaNativeAdWillPresentFullscreen:(IANativeAdSpot *)adSpot {
    [_delegate willPresentFullScreenView];
}

- (void)iaNativeAdDidPresentFullscreen:(IANativeAdSpot *)adSpot {
    NSLog(@"iaNativeAdDidPresentFullscreen, unitID: %@, spotID %@", adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

- (void)iaNativeAdWillDismissFullscreen:(IANativeAdSpot *)adSpot {
    [_delegate willDismissFullScreenView];
}

- (void)iaNativeAdDidDismissFullscreen:(IANativeAdSpot *)adSpot {
    [_delegate didDismissFullScreenView];
}

- (void)iaNativeAdWillOpenExternalApp:(IANativeAdSpot *)adSpot {
    // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)iaNativeAdDidExpire:(IANativeAdSpot *)adSpot {
    // as of DT Exchange SDK v8.4.0, "iaAdDidExpire" callback is triggered only from IAFullscreenUnitController
    NSLog(@"iaNativeAdDidExpire, unitID: %@, spotID %@", adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

// native video callbacks
- (void)iaNativeAd:(IANativeAdSpot *)adSpot videoDurationUpdated:(NSTimeInterval)videoDuration {
    NSLog(@"iaNativeAd:videoDurationUpdated:, duration is %.2f, for unitID: %@, spotID %@", videoDuration, adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

- (void)iaNativeAd:(IANativeAdSpot *)adSpot videoInterruptedWithError:(NSError *)error {
    NSLog(@"iaNativeAd:videoInterruptedWithError: %@, for unitID: %@, spotID %@", error, adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

- (void)iaNativeAd:(IANativeAdSpot *)adSpot videoProgressUpdatedWithCurrentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    // this callback is triggered very often, enable only if needed
    //NSLog(@"iaNativeAd:videoProgressUpdatedWithCurrentTime: %.2f totalTime: %.2f, for unitID: %@, spotID %@", currentTime, totalTime, adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

- (void)iaNativeAdVideoCompleted:(IANativeAdSpot *)adSpot {
    [_delegate didEndVideo];
}

// native image callbacks
- (void)iaNativeAdSpot:(IANativeAdSpot *)adSpot didFailToLoadImageFromUrl:(NSURL *)url with:(NSError *)error {
    NSLog(@"iaNativeAdSpot:didFailToLoadImageFromUrl: %@, with error: %@, for unitID: %@, spotID %@", url.absoluteString, error, adSpot.adRequest.unitID, adSpot.userInfo[@"DTSpotID"]);
}

-(void)iaNativeAd:(IANativeAdSpot *)adSpot didLoadImageFromUrl:(NSURL *)url {
    NSLog(@"iaNativeAd:didLoadImageFromUrl %@,  spotID %@", url, adSpot.userInfo[@"DTSpotID"]);
}

@end

