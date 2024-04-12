package com.lianke.push.xiaomi;


import android.content.Context;
import android.content.Intent;
import android.util.Log;


import com.lianke.push.PushKit;
import com.lianke.push.PushType;
import com.lianke.push.utils.MainThreadUtil;
import com.xiaomi.mipush.sdk.ErrorCode;
import com.xiaomi.mipush.sdk.MiPushClient;
import com.xiaomi.mipush.sdk.MiPushCommandMessage;
import com.xiaomi.mipush.sdk.MiPushMessage;
import com.xiaomi.mipush.sdk.PushMessageHelper;
import com.xiaomi.mipush.sdk.PushMessageReceiver;


import java.util.List;


public class XiaoMiPushMessageReceiver extends PushMessageReceiver {


    @Override
    public void onNotificationMessageArrived(Context context, MiPushMessage miPushMessage) {
    }


    //    当用户点击了自定义通知消息，消息会通过onNotificationMessageClicked方法传到客户端。
//
//    注意：用户点击了预定义通知消息，消息不会通过onNotificationMessageClicked方法传到客户端。
    @Override
    public void onNotificationMessageClicked(Context context, MiPushMessage miPushMessage) {
        try {
            Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                intent.putExtra(PushMessageHelper.KEY_MESSAGE, miPushMessage);
                context.startActivity(intent);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onReceiveRegisterResult(Context context, MiPushCommandMessage message) {
        String command = message.getCommand();
        List<String> arguments = message.getCommandArguments();
        String cmdArg1 = ((arguments != null && arguments.size() > 0) ? arguments.get(0) : null);
        if (MiPushClient.COMMAND_REGISTER.equals(command)) {
            if (message.getResultCode() == ErrorCode.SUCCESS) {
                PushKit.instance.onToken(PushType.XiaoMi, cmdArg1);
            }
        }
    }
}
