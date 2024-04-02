import Flutter
import UserNotifications
import HmsPushSdk



func getFlutterError(_ error: Error) -> FlutterError {
    let e = error as NSError
    return FlutterError(code: "Error: \(e.code)", message: e.domain, details: error.localizedDescription)
}

@objc public class PushPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    internal init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.lianke.push", binaryMessenger: registrar.messenger())
        let instance = PushPlugin(channel: channel)
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let channel: FlutterMethodChannel
    var launchNotification: [String: Any]?
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "register":
            if #available(iOS 10.0, *) {
                assert(
                    UNUserNotificationCenter.current().delegate != nil,
                    "UNUserNotificationCenter.current().delegate is not set. Check readme at https://pub.dev/packages/flutter_apns."
                )
            } else {
                // Fallback on earlier versions
            }
            UIApplication.shared.registerForRemoteNotifications()
            
            // check for onLaunch notification *after* configure has been ran
            if let launchNotification = launchNotification {
                onLaunch(userInfo: launchNotification)
                self.launchNotification = nil
                return
            }
            result(nil)
    
        case "hasPermission":
            checkPermission(result: result)
        case "requestPermission":
            requestPermission(result:result)
        case "unregister":
            UIApplication.shared.unregisterForRemoteNotifications()
            result(nil)
        case "openNotificationSettings":
            openNotificationSettings()
            result(nil)
            
        case "clearAll":
            
            // 即将收到的
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                // 已经收到的
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            result(nil)
        default:
            assertionFailure(call.method)
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    func openNotificationSettings(){
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
               return
           }
           
           if #available(iOS 10.0, *) {
               UIApplication.shared.open(url, options: [:], completionHandler: nil)
           } else {
               UIApplication.shared.openURL(url)
           }

    }
    
    
    
    ///判断通知权限
    func checkPermission(result: @escaping FlutterResult){
        UNUserNotificationCenter.current().getNotificationSettings {  (settings) in
            let status = settings.authorizationStatus
            if(status == .denied){
                result(false)
            }else if(status == .notDetermined){
                result(false)
            }else{
                result(true)
            }
            
        }
    }
   
    
    func requestPermission(result: @escaping FlutterResult){
    
        UNUserNotificationCenter.current().getNotificationSettings {  (settings) in
            let status = settings.authorizationStatus
            if(status == .denied){
                result(false)
            }else if(status == .notDetermined){
                let center = UNUserNotificationCenter.current()
                
                var options = [UNAuthorizationOptions]()
                
                
                options.append(.sound)
              
                options.append(.badge)
               
                options.append(.alert)
                
                
                let optionsUnion = UNAuthorizationOptions(options)
                
                center.requestAuthorization(options: optionsUnion) { (granted, error)  in
                    if(granted){
                        result(true)
                    }else{
                        result(false)
                    }
                }
            }else{
                result(true)
            }
            
        }
        
        
     
    }
    
    
    //MARK:  - AppDelegate
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        if let launchNotification = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any] {
            self.launchNotification = FlutterApnsSerialization.remoteMessageUserInfo(toDict: launchNotification)
        }
        return true
    }
    
 
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        var deviceTokenString = "" ;
        
        // 判断iOS设备版本
           if #available(iOS 13.0, *)  {
               var deviceTokenString1 = String()
               let bytes = [UInt8](deviceToken)
               for item in bytes {
                   deviceTokenString1 += String(format: "%02x", item & 0x000000FF)
               }
               deviceTokenString = deviceTokenString1;
           } else {
               deviceTokenString = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
            
           }
        
        
        /// covert to huawei push
        
        var huaweitoken = HmsInstanceId.getInstance().getToken(deviceTokenString)
        
        channel.invokeMethod("onToken", arguments: [
            "token":huaweitoken,
            "type":"APNS"
        ])
    }
    
    
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //when notification receive on foreground
        
        let userInfo = notification.request.content.userInfo
        
        guard userInfo["aps"] != nil else {
            return
        }
        
        let dict = FlutterApnsSerialization.remoteMessageUserInfo(toDict: userInfo)
        
        channel.invokeMethod("willPresent", arguments: dict) { (result) in
            let shouldShow = (result as? Bool) ?? false
            if shouldShow {
                ///在前台弹出
                completionHandler([.alert, .sound])
            } else {
                completionHandler([])
            }
        }
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
     
        //when notification click
        var userInfo = response.notification.request.content.userInfo
        guard userInfo["aps"] != nil else {
            return
        }
        
        userInfo["actionIdentifier"] = response.actionIdentifier
        let dict = FlutterApnsSerialization.remoteMessageUserInfo(toDict: userInfo)
        
        if launchNotification != nil {
            launchNotification = dict
            return
        }
        
        onLaunch(userInfo: dict)
        completionHandler()
    }
    
    func onLaunch(userInfo: [AnyHashable: Any]) {
        channel.invokeMethod("onLaunch", arguments: [
            "type":"APNS",
            "message":userInfo
        ])
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
