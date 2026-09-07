# ==================== MOBILE SCANNER / ML KIT ====================
# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.barcode.common.** { *; }
-keep class com.google.mlkit.vision.barcode.internal.** { *; }
-dontwarn com.google.mlkit.**

# Keep CameraX classes
-keep class androidx.camera.** { *; }
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.camera2.** { *; }
-keep class androidx.camera.lifecycle.** { *; }
-keep class androidx.camera.view.** { *; }
-dontwarn androidx.camera.**

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Guava (required by ML Kit)
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep exceptions
-keep public class * extends java.lang.Exception

# ==================== FLUTTER ====================
# Keep Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ==================== MOBILE SCANNER SPECIFIC ====================
# Keep mobile_scanner plugin classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**

# Keep Barcode classes
-keep class com.google.mlkit.vision.barcode.Barcode { *; }
-keep class com.google.mlkit.vision.barcode.BarcodeScanner { *; }
-keep class com.google.mlkit.vision.barcode.BarcodeScannerOptions { *; }
-keep class com.google.mlkit.vision.barcode.BarcodeScanning { *; }

# ==================== GENERAL ====================
# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}