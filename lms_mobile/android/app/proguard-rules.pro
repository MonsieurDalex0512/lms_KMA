# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# ============================================
# Flutter Framework
# ============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ============================================
# Native Methods
# ============================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================
# Parcelable
# ============================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ============================================
# Dio HTTP Client
# ============================================
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# Provider (State Management)
# ============================================
-keep class provider.** { *; }
-keep class * extends provider.ChangeNotifier { *; }

# ============================================
# Go Router
# ============================================
-keep class go_router.** { *; }

# ============================================
# JWT Decoder
# ============================================
-keep class jwt_decoder.** { *; }

# ============================================
# Encryption Libraries
# ============================================
-keep class encrypt.** { *; }
-keep class crypto.** { *; }
-keep class pointycastle.** { *; }
-dontwarn encrypt.**
-dontwarn crypto.**
-dontwarn pointycastle.**

# ============================================
# Flutter Secure Storage
# ============================================
-keep class flutter_secure_storage.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ============================================
# Shared Preferences
# ============================================
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$* { *; }

# ============================================
# Socket.IO Client
# ============================================
-keep class socket_io_client.** { *; }
-keep class io.socket.** { *; }
-dontwarn socket_io_client.**
-dontwarn io.socket.**

# ============================================
# WebView Flutter
# ============================================
-keep class webview_flutter.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

# ============================================
# FL Chart
# ============================================
-keep class fl_chart.** { *; }

# ============================================
# Table Calendar
# ============================================
-keep class table_calendar.** { *; }

# ============================================
# Google Fonts
# ============================================
-keep class google_fonts.** { *; }

# ============================================
# Intl (Internationalization)
# ============================================
-keep class intl.** { *; }

# ============================================
# Kotlin
# ============================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ============================================
# Keep MainActivity
# ============================================
-keep class com.example.lms_mobile.MainActivity { *; }

# ============================================
# Keep Application class if exists
# ============================================
-keep class * extends android.app.Application {
    <init>();
}

# ============================================
# Keep annotations
# ============================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ============================================
# Keep line numbers for debugging
# ============================================
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ============================================
# Remove logging in release
# ============================================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

