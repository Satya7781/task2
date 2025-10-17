# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep audio player classes
-keep class com.ryanheise.just_audio.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# Suppress warnings for media2 library
-dontwarn androidx.media2.**
-dontwarn android.support.v4.media.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Disable warnings as errors
-ignorewarnings
