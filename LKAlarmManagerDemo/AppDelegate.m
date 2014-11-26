//
//  AppDelegate.m
//  LKAlarmManagerDemo
//
//  Created by ljh on 14/11/25.
//  Copyright (c) 2014年 Jianghuai Li. All rights reserved.
//

#import "AppDelegate.h"
#import "LKAlarmMamager.h"
#import "ViewController.h"
@interface AppDelegate ()<LKAlarmMamagerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    [[LKAlarmMamager shareManager] didFinishLaunchingWithOptions:launchOptions];
    [[LKAlarmMamager shareManager] registDelegateWithObject:self];

    for (int i=0; i < 100;i++)
    {
        LKAlarmEvent* event = [LKAlarmEvent new];
        event.title = [NSString stringWithFormat:@"我是本地提醒 %d 号",i+1];
        ///强制加入到本地提醒中
        event.isNeedJoinLocalNotify = YES;
        ///60+i*2秒后提醒我
        event.startDate = [NSDate dateWithTimeIntervalSinceNow:60 + (i*2)];
        [[LKAlarmMamager shareManager] addAlarmEvent:event];
    }
    
    LKAlarmEvent* event = [LKAlarmEvent new];
    event.title = @"参试加入日历事件中";
    event.content = @"只有加入到日历当中才有用，是日历中的备注";
    ///工作日提醒
    event.repeatType = LKAlarmRepeatTypeWork;
    ///60秒后提醒我
    event.startDate = [NSDate dateWithTimeIntervalSinceNow:60];
    
    ///会先尝试加入日历  如果日历没权限 会加入到本地提醒中
    [[LKAlarmMamager shareManager] addAlarmEvent:event callback:^(LKAlarmEvent *alarmEvent) {

        dispatch_async(dispatch_get_main_queue(), ^{
            
            UILabel* label =     ((ViewController*)_window.rootViewController).lb_haha;
            if(alarmEvent.isJoinedCalendar)
            {
                label.text = @"已加入日历";
            }
            else if(alarmEvent.isJoinedLocalNotify)
            {
                label.text = @"已加入本地通知";
            }
            else
            {
                label.text = @"加入通知失败";
            }
            
        });
        
    }];
    return YES;
}
-(void)lk_receiveAlarmEvent:(LKAlarmEvent *)event
{
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:@"接受到通知！" message:event.title delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[LKAlarmMamager shareManager] handleOpenURL:url];
    
    return YES;
}
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[LKAlarmMamager shareManager] didReceiveLocalNotification:notification];
}
@end
