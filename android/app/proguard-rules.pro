# Flutter网络相关
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# OkHttp相关 (Flutter的HTTP请求底层库)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# 保留HTTP模块相关代码
-keep class com.android.okhttp.** { *; }
-keep interface com.android.okhttp.** { *; }

# 如果使用Gson进行JSON解析
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 保留网络相关类
-keep class java.net.** { *; }
-keep interface java.net.** { *; }
-keep class javax.net.** { *; }
-keep interface javax.net.** { *; }
-keep class android.net.** { *; }
-keep interface android.net.** { *; }

# SSL相关
-keep class javax.net.ssl.** { *; }
-keep class sun.security.** { *; }
-keep class org.apache.harmony.xnet.provider.jsse.** { *; }

# Flutter Secure Storage相关
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# 保留Google API相关代码
-keep class com.google.api.** { *; }
-keep class com.google.cloud.** { *; }
-keep class com.google.generativeai.** { *; }

# 保留HTTP客户端
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn android.net.http.**

# 保留flutter_sharing_intent
-keep class com.kasem.flutter_sharing_intent.** { *; }

# 保留Flutter路径相关
-keep class io.flutter.plugins.pathprovider.** { *; }

# 调试信息
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# 确保不混淆主应用类
-keep class com.gojyuplusone.gifiti.MainApplication { *; }
-keep class com.gojyuplusone.gifiti.MainActivity { *; } 