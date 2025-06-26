package com.thesis.generator.ai

import android.content.Context
import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        with(nativeAdView) {
            // Headline
            nativeAd.headline?.let {
                findViewById<TextView>(R.id.ad_headline).text = it
                headlineView = findViewById(R.id.ad_headline)
            }

            // Body
            nativeAd.body?.let {
                findViewById<TextView>(R.id.ad_body).text = it
                bodyView = findViewById(R.id.ad_body)
            }

            // Media
            mediaView = findViewById(R.id.ad_media)

            // App Icon
            nativeAd.icon?.let {
                findViewById<ImageView>(R.id.ad_app_icon).setImageDrawable(it.drawable)
                iconView = findViewById(R.id.ad_app_icon)
            }

            // Call to Action
            nativeAd.callToAction?.let {
                findViewById<Button>(R.id.ad_call_to_action).text = it
                callToActionView = findViewById(R.id.ad_call_to_action)
            }

            setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}
