//
//  CPAppUpdateHelper.h
//  CPAppUpdateHelper
//
//  Created by Parsifal on 16/4/12.
//  Copyright © 2016年 Parsifal. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    kAlertNone,
    kAlertCancel,
    kAlertForce,
} kAlertType;

typedef enum : NSUInteger {
    kLargeVersion,
    kMediumVersion,
    kSmallVersion,
} kVersionCheckType;

typedef void (^kCPBOOLResultBlock)(BOOL result);

@interface CPAppUpdateHelper : NSObject
/**
 * 当前应用的版本号
 **/
+ (NSString *)currentLocalVersion;

/**
 * 缓存的线上版本号
 **/
+ (NSString *)cachedRemoteVersion;

/**
 * 判断应用是否处于审核中
 **/
+ (void)checkReviewStatusWithAppId:(NSString *)appId
                   completionBlock:(kCPBOOLResultBlock)blcok;

/**
 * 打开应用在AppStore中的下载页面
 **/
+ (void)openAppInAppStoreWithAppId:(NSString *)appId;

/**
 * 自动更新检查
 * 例如当前版本2.0.0
 * kVersionCheckedType:kLargeVersion对应只在第一个版本号有更新时提示 kMediumVersion对应只在第二个版本号 kSmallVersion对应第三个版本号
 * kAlertType:kAlertNone对应不弹提示 kAlertOptional对应可选更新 kAlertForced对应强制更新
 **/
+ (void)autoUpdateWithAppId:(NSString *)appId
                  checkType:(kVersionCheckType)checkType
                  alertType:(kAlertType)alertType
            completionBlock:(kCPBOOLResultBlock)blcok;
@end
