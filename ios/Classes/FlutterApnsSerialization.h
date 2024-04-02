//
//  FlutterApnsSerialization.h
//  push
//
//  Created by Mac_BigSur on 2021/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Copied from https://github.com/FirebaseExtended/flutterfire/blob/master/packages/firebase_messaging/firebase_messaging/ios/Classes/FLTFirebaseMessagingPlugin.m#L759
@interface FlutterApnsSerialization : NSObject
+ (NSDictionary <NSString*, NSObject*> *)remoteMessageUserInfoToDict:(NSDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
