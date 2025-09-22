import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'push_types.dart';

///启动消息的回调
typedef void PushMessageHandler(PushType pushType, Map<dynamic, dynamic> message);

///处理token的回调
typedef void PushTokenHandler(PushType pushType, String token);

const String _channelName = 'com.shingo.push';

/// 推送接口，实现常见功能.
class PushConnector {
  final MethodChannel _channel = const MethodChannel(_channelName);

  ///启动
  PushMessageHandler? _onLaunch;

  ///获取token
  PushTokenHandler? _onToken;

  static PushConnector instance = PushConnector._();

  factory PushConnector() {
    return instance;
  }

  PushConnector._() {}

  ///注册
  Future<void> register({required PushMessageHandler onLaunch, required PushTokenHandler onToken}) async {
    _onLaunch = onLaunch;
    _onToken = onToken;
    _channel.setMethodCallHandler(_handleMethod);
    _channel.invokeMethod('register');
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    String method = call.method;
    if (method == "onToken") {
      String tokenValue = call.arguments["token"];
      String type = call.arguments["type"];
      if (coverStringToPushType(type) != null) {
        _onToken?.call(coverStringToPushType(type)!, tokenValue);
      }
    } else if (method == "onLaunch") {
      String type = call.arguments["type"];
      dynamic message = call.arguments["message"];
      if (coverStringToPushType(type) != null) {
        _onLaunch?.call(coverStringToPushType(type)!, _extractMessage(message));
      }
    }
  }

  Map<String, dynamic> _extractMessage(Map map) {
    return Map<String, dynamic>.from(map);
  }

  ///取消注册
  Future<void> unregister() async {
    await _channel.invokeMethod('unregister');
    _onLaunch = null;
    _onToken = null;
  }

  ///打开通知设置(iOS上跳转到设置)
  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid || Platform.isIOS) {
      Completer completer = Completer();

      ///https://gitcode.com/openharmony-tpc/flutter_flutter/issues/1191
      AppLifecycleListener lifecycleListener = AppLifecycleListener(onResume: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await _channel.invokeMethod("openNotificationSettings");
      await completer.future;
      lifecycleListener.dispose();
    } else {
      ///鸿蒙侧认为弹出通知设置页面是应用内弹窗,所有不影响应用的生命周期,也没有通知设置页面关闭事件
      ///所有鸿蒙侧无法根据应用生命周期或者关闭事件来重新获取允许通知开关状态
      await _channel.invokeMethod("openNotificationSettings");
    }
  }

  ///清除所有通知
  Future<void> clearAll() async {
    return _channel.invokeMethod("clearAll");
  }

  ///请求权限(如果请求过则直接返回结果)
  Future<bool> requestPermission() async {
    return await _channel.invokeMethod("requestPermission");
  }
}
