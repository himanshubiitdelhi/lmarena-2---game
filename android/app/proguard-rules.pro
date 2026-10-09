# Keep Play Games and Firebase data-model annotations used by plugin adapters.
-keepattributes *Annotation*
-keep class com.google.android.gms.games.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
