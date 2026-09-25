# Proguard rules for TensorFlow Lite and Flutter dependencies
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.llfbandit.record.** { *; }
