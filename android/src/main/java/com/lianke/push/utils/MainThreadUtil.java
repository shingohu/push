package com.lianke.push.utils;

import android.os.Handler;
import android.os.Looper;

public class MainThreadUtil {
    private final static Handler MAIN_HANDLER = new Handler(Looper.getMainLooper());

    public static void runMainThread(Runnable runnable) {
        MAIN_HANDLER.post(runnable);
    }
}
