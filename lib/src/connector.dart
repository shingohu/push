import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'push_types.dart';

///启动消息的回调
typedef void PushMessageHandler(
    PushType pushType, Map<dynamic, dynamic> message);

///处理token的回调
typedef void PushTokenHandler(PushType pushType, String token);

const String _channelName = 'com.lianke.push';

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
  Future<void> register(
      {required PushMessageHandler onLaunch,
      required PushTokenHandler onToken}) async {
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
    clearAll();
    await _channel.invokeMethod('unregister');
    _onLaunch = null;
    _onToken = null;
  }

  ///打开通知设置(iOS上跳转到设置)
  Future<void> openNotificationSettings() async {
    Completer completer = Completer();
    AppLifecycleListener lifecycleListener = AppLifecycleListener(onResume: () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await _channel.invokeMethod("openNotificationSettings");
    await completer.future;
    lifecycleListener.dispose();
  }

  ///清除所有通知
  Future<void> clearAll() async {
    _channel.invokeMethod("clearAll");
  }

  ///检查是否授权(android13 以及iOS未请求权限之前都是false)
  Future<bool> get isPermissionGranted async {
    return await _channel.invokeMethod("checkPermission");
  }

  ///请求权限(如果请求过则直接返回结果)
  Future<bool> requestPermission() async {
    return await _channel.invokeMethod("requestPermission");
  }
}
