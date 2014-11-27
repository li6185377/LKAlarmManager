LKAlarmManager
==============

方便快捷的把 “您的提醒” 加入到 日历或者本地通知中 <br>
会自动处理本地通知超过64个的情况

QQ群号 113767274  有什么问题或者改进的地方大家一起讨论

Requirements
====================================

* iOS 5.0+ 
* ARC only
* LKDBHelper(https://github.com/li6185377/LKDBHelper-SQLite-ORM)

##Adding to your project

If you are using CocoaPods, then, just add this line to your PodFile<br>

```objective-c
pod 'LKAlarmManager', :head
```

##Basic usage

1、把下面三个 UIApplication回调, 传给LKAlarmManager
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    [[LKAlarmMamager shareManager] didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
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
```

2、 加添提醒到 LKAlarmManager 中.
```objective-c
    LKAlarmEvent* event = [LKAlarmEvent new];
    event.title = @"参试加入日历事件中";
    event.content = @"只有加入到日历当中才有用，是日历中的备注";
    ///工作日提醒
    event.repeatType = LKAlarmRepeatTypeWork;
    ///60秒后提醒我
    event.startDate = [NSDate dateWithTimeIntervalSinceNow:60];
    
    ///也可以强制加入到本地提醒中
    //event.isNeedJoinLocalNotify = YES;
    
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
```
3、 注册 LKAlarmManager 回调，接收到提醒的时候 做你想做的事
```objective-c
    ///regist delegate
    [[LKAlarmMamager shareManager] registDelegateWithObject:self];

-(void)lk_receiveAlarmEvent:(LKAlarmEvent *)event
{
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:@"接受到通知！" message:event.title delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}
```
