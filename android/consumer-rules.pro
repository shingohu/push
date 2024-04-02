
#xiaomi push sdk 混淆规则
#这里com.xiaomi.mipushdemo.DemoMessageRreceiver改成app中定义的完整类名

#可以防止一个误报的 warning 导致无法成功编译，如果编译使用的 Android 版本是 23。
-dontwarn com.xiaomi.push.**





#vivo push sdk 混淆规则
-dontwarn com.vivo.push.**

-keep class com.vivo.push.**{*; }

-keep class com.vivo.vms.**{*; }



#oppo push sdk 混淆规则

-keep public class * extends android.app.Service
-keep class com.heytap.msp.** { *;}

#huawei push sdk 混淆规则
-ignorewarnings
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keep class com.huawei.hianalytics.**{*;}
-keep class com.huawei.updatesdk.**{*;}
-keep class com.huawei.hms.**{*;}


-keep class com.lianke.push.**{
*;
}

