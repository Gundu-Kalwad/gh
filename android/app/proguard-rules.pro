-keep class com.google.android.gms.** { *; }

-keep class com.google.mlkit.** { *; }
-keep class com.syncfusion.** { *; }
-keep class io.flutter.** { *; }

# Play Core Library
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManager { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManagerFactory { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest$Builder { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallSessionState { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep class com.google.android.play.core.tasks.OnFailureListener { *; }
-keep class com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.tasks.Task { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$FeatureInstallStateUpdatedListener { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$1 { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$2 { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Syncfusion PDF rules
-keep class com.syncfusion.pdf.** { *; }
-keep class com.syncfusion.pdfviewer.** { *; }
-keep class com.syncfusion.pdfviewer.controller.** { *; }
-keep class com.syncfusion.pdfviewer.model.** { *; }
-keep class com.syncfusion.pdfviewer.rendering.** { *; }

# Google ML Kit rules
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.mlkit.text.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Camera and Image Picker rules
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.vision.barcode.** { *; }
-keep class com.google.android.gms.vision.face.** { *; }
-keep class com.google.android.gms.vision.text.** { *; }

# Preserve enums
-keepattributes InnerClasses,Signature,Enum
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve setters in Views so that animations can still work.
-keepclassmembers public class * extends android.view.View {
   void set*(***);
   *** get*();
}

# Preserve static fields in non-activity Views (e.g., custom Views).
-keepclassmembers class * extends android.view.View {
   public static <fields>;
}

# Preserve public constructors in Views.
-keepclassmembers class * extends android.view.View {
   public <init>(android.content.Context);
   public <init>(android.content.Context, android.util.AttributeSet);
   public <init>(android.content.Context, android.util.AttributeSet, int);
   public <init>(android.content.Context, android.util.AttributeSet, int, int);
}

# We want to keep methods in Activity that could be used in the XML attribute onClick
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}

# For enumeration classes, see http://proguard.sourceforge.net/manual/examples.html#enumerations
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Preserve all native methods.
-keepclasseswithmembers,allowshrinking class * {
    native <methods>;
}

# Preserve the special static methods that are required in all enumeration classes.
-keepclassmembers,allowshrinking,allowobfuscation enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve all native fields.
-keepclassmembers,allowshrinking class * {
    native <methods>;
}

# Preserve the special static methods that are required in all enumeration classes.
-keepclassmembers,allowshrinking,allowobfuscation enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
