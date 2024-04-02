package com.lianke.push;

import android.Manifest;
import android.app.Activity;
import android.app.ActivityManager;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.xiaomi.mipush.sdk.MiPushClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * PushPlugin
 */
public class PushPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private ActivityPluginBinding activityPluginBinding;


    Map<Integer, PermissionCallback> permissionCallbackMap = new HashMap<>();

    Map<Integer, ActivityResultCallback> activityResultCallbackMap = new HashMap<>();


    abstract static class PermissionCallback {
        abstract void onPermission(boolean hasPermission);
    }

    abstract static class ActivityResultCallback {
        abstract void onCallback();
    }


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        PushKit.instance.init(context);
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.lianke.push");
        channel.setMethodCallHandler(this);

    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        if ("hasPermission".equals(method)) {
            result.success(hasPermission());
        } else if ("requestPermission".equals(method)) {
            requestPermission(result);
        } else if ("openNotificationSettings".equals(method)) {
            gotoNotificationSetting();
            result.success(true);
        } else if ("clearAll".equals(method)) {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancelAll();
            result.success(true);
        } else if ("register".equals(method)) {
            register();
            result.success(true);
        } else if ("unRegister".equals(method)) {
            unRegister();
            result.success(true);
        }
    }

    private void register() {
        PushKit.instance.register(new PushKit.PushListener() {
            @Override
            public void onToken(PushType pushType, String token) {
                Map<String, Object> map = new HashMap<String, Object>();
                map.put("type", pushType.name());
                map.put("token", token);
                channel.invokeMethod("onToken", map);
            }

            @Override
            public void onMessageClick(PushType pushType, Map<String, Object> message) {
                Map<String, Object> map = new HashMap<String, Object>();
                map.put("type", pushType.name());
                map.put("message", message);
                channel.invokeMethod("onLaunch", map);
            }
        });
    }

    private void unRegister() {
        PushKit.instance.unRegister();
    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        context = null;
    }


    private boolean hasPermission() {
        if (context != null) {
            return NotificationManagerCompat.from(context).areNotificationsEnabled();
        }
        return false;
    }


    public void requestPermission(Result result) {
        if (activity != null) {
            PermissionCallback callback = new PermissionCallback() {
                @Override
                void onPermission(boolean hasPermission) {
                    result.success(hasPermission);
                    permissionCallbackMap.remove(result.hashCode());
                }
            };
            permissionCallbackMap.put(result.hashCode(), callback);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) ==
                        PackageManager.PERMISSION_GRANTED) {
                    callback.onPermission(true);
                } else {
                    ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.POST_NOTIFICATIONS}, result.hashCode());
                }
            } else {
                callback.onPermission(NotificationManagerCompat.from(context).areNotificationsEnabled());
            }
        }
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        PushKit.instance.handleIntent(intent);
        return false;
    }


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        activityPluginBinding = binding;
        binding.addRequestPermissionsResultListener(this);
        binding.addActivityResultListener(this);
        binding.addOnNewIntentListener(this);
        PushKit.instance.handleIntent(binding.getActivity().getIntent());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {
        activityPluginBinding.removeRequestPermissionsResultListener(this);
        activityPluginBinding.removeActivityResultListener(this);
        activityPluginBinding.removeOnNewIntentListener(this);
        activity = null;
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (permissionCallbackMap.containsKey(requestCode)) {
            if (grantResults.length > 0)
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    permissionCallbackMap.get(requestCode).onPermission(true);
                    return true;
                } else {
                    permissionCallbackMap.get(requestCode).onPermission(false);
                }
        }
        return false;
    }


    private void gotoNotificationSetting() {
        if (activity == null || context == null) {
            return;
        }
        try {
            String packageName = context.getPackageName();
            Intent intent = new Intent();
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
                intent.putExtra("app_package", packageName);
                intent.putExtra("app_uid", context.getApplicationInfo().uid);
            } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.KITKAT) {
                intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                intent.addCategory(Intent.CATEGORY_DEFAULT);
                intent.setData(Uri.parse("package:" + packageName));
            } else {
                return;
            }
            context.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
            // 出现异常则跳转到应用设置界面
            Intent intent = new Intent();
            intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            Uri uri = Uri.fromParts("package", context.getPackageName(), null);
            intent.setData(uri);
            context.startActivity(intent);
        }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (activityResultCallbackMap.containsKey(requestCode)) {
            activityResultCallbackMap.get(requestCode).onCallback();
            return true;
        }
        return false;
    }
}
