# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Isar DB JNI bindings & Models
-keep class dev.isar.isar_flutter_libs.** { *; }
-keep class dev.isar.** { *; }
-keepclassmembers class * extends dev.isar.IsarLink { *; }
-keepclassmembers class * extends dev.isar.IsarLinks { *; }

# Security & Biometrics
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn androidx.biometric.**

# Crypto & Encryption
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Google Auth & Services
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.android.gms.**

