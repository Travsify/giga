# Stripe Android SDK ProGuard rules
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }

# For Push Provisioning if used
-keep class com.stripe.android.pushprovisioning.** { *; }

# General ProGuard rules
-dontwarn com.stripe.android.**
-dontwarn com.stripe.android.pushprovisioning.**

# React Native related (Stripe React Native depends on these)
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**
