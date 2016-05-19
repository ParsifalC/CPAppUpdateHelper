//
//  ViewController.m
//  CPAppUpdateHelper
//
//  Created by Parsifal on 16/4/12.
//  Copyright © 2016年 Parsifal. All rights reserved.
//

#import "ViewController.h"
#import "CPAppUpdateHelper.h"

@interface ViewController ()

@end

#define kAppId @"414478124"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //修改bundle version 进行测试
}

#pragma mark - Action methods
- (IBAction)checkReviewStatusBtnTapped:(UIButton *)sender
{
    [CPAppUpdateHelper checkReviewStatusWithAppId:kAppId
                                  completionBlock:^(BOOL isInReview) {
                                      NSLog(@"InReview:%@", @(isInReview));
                                  }];
}

- (IBAction)openInAppStoreBtnTapped:(UIButton *)sender
{
    [CPAppUpdateHelper openAppInAppStoreWithAppId:kAppId];
}

- (IBAction)checkNewVersionBtnTapped:(UIButton *)sender
{
    [CPAppUpdateHelper autoUpdateWithAppId:kAppId
                                 checkType:kSmallVersion
                                 alertType:kAlertForce
                           completionBlock:^(BOOL needUpdate) {
                               NSString *currentVersion = [CPAppUpdateHelper currentLocalVersion];
                               NSString *remoteVersion = [CPAppUpdateHelper cachedRemoteVersion];
                               NSLog(@"NeedUpdate:%@ RemoteVersion:%@ CurrentVersion:%@", @(needUpdate), remoteVersion, currentVersion);
                           }];
}
@end
