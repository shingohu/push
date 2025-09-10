import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  NewWantListener,
} from '@ohos/flutter_ohos';

import { notificationManager } from '@kit.NotificationKit';
import { pushService } from '@kit.PushKit';
import { AbilityConstant, common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/** PushPlugin **/
export default class PushPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware, NewWantListener {
  private channel: MethodChannel | null = null
  private context: common.UIAbilityContext | null = null
  private launchParameters: Record<string, Object> | null | undefined = null
  private hasRegister: boolean = false
  private abilityBinding: AbilityPluginBinding | null = null

  constructor() {
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    if (want.parameters) {
      this.launchParameters = want.parameters
      this.onLaunchAbility(this.launchParameters)
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityBinding = binding
    this.context = binding.getAbility().context
    this.launchParameters = binding.getAbility().launchWant.parameters
    binding.addOnNewWantListener(this)
  }

  onDetachedFromAbility(): void {
    this.context = null
    this.launchParameters = null
    this.abilityBinding?.removeOnNewWantListener(this)
    this.abilityBinding = null
  }


  onLaunchAbility(parameters: Record<string, Object>) {
    if (parameters["_push_notifyid"]) {
        if(this.hasRegister){
              hilog.info(0x0000, 'PushKit', `Launch Parameters ${JSON.stringify(parameters)}`);
              this.channel?.invokeMethod("onLaunch", {
                "type": "HarmonyOS",
                "message": parameters
              })
              this.launchParameters = null
          }
    }else{
        this.launchParameters = null
    }

  }

  getUniqueClassName(): string {
    return "PushPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.shingo.push");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null
    }
  }


  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "requestPermission") {
      this.requestPermission(result)
    } else if (call.method == "openNotificationSettings") {
      if (this.context) {
        notificationManager.openNotificationSettings(this.context).then(() => {
          hilog.info(0x0000, 'PushKit', `[ANS] openNotificationSettings success`);
          result.success(true)
        }).catch((err: BusinessError) => {
          hilog.error(0x0000, 'PushKit',
            `[ANS] openNotificationSettings failed, code is ${err.code}, message is ${err.message}`);
          result.success(false)
        });
      }
    } else if (call.method == "clearAll") {
      notificationManager.cancelAll();
      result.success(true)
    } else if (call.method == "register") {
      this.register()
      result.success(true)
      if (this.launchParameters) {
        this.onLaunchAbility(this.launchParameters)
      }
    } else if (call.method == "unregister") {
      this.unregister()
      result.success(true)
    } else {
      result.notImplemented()
    }
  }

  async register() {
    try {
      this.hasRegister = true
      const pushToken: string = await pushService.getToken();
      this.channel?.invokeMethod("onToken", {
        "type": "HarmonyOS",
        "token": pushToken
      });
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'PushKit', 'Failed to get push token: %{public}d %{public}s', e.code, e.message);
    }
  }

  async unregister() {
    try {
      this.hasRegister = false
      this.launchParameters = null
      await pushService.deleteToken();
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'PushKit', 'Failed to delete push token: %{public}d %{public}s', e.code, e.message)
    }
  }


  ///请求通知权限
  async requestPermission(result: MethodResult) {
    const enable = notificationManager.isNotificationEnabledSync();
    if (enable) {
      result.success(true)
    } else {
      if (this.context) {
        try {
          await notificationManager.requestEnableNotification(this.context)
          result.success(notificationManager.isNotificationEnabledSync())
        } catch (e) {
          result.success(false)
        }
      } else {
        result.success(false)
      }
    }
  }
}