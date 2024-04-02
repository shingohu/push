package com.lianke.push.huawei;

import android.os.Bundle;
import android.text.TextUtils;

import com.huawei.hms.push.HmsMessageService;
import com.lianke.push.PushKit;
import com.lianke.push.PushType;
import com.lianke.push.utils.MainThreadUtil;

public class HuaweiPushMessageService extends HmsMessageService {

    @Override
    public void onNewToken(String token, Bundle bundle) {
    }

    @Override
    public void onNewToken(String token) {
        if (!TextUtils.isEmpty(token)) {
            PushKit.instance.onToken(PushType.Huawei, token);
        }
    }
}
