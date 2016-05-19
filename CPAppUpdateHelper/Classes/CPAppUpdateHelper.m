//
//  CPAppUpdateHelper.m
//  CPAppUpdateHelper
//
//  Created by Parsifal on 16/4/12.
//  Copyright © 2016年 Parsifal. All rights reserved.
//

#import "CPAppUpdateHelper.h"

#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...)
#endif

#define kAppLookupURL(appId) [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/cn/lookup?id=%@", appId]]
#define kCPRemoteVersion @"CPRemoteVersion"

@implementation CPAppUpdateHelper

#pragma Public methods
/**
 * 判断应用是否处于审核中
 **/
+ (void)checkReviewStatusWithAppId:(NSString *)appId
                   completionBlock:(kCPBOOLResultBlock)blcok
{
    //这个方法可能被多次调用 这边缓存一个静态变量 一次应用生命周期内 仅检查一次审核状态
    static BOOL CPHasCheckedReviewStatus = NO;
    static BOOL CPIsInReview = NO;
    if (CPHasCheckedReviewStatus) {
        blcok(CPIsInReview);
        return;
    }
    
    NSString *localVersion = [self currentLocalVersion];
    NSURLSession *session = [self createSession];
    
    [[session dataTaskWithURL:kAppLookupURL(appId)
           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
               if (!error) {
                   NSError *serializationError = nil;
                   NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:0
                                                                             error:&serializationError];
                   if (serializationError) {
                       CPIsInReview = NO;
                       NSLog(@"解析数据错误:%@", serializationError);
                   } else {
                       NSDictionary *appInfo = [self appInfoWithResponseJSON:jsonDic];
                       if (appInfo) {
                           NSString *remoteVersion = [self versionWithAppInfo:appInfo];
                           //本地版本比远程版本高 则说明正在审核
                           if ([self compareVersion:localVersion anotherVersion:remoteVersion checkType:kSmallVersion] == NSOrderedDescending) {
                               CPIsInReview = YES;
                           }
                           //缓存下远程版本
                           [self cacheRemoteVersion:remoteVersion];
                       } else {
                           //获取不到app info 则表示iTunes还没有app app还未上线 当做正在审核中处理
                           CPIsInReview = YES;
                       }
                       CPHasCheckedReviewStatus = YES;
                   }
               } else {
                   CPIsInReview = NO;
                   NSLog(@"网络错误:%@", error);
               }
               blcok(CPIsInReview);
           }] resume];
}

/**
 * 打开应用在AppStore中的下载页面
 **/
+ (void)openAppInAppStoreWithAppId:(NSString *)appId
{
    if (appId.length == 0) {
        NSLog(@"不能打开AppStore，因为appID为空!");
        return;
    }
    NSString *str = [NSString stringWithFormat:
                     @"itms-apps://itunes.apple.com/app/id%@", appId];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}

/**
 * 自动更新检查
 * 例如当前版本2.0.0
 * kVersionCheckedType:kLargeVersion对应只在第一个版本号有更新时提示 kMediumVersion对应只在第二个版本号 kSmallVersion对应第三个版本号
 * kAlertType:kAlertNone对应不弹提示 kAlertOptional对应可选更新 kAlertForced对应强制更新
 **/
+ (void)autoUpdateWithAppId:(NSString *)appId
                  checkType:(kVersionCheckType)checkType
                  alertType:(kAlertType)alertType
            completionBlock:(kCPBOOLResultBlock)blcok
{
    __block BOOL needUpdate = NO;
    NSString *localVersion = [self currentLocalVersion];
    NSURLSession *session = [self createSession];
    
    [[session dataTaskWithURL:kAppLookupURL(appId)
            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (!error) {
                    NSError *serializationError = nil;
                    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:0
                                                                              error:&serializationError];
                    if (serializationError) {
                        NSLog(@"解析数据错误:%@", serializationError);
                    } else {
                        NSDictionary *appInfo = [self appInfoWithResponseJSON:jsonDic];
                        if (appInfo) {
                            NSString *remoteVersion = [self versionWithAppInfo:appInfo];
                            NSString *releaseNotes = [NSString stringWithFormat:@"%@", [self releaseNotesWithAppInfo:appInfo]];
                            //远程版本比本地版本高则需要提示更新
                            if ([self compareVersion:localVersion anotherVersion:remoteVersion checkType:checkType] == NSOrderedAscending) {
                                needUpdate = YES;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self showUpdateAlertWithAlertType:alertType
                                                               message:releaseNotes
                                                                 appId:appId];
                                });
                            }
                            [self cacheRemoteVersion:remoteVersion];
                        } else {
                            NSLog(@"iTunes没有app信息");
                        }
                    }
                } else {
                    NSLog(@"网络错误:%@", error);
                }
                blcok(needUpdate);
            }] resume];
}

+ (NSURLSession *)createSession
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    configuration.timeoutIntervalForRequest = 4;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    return session;
}

#pragma mark - Util methods
+ (void)showUpdateAlertWithAlertType:(kAlertType)alertType message:(NSString *)releaseNotes appId:(NSString *)appId
{
    if (alertType == kAlertNone) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"有新版本啦"
                                                                             message:releaseNotes
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"马上更新"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self openAppInAppStoreWithAppId:appId];
                                                             if (alertType == kAlertForce) {
                                                                 [self showUpdateAlertWithAlertType:alertType
                                                                                            message:releaseNotes
                                                                                              appId:appId];
                                                             }
                                                         }];
    [alertController addAction:updateAction];
    switch (alertType) {
        case kAlertCancel:
        {
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"以后再说"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                                                 }];
            [alertController addAction:cancelAction];
            break;
        }
        default:
            break;
    }
    [[self rootViewController] presentViewController:alertController
                                            animated:YES
                                          completion:nil];
}

+ (NSComparisonResult)compareVersion:(NSString *)fVersion anotherVersion:(NSString *)sVersion checkType:(kVersionCheckType)checkType
{
    NSArray *fNumArray = [fVersion componentsSeparatedByString:@"."];
    NSArray *sNumArray = [sVersion componentsSeparatedByString:@"."];
    
    if (fNumArray.count == 0 || sNumArray.count == 0) {
        return NSOrderedSame;
    }
    
    NSString *fNum = fVersion;
    NSString *sNum = sVersion;
    
    switch (checkType) {
        case kLargeVersion:
        {
            fNum = fNumArray.firstObject;
            sNum = sNumArray.firstObject;
            break;
        }
        case kMediumVersion:
        {
            fNum = fNumArray[1];
            sNum = sNumArray[1];
            break;
        }
        default:
            break;
    }
    
    return [fNum compare:sNum options:NSNumericSearch];
}

+ (void)cacheRemoteVersion:(NSString *)remoteVersion
{
    if (remoteVersion.length == 0) {
        NSLog(@"缓存远程版本失败，版本号不能为空");
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:remoteVersion forKey:kCPRemoteVersion];
    [userDefaults synchronize];
}

+ (NSString *)cachedRemoteVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:kCPRemoteVersion];
}

#pragma mark - Setter & Getter methods
+ (UIViewController *)rootViewController
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

+ (NSString *)currentLocalVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSDictionary *)appInfoWithResponseJSON:(NSDictionary *)json
{
    return [json[@"results"] firstObject];
}

+ (NSString *)releaseNotesWithAppInfo:(NSDictionary *)info
{
    return info[@"releaseNotes"];
}

+ (NSString *)versionWithAppInfo:(NSDictionary *)info
{
    return info[@"version"];
}

+ (NSString *)currentVersionReleaseDate:(NSDictionary *)info
{
    return info[@"currentVersionReleaseDate"];
}
@end
