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
    
    ///重置为0
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [[LKAlarmMamager shareManager] didFinishLaunchingWithOptions:launchOptions];
    
    ///注册下回调
    [[LKAlarmMamager shareManager] registDelegateWithObject:self];
    
    ///本地提醒
    LKAlarmEvent* notifyEvent = [LKAlarmEvent new];
    notifyEvent.title = [NSString stringWithFormat:@"我是本地提醒 %d 号",0];
    ///强制加入到本地提醒中
    notifyEvent.isNeedJoinLocalNotify = YES;
    ///20秒后提醒我
    notifyEvent.startDate = [NSDate dateWithTimeIntervalSinceNow:20];
    
    ///增加推送声音 和 角标
    [notifyEvent setOnCreatingLocalNotification:^(UILocalNotification * localNotification) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    }];
    
    [[LKAlarmMamager shareManager] addAlarmEvent:notifyEvent];
    
    
    
    ///添加到日历
    LKAlarmEvent* calendarEvent = [LKAlarmEvent new];
    calendarEvent.title = @"参试加入日历事件中";
    calendarEvent.content = @"只有加入到日历当中才有用，是日历中的备注";
    ///工作日提醒
    calendarEvent.repeatType = LKAlarmRepeatTypeWork;
    ///60秒后提醒我
    calendarEvent.startDate = [NSDate dateWithTimeIntervalSinceNow:60];
    
    ///会先尝试加入日历  如果日历没权限 会加入到本地提醒中
    [[LKAlarmMamager shareManager] addAlarmEvent:calendarEvent callback:^(LKAlarmEvent *alarmEvent) {

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
    
    
    
    ///用来测试删除的
    LKAlarmEvent* notifyEventNumber2 = [LKAlarmEvent new];
    notifyEventNumber2.title = [NSString stringWithFormat:@"我是本地提醒 %d 号",1];
    ///强制加入到本地提醒中
    notifyEventNumber2.isNeedJoinLocalNotify = YES;
    ///22秒后提醒我
    notifyEventNumber2.startDate = [NSDate dateWithTimeIntervalSinceNow:22];
    
    [[LKAlarmMamager shareManager] addAlarmEvent:notifyEventNumber2];
    
    ///( ⊙ o ⊙ )啊！ 要删除通知啦
    [[LKAlarmMamager shareManager] deleteAlarmEvent:notifyEventNumber2];
    
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
