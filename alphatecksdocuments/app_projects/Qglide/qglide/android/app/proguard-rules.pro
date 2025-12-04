# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Zego Cloud classes
-keep class im.zego.** { *; }
-keep class im.zego.zegoexpress.** { *; }
-dontwarn im.zego.**

# Keep Zego AVKit2 classes (legacy classes still referenced by native code)
-keep class com.zego.zegoavkit2.** { *; }
-keep class com.zego.** { *; }
-dontwarn com.zego.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Firebase classes (used for FCM notifications)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Ignore missing Google Play Core classes (used by Flutter deferred components, but not needed for this app)
# These classes are optional and only needed if using Play Store dynamic feature modules
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotation default values
-keepattributes AnnotationDefault

# Keep line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Preserve native method names
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep classes that are referenced in native code
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <methods>;
    !private <fields>;
}

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Prevent obfuscation of classes used in reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

