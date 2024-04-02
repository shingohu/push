//
//  FlutterApnsSerialization.m
//  push
//
//  Created by Mac_BigSur on 2021/12/2.
//

#import "FlutterApnsSerialization.h"
#import <UserNotifications/UserNotifications.h>

@implementation FlutterApnsSerialization

+ (NSDictionary *)remoteMessageUserInfoToDict:(NSDictionary *)userInfo {
    ///这里不处理了,服务端推什么过来直接返回给业务方,有业务方自己处理
    return userInfo;
}

@end
