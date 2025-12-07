import google_mobile_ads

class NativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                        customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        let nibView = Bundle.main.loadNibNamed("NativeAdView", owner: nil, options: nil)!.first
        let nativeAdView = nibView as! GADNativeAdView

        // Set the headline
        if let headlineView = nativeAdView.headlineView as? UILabel {
            headlineView.text = nativeAd.headline
        }

        // Set the body text
        if let bodyView = nativeAdView.bodyView as? UILabel {
            bodyView.text = nativeAd.body
        }

        // Set the media view
        if let mediaView = nativeAdView.mediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }

        // Set the icon
        if let iconView = nativeAdView.iconView as? UIImageView {
            iconView.image = nativeAd.icon?.image
        }

        // Set call to action
        if let callToActionView = nativeAdView.callToActionView as? UIButton {
            callToActionView.setTitle(nativeAd.callToAction, for: .normal)
        }

        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }
}
