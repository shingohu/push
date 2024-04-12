package com.lianke.push;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;


import com.heytap.msp.push.HeytapPushManager;
import com.heytap.msp.push.callback.ICallBackResultService;
import com.huawei.hms.push.HmsMessaging;
import com.huawei.hms.push.RemoteMessage;
import com.lianke.push.huawei.RemoteMessageUtils;
import com.lianke.push.utils.BundleUtils;
import com.lianke.push.utils.MainThreadUtil;
import com.lianke.push.utils.MapUtils;
import com.vivo.push.IPushActionListener;
import com.vivo.push.PushClient;
import com.vivo.push.PushConfig;
import com.vivo.push.listener.IPushQueryActionListener;
import com.vivo.push.util.VivoPushException;
import com.xiaomi.mipush.sdk.MiPushClient;
import com.xiaomi.mipush.sdk.MiPushMessage;
import com.xiaomi.mipush.sdk.PushMessageHelper;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PushKit {

    private static final String TAG = "PushKit";
    public static PushKit instance = new PushKit();

    private PushListener listener;
    private Context context;


    private PushType cachedPushType;
    private Map<String, Object> cachedMessage;


    private PushKit() {

    }

    public void init(Context context) {
        this.context = context;
    }

    public void register(PushListener pushListener) {
        this.listener = pushListener;
        if (isSupport(PushType.XiaoMi) && shouldInit(context)) {
            MiPushClient.registerPush(context, BuildConfig.XIAOMI_APP_ID, BuildConfig.XIAOMI_APP_KEY);
        } else if (isSupport(PushType.Huawei)) {
            HmsMessaging.getInstance(context).turnOnPush();
            HmsMessaging.getInstance(context).setAutoInitEnabled(true);
            HmsMessaging.getInstance(context).setAutoInitEnabled(false);
        } else if (isSupport(PushType.Oppo)) {
            HeytapPushManager.init(context, false);
            HeytapPushManager.register(context, BuildConfig.OPPO_APP_KEY, BuildConfig.OPPO_APP_SECRET, new ICallBackResultService() {
                /**
                 * 注册的结果,如果注册成功,registerID就是客户端的唯一身份标识
                 *
                 * @param responseCode 接口执行结果码，0表示接口执行成功
                 * @param registerID   注册id/token
                 * @param packageName 如果当前执行注册的应用是常规应用，则通过packageName返回当前应用对应的包名
                 * @param miniPackageName  如果当前是快应用进行push registerID的注册，则通过miniPackageName进行标识快应用包名
                 */
                @Override
                public void onRegister(int responseCode, String registerID, String packageName, String miniPackageName) {
                    if (responseCode == 0) {
                        onToken(PushType.Oppo, registerID);
                    }
                }

                @Override
                public void onUnRegister(int i, String s, String s1) {

                }

                @Override
                public void onSetPushTime(int i, String s) {

                }

                @Override
                public void onGetPushStatus(int i, int i1) {

                }

                @Override
                public void onGetNotificationStatus(int i, int i1) {

                }

                @Override
                public void onError(int i, String s, String s1, String s2) {

                }
            });
        } else if (isSupport(PushType.ViVo)) {
            PushClient.getInstance(context).turnOnPush(state -> {

                if (state == 0) {
                    PushClient.getInstance(context).getRegId(new IPushQueryActionListener() {
                        @Override
                        public void onSuccess(String s) {
                            onToken(PushType.ViVo, s);
                        }

                        @Override
                        public void onFail(Integer integer) {

                        }
                    });
                }

            });
        }
        if (this.cachedMessage != null && this.cachedPushType != null) {
            onMessageClick(cachedPushType, cachedMessage);
            this.cachedMessage = null;
            this.cachedPushType = null;
        }
    }


    public void unRegister() {
        this.listener = null;
        this.cachedMessage = null;
        this.cachedPushType = null;
        if (isSupport(PushType.XiaoMi)) {
            MiPushClient.unregisterPush(context);
        } else if (isSupport(PushType.Huawei)) {
            HmsMessaging.getInstance(context).turnOffPush();
        } else if (isSupport(PushType.Oppo)) {
            HeytapPushManager.unRegister();
        } else if (isSupport(PushType.ViVo)) {
            PushClient.getInstance(context).turnOffPush(new IPushActionListener() {
                @Override
                public void onStateChanged(int i) {

                }
            });

        }
    }


    private boolean isSupport(PushType pushType) {
        if (pushType == PushType.XiaoMi) {
            return !BuildConfig.XIAOMI_APP_ID.isEmpty() && !BuildConfig.XIAOMI_APP_KEY.isEmpty() && RomUtil.isXiaoMi();
        }
        if (pushType == PushType.Huawei) {
            return BuildConfig.HUAWEI_AGC_SERVICE_EXIST && RomUtil.isHuaWei();
        }
        if (pushType == PushType.Oppo) {
            ///目前支持 ColorOS3.1及以上的系统的OPPO的机型，一加5/5t及以上机型，realme所有机型。
            ///所以不要用rom来判断
            return !BuildConfig.OPPO_APP_KEY.isEmpty() && !BuildConfig.OPPO_APP_SECRET.isEmpty() && HeytapPushManager.isSupportPush(context);
        }
        if (pushType == PushType.ViVo) {
            ///目前支持 vivo iqoo
            ///所以不要用rom来判断
            try {
                PushConfig config = new PushConfig.Builder()
                        .agreePrivacyStatement(true)
                        .build();
                PushClient.getInstance(context).initialize(config);
            } catch (VivoPushException e) {
                e.printStackTrace();
            }
            return !BuildConfig.VIVO_APP_ID.isEmpty() && !BuildConfig.VIVO_APP_KEY.isEmpty() && PushClient.getInstance(context).isSupport();
        }

        return false;
    }


    public void onToken(PushType pushType, String token) {
        MainThreadUtil.runMainThread(() -> {
            if (this.listener != null) {
                this.listener.onToken(pushType, token);
            }
        });

    }


    public void onMessageClick(PushType pushType, Map<String, Object> message) {
        if (this.listener != null) {
            this.listener.onMessageClick(pushType, message);
        } else {
            ///还未注册 缓存起来 等注册成功
            cachedPushType = pushType;
            cachedMessage = message;
        }
    }


    public void handleIntent(Intent intent) {
        Bundle bundleExtras = intent.getExtras();
        if (bundleExtras != null) {
            if (bundleExtras.containsKey(PushMessageHelper.KEY_MESSAGE) && isSupport(PushType.XiaoMi)) {
                ///小米推送
                MiPushMessage miPushMessage = (MiPushMessage) intent.getSerializableExtra(PushMessageHelper.KEY_MESSAGE);
                if (miPushMessage != null) {
                    Map<String, Object> message = MapUtils.toMap(BundleUtils.convertJSONObject(miPushMessage.toBundle()));
                    PushKit.instance.onMessageClick(PushType.XiaoMi, message);
                }
            } else if (bundleExtras.containsKey("_hw_from") && isSupport(PushType.Huawei)) {
                ///华为
                Map<String, Object> message = new HashMap<>();
                message.put("uriPage", intent.getDataString());
                RemoteMessage remoteMessage = new RemoteMessage(bundleExtras);
                message.put("remoteMessage", RemoteMessageUtils.toMap(remoteMessage));
                Map<String, Object> extras = MapUtils.toMap(BundleUtils.convertJSONObject(bundleExtras));
                message.put("extras", extras);
                PushKit.instance.onMessageClick(PushType.Huawei, message);
            } else if (bundleExtras.containsKey("vivo_push_messageId") && isSupport(PushType.ViVo)) {
                ///vivo
                Map<String, Object> message = MapUtils.toMap(BundleUtils.convertJSONObject(bundleExtras));
                PushKit.instance.onMessageClick(PushType.ViVo, message);
            } else if (isSupport(PushType.Oppo)) {
                ///oppo
                Map<String, Object> message = MapUtils.toMap(BundleUtils.convertJSONObject(bundleExtras));
                PushKit.instance.onMessageClick(PushType.ViVo, message);
            }
        }
    }


    public interface PushListener {


        void onToken(PushType pushType, String token);

        void onMessageClick(PushType pushType, Map<String, Object> message);

    }


    //因为推送服务XMPushService在AndroidManifest.xml中设置为运行在另外一个进程，
    //这导致本Application会被实例化两次，所以我们需要让应用的主进程初始化
    private boolean shouldInit(Context context) {
        //通过ActivityManager我们可以获得系统里正在运行的activities
        //包括进程(Process)等、应用程序/包、服务(Service)、任务(Task)信息。
        ActivityManager am = ((ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE));
        List<ActivityManager.RunningAppProcessInfo> processInfos = am.getRunningAppProcesses();
        String mainProcessName = context.getApplicationInfo().processName;
        int myPid = android.os.Process.myPid();
        for (ActivityManager.RunningAppProcessInfo info : processInfos) {
            //通过比较进程的唯一标识和包名判断进程里是否存在该App
            if (info.pid == myPid && mainProcessName.equals(info.processName)) {
                return true;
            }
        }
        return false;
    }


}
