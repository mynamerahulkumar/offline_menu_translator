# Keep all classes in com.google and its subpackages, and all their members
-keep class com.google.** { *; }
-keep interface com.google.** { *; }
-keep enum com.google.** { *; }

# Keep all classes in javax.lang.model and its subpackages, and all their members
-keep class javax.lang.model.** { *; }
-keep interface javax.lang.model.** { *; }
-keep enum javax.lang.model.** { *; }

# Keep specific classes related to autovalue.shaded.com.squareup.javapoet
-keep class autovalue.shaded.com.squareup.javapoet.** { *; }

# Keep all classes in BouncyCastle JSSE and its subpackages, and all their members
-keep class org.bouncycastle.jsse.** { *; }
-keep interface org.bouncycastle.jsse.** { *; }

# Keep all classes in Conscrypt and its subpackages, and all their members
-keep class org.conscrypt.** { *; }
-keep interface org.conscrypt.** { *; }

# Keep all classes in OpenJSSE and its subpackages, and all their members
-keep class org.openjsse.javax.net.ssl.** { *; }
-keep class org.openjsse.net.ssl.** { *; }
-keep interface org.openjsse.javax.net.ssl.** { *; }

# For OkHttp and its internal platform classes if they are being stripped
-keep class okhttp3.internal.platform.** { *; }
-keep interface okhttp3.internal.platform.** { *; }

# MediaPipe Proto buffers missing classes
-dontwarn com.google.mediapipe.proto.**
