package com.shingo.push.huawei;

import android.os.Bundle;
import android.text.TextUtils;

import com.huawei.hms.push.HmsMessageService;
import com.shingo.push.PushKit;
import com.shingo.push.PushType;

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
