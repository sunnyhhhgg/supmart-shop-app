# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保留基本类型
-keepclassmembers class * {
    native <methods>;
}

# 保留枚举类型
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留注解
-keepattributes *Annotation*

# 保留R类
-keep class **.R$* {
    *;
}

# 保留Serializable类
-keep class * implements java.io.Serializable {
    *;
}

# 保留HTTP相关类
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }

# 保留WebSocket相关类
-keep class org.java_websocket.** { *; }

# 保留加密相关类
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# 保留JSON相关类
-keep class org.json.** { *; }

# 保留通知相关类
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.common.** { *; }

# 移除日志
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}