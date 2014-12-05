//
//  LKAlarmMamager.h
//  LKAlarmManagerDemo
//
//  Created by ljh on 14/11/25.
//  Copyright (c) 2014年 Jianghuai Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LKAlarmEvent.h"

@class UILocalNotification;

@protocol LKAlarmMamagerDelegate
@optional
+(void)lk_receiveAlarmEvent:(LKAlarmEvent*)event;
-(void)lk_receiveAlarmEvent:(LKAlarmEvent*)event;
@end

///会先参试给日历加事件  如果用户不同意则用UILocalNotification
@interface LKAlarmMamager : NSObject
+(instancetype)shareManager;

///应用的 schemes  会先自动读info.plist中的数据  可手动修改
@property(strong,nonatomic)NSString* urlSchemes;

/**
 *  @brief  判断是否点击本地通知启动应用
        请在 AppDelegate.m 中 
        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
        方法内调用
 *
 */
- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/**
    @brief  判断是否点击URL进来
    请在 AppDelegate.m 中
    -(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
    方法内调用
 *
 */
- (void)handleOpenURL:(NSURL *)url;

/**
 @brief  判断是否点击本地通知进来
 请在 AppDelegate.m 中
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
 方法内调用
 *
 */
-(void)didReceiveLocalNotification:(UILocalNotification *)notification;


///对象 调用  实例方法 -(void)lk_receiveAlarmEvent:(LKAlarmEvent*)event;
-(void)registDelegateWithObject:(id)delegate;
///class 调用 静态方法+(void)lk_receiveAlarmEvent:(LKAlarmEvent*)event;
-(void)registDelegateWithClass:(Class)clazz;

///添加通知事件 当isNeedJoinLocalNotify 为YES时 只添加到本地通知中
-(void)addAlarmEvent:(LKAlarmEvent*)event;
-(void)addAlarmEvent:(LKAlarmEvent*)event callback:(void(^)(LKAlarmEvent* alarmEvent))callback;

///删除通知事件 同时会删除日历或本地通知 内 对应的提醒
-(void)deleteAlarmEvent:(LKAlarmEvent*)event;

///删除所有没有触发的事件
-(void)deleteNoReceiveAlarmEvents;


///所有的通知事件
-(NSArray*)allEvents;

///还没有到提醒时间的通知事件
-(NSArray*)allNoReceiveEvents;
@end