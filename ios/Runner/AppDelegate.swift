import UIKit
import Flutter
import google_mobile_ads
import FirebaseCore

class NativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd, customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        let bundle = Bundle(for: type(of: self))
        let nibView = bundle.loadNibNamed("NativeAdView", owner: nil, options: nil)?.first as? GADNativeAdView
        guard let nativeAdView = nibView else {
            return nil
        }

        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)

        nativeAdView.nativeAd = nativeAd
        return nativeAdView
    }
}


@main
class AppDelegate: FlutterAppDelegate {
    private var nativeAdFactory: NativeAdFactory?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        GeneratedPluginRegistrant.register(with: self)

        nativeAdFactory = NativeAdFactory()
        let registry = self as FlutterPluginRegistry
        FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
            registry,
            factoryId: "customNative",
            nativeAdFactory: nativeAdFactory!
        )

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "customNative")
    }
}
