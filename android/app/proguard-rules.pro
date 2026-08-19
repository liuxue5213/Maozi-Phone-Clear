# Flutter ProGuard 规则
# 保留 Flutter 引擎和插件所需的类

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保留原生插件
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}

# 保留 Flutter 使用的注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# 保留 Provider 和模型类（避免反射问题）
-keep class com.maozi.phone_clear.** { *; }

# Flutter local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# 避免警告
-dontwarn io.flutter.**
