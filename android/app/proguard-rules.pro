# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Local Notifications
-keep class com.dexterous.** { *; }

# OneSignal
-keep class com.onesignal.** { *; }

# Facebook Audience Network
-keep class com.facebook.ads.** { *; }

# Google Play Services
-keep class com.google.android.gms.ads.** { *; }

# Billing
-keep class com.android.billingclient.** { *; }

# Play Core (Feature Delivery for splits and 16 KB page size support)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# AppsFlyer
-keep class com.appsflyer.** { *; }

# Superwall
-keep class com.superwall.** { *; }

# Network libraries
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Kotlin
-keep class kotlin.** { *; }

# General rules
-dontwarn com.google.common.base.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.j2objc.annotations.**
-dontwarn java.lang.ClassValue
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}