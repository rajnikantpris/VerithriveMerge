# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep OkHttp classes (required by UCrop)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep UCrop classes
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep all model classes that might be used with Gson or similar
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep social auth classes
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Keep Apple Sign In classes
-keep class com.apple.signin.** { *; }
-dontwarn com.apple.signin.**

# Keep HTTP classes
-keep class retrofit2.** { *; }
-keep class retrofit.** { *; }
-dontwarn retrofit2.**

# Keep OkHttp3 classes
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep Okio classes
-keep class okio.** { *; }
-dontwarn okio.**

# Keep logging classes
-keep class android.util.Log { *; }
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
