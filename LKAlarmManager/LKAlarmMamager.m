//
//  LKAlarmMamager.m
//  LKAlarmManagerDemo
//
//  Created by ljh on 14/11/25.
//  Copyright (c) 2014年 Jianghuai Li. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import "LKAlarmMamager.h"

@interface LKAlarmDelegateObject : NSObject
@property(weak,nonatomic)id delegate;
@property(nonatomic) Class clazz;
@end

@interface LKAlarmMamager()
@property(nonatomic,strong)NSMutableArray* registDelegates;
@property(strong,nonatomic)NSLock* checkLocalNotifyLock;
@property BOOL isExecuteCheckNotifyCallback;
@end

@implementation LKAlarmMamager
+(instancetype)shareManager
{
    static LKAlarmMamager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
#pragma mark- base
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.registDelegates = [NSMutableArray array];
        
        NSDictionary* dic = [[NSBundle mainBundle] infoDictionary];
        NSArray* array = [dic objectForKey:@"CFBundleURLTypes"];
        NSDictionary* urlTypes = [array lastObject];
        NSArray* urlSchemes = urlTypes[@"CFBundleURLSchemes"];
        self.urlSchemes = [urlSchemes lastObject];
        
        self.checkLocalNotifyLock = [[NSLock alloc]init];
        [self checkLocalNotifyEvent];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)applicationDidBecomeActive
{
    [self checkNeedCallbackNotifyEvent];
}
-(void)registDelegateWithClass:(Class<LKAlarmMamagerDelegate>)clazz
{
    LKAlarmDelegateObject* obj =[LKAlarmDelegateObject new];
    obj.clazz = clazz;
    [_registDelegates addObject:obj];
}
-(void)registDelegateWithObject:(id<LKAlarmMamagerDelegate>)delegate
{
    LKAlarmDelegateObject* obj =[LKAlarmDelegateObject new];
    obj.delegate = delegate;
    [_registDelegates addObject:obj];
}


-(NSArray *)allEvents
{
    return [LKAlarmEvent searchWithWhere:nil orderBy:@"eventId desc" offset:0 count:0];
}
-(NSArray *)allNoReceiveEvents
{
    NSMutableArray* events = [LKAlarmEvent searchWithWhere:[NSString stringWithFormat:@"startDate > '%@'",[LKDBUtils stringWithDate:[NSDate date]]] orderBy:@"eventId" offset:0 count:0];
    return events;
}
#pragma mark- check alarm event status
-(void)checkLocalNotifyEvent
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
        if([self.checkLocalNotifyLock tryLock])
        {
            [self checkLocalNotifyEvent_async];
            [self.checkLocalNotifyLock unlock];
        }
    });
}
-(void)checkLocalNotifyEvent_async
{
   NSArray* array = [LKAlarmEvent searchWithWhere:@"isNeedJoinLocalNotify=1 and isJoinedLocalNotify=0" orderBy:@"startDate" offset:0 count:0];
    for (LKAlarmEvent* event in array)
    {
        [self pushToLocalNotify:event];
    }
}


-(void)checkNeedCallbackNotifyEvent
{
    if(_isExecuteCheckNotifyCallback)
        return;
    
    _isExecuteCheckNotifyCallback = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        [self checkNeedCallbackNotifyEvent_async];
    });
}
-(void)checkNeedCallbackNotifyEvent_async
{
    NSString* where = [NSString stringWithFormat:@"startDate<='%@' and alermDidCallbacked=0",[LKDBUtils stringWithDate:[NSDate date]]];
    NSArray* array = [LKAlarmEvent searchWithWhere:where orderBy:@"startDate" offset:0 count:0];
    for (LKAlarmEvent* event in array)
    {
        [self sendReceveEvent:event];
    }
    _isExecuteCheckNotifyCallback = NO;
}

#pragma mark- receive alarm
-(void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UILocalNotification *localNotify = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotify)
    {
        [self didReceiveLocalNotification:localNotify];
    }
    else
    {
        [self checkNeedCallbackNotifyEvent];
    }
}
-(void)didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString* eventParams = [notification.userInfo objectForKey:@"lk_alarm_id"];
    NSInteger alarmId = eventParams.integerValue;
    [self sendReceveEventWithID:alarmId];
}
-(void)handleOpenURL:(NSURL *)url
{
    NSArray* params = [url.absoluteString componentsSeparatedByString:@"://"];
    NSString* eventParams = [params lastObject];
    if([eventParams hasPrefix:@"lk_alarm_id="])
    {
        NSInteger alarmId = [[[eventParams componentsSeparatedByString:@"="] lastObject] integerValue];
        [self sendReceveEventWithID:alarmId];
    }
}
-(void)sendReceveEventWithID:(NSInteger)eventId
{
    if(eventId > 0)
    {
        LKAlarmEvent* event = [LKAlarmEvent searchSingleWithWhere:[NSString stringWithFormat:@"eventId=%ld",(long)eventId] orderBy:nil];
        if (event)
        {
            [self sendReceveEvent:event];
        }
    }
}

-(void)sendReceveEvent:(LKAlarmEvent*)event
{
    if([NSThread isMainThread])
    {
        [self sendReceveEvent_mainThread:event];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendReceveEvent_mainThread:event];
        });
    }
}
-(void)sendReceveEvent_mainThread:(LKAlarmEvent*)event
{
    for (LKAlarmDelegateObject* obj in _registDelegates)
    {
        if (obj.delegate)
        {
            [obj.delegate lk_receiveAlarmEvent:event];
        }
        if(obj.clazz)
        {
            [obj.clazz lk_receiveAlarmEvent:event];
        }
    }
    [event setValue:@YES forKey:@"alermDidCallbacked"];
    [LKAlarmEvent updateToDBWithSet:@"alermDidCallbacked=1" where:@"eventId=%ld",event.eventId];
    
    [self checkLocalNotifyEvent];
}


#pragma mark- add alarm
-(void)addAlarmEvent:(LKAlarmEvent *)event
{
    [self addAlarmEvent:event callback:nil];
}
-(void)addAlarmEvent:(LKAlarmEvent *)event callback:(void (^)(LKAlarmEvent *))callback
{
    if(event.startDate == nil)
    {
        NSLog(@"添加提醒失败~ 因为没有开始时间");
        return;
    }
    if(event.eventId == 0)
    {
        [event saveToDB];
    }
    
    if(event.isNeedJoinLocalNotify)
    {
        [self pushToLocalNotify:event];
        if(callback)
        {
            callback(event);
        }
    }
    else
    {
        __weak LKAlarmMamager* wself = self;
        EKEventStore *ekEventStore = [[EKEventStore alloc] init];
        [ekEventStore requestAccessToEntityType:EKEntityTypeEvent
                                     completion:^(BOOL granted, NSError *kError)
         {
             __strong LKAlarmMamager* sself = wself;
             if (granted)
             {
                 [sself pushToCalednar:event eventStore:ekEventStore];
             }
             else
             {
                 [sself pushToLocalNotify:event];
             }
             if(callback)
             {
                 callback(event);
             }
         }];
    }
}
-(void)pushToCalednar:(LKAlarmEvent*)event eventStore:(EKEventStore*)eventStore
{
    EKEvent *ekEvent = nil;
    if (event.eventIdentifier.length > 0)
    {
        ekEvent = [eventStore eventWithIdentifier:event.eventIdentifier];
    }
    if(ekEvent == nil)
    {
        ekEvent = [EKEvent eventWithEventStore:eventStore];
    }
    
    ekEvent.title = event.title;
    ekEvent.notes = event.content;
    ekEvent.startDate = event.startDate;
    if(event.endDate)
    {
        ekEvent.endDate = event.endDate;
    }
    else
    {
        ekEvent.endDate = [ekEvent.startDate dateByAddingTimeInterval:60*60];
    }
    
    if(self.urlSchemes.length > 0 && [UIDevice currentDevice].systemVersion.floatValue >= 5)
    {
        NSString* URL = [self.urlSchemes stringByAppendingFormat:@"://lk_alarm_id=%ld",(long)event.eventId];
        [event setValue:URL forKey:@"URL"];
        ekEvent.URL = [NSURL URLWithString:URL];
    }
    if(event.beforeTime > 0)
    {
        [ekEvent addAlarm:[EKAlarm alarmWithRelativeOffset:event.beforeTime]];
    }
    else
    {
        [ekEvent addAlarm:[EKAlarm alarmWithRelativeOffset:0]];
    }
    if(event.repeatType > 0)
    {
        EKRecurrenceRule* rule = nil;
        switch (event.repeatType) {
            case LKAlarmRepeatTypeDay:
            {
                rule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil];
                   break;
            }
             
            case LKAlarmRepeatTypeWeek:
            {
                rule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil];
                break;
            }
            case LKAlarmRepeatTypeWork:
            {
                rule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1
                                                              daysOfTheWeek:@[[EKRecurrenceDayOfWeek dayOfWeek:EKMonday],
                                                                              [EKRecurrenceDayOfWeek dayOfWeek:EKTuesday],
                                                                              [EKRecurrenceDayOfWeek dayOfWeek:EKWednesday],
                                                                              [EKRecurrenceDayOfWeek dayOfWeek:EKThursday],
                                                                              [EKRecurrenceDayOfWeek dayOfWeek:EKFriday]]
                                                             daysOfTheMonth:nil monthsOfTheYear:nil weeksOfTheYear:nil daysOfTheYear:nil setPositions:nil end:nil];

                break;
            }
        }
        [ekEvent addRecurrenceRule:rule];
    }
    
    ekEvent.location = event.location;
    if(event.timeZoneName.length > 0)
    {
        ekEvent.timeZone = [NSTimeZone timeZoneWithName:event.timeZoneName];
    }
    
    [ekEvent setCalendar:[eventStore defaultCalendarForNewEvents]];
    
    NSError *error = nil;
    BOOL success = [eventStore saveEvent:ekEvent span:EKSpanThisEvent error:&error];
    if(error)
    {
        NSLog(@"%@",error.debugDescription);
    }
    if(success)
    {
        [event setValue:@YES forKey:@"isJoinedCalendar"];
        [event setValue:ekEvent.eventIdentifier forKey:@"eventIdentifier"];
        [event saveToDB];
    }
    else
    {
        [self pushToLocalNotify:event];
    }
}
-(void)pushToLocalNotify:(LKAlarmEvent*)event
{
    ///是需要加入到本地推送的
    event.isNeedJoinLocalNotify = YES;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8)
    {        
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    NSArray* localNotify = [[UIApplication sharedApplication] scheduledLocalNotifications];
    UILocalNotification* lastFireNotify = nil;
    BOOL isMaxNotify = (localNotify.count >=64);
    
    for (UILocalNotification* notify in localNotify)
    {
        NSInteger event_id = [notify.userInfo[@"lk_alarm_id"] integerValue];
        if(event_id > 0)
        {
            if(event.eventId == event_id)
            {
                lastFireNotify = nil;
                [[UIApplication sharedApplication] cancelLocalNotification:notify];
                break;
            }
            if(isMaxNotify)
            {
                if(lastFireNotify == nil || [lastFireNotify.fireDate compare:notify.fireDate] == NSOrderedAscending)
                {
                    lastFireNotify = notify;
                }
            }
        }
    }
    
    NSDate* fireDate = event.startDate;
    if(event.beforeTime > 0)
    {
        fireDate = [fireDate dateByAddingTimeInterval:-event.beforeTime];
    }
    if(lastFireNotify)
    {
        if([lastFireNotify.fireDate compare:fireDate] == NSOrderedAscending)
        {
            ///加入失败
            NSLog(@"本地通知超过64个 没法再加入了....");
            
            [event setValue:@NO forKey:@"isJoinedLocalNotify"];
            [event saveToDB];
            
            return;
        }
        else
        {
            ///把最后一个通知挤掉
            [[UIApplication sharedApplication] cancelLocalNotification:lastFireNotify];
            NSInteger event_id = [lastFireNotify.userInfo[@"lk_alarm_id"] integerValue];
            [LKAlarmEvent updateToDBWithSet:@"isJoinedLocalNotify=0" where:@"eventId=%d",event_id];
        }
    }
    
    UILocalNotification* notify = [[UILocalNotification alloc]init];
    
    notify.fireDate = fireDate;
    notify.alertBody = event.title;
    notify.repeatInterval = (NSCalendarUnit)event.repeatType;
    notify.userInfo = @{@"lk_alarm_id":@(event.eventId)};
    if(event.onCreatingLocalNotification)
    {
        event.onCreatingLocalNotification(notify);
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:notify];
    
    [event setValue:@YES forKey:@"isJoinedLocalNotify"];
    [event saveToDB];
}

#pragma mark- delete 
-(void)deleteAlarmEvent:(LKAlarmEvent *)event
{
    if(event.isJoinedCalendar)
    {
        EKEventStore *ekEventStore = [[EKEventStore alloc] init];
        EKEvent* ekEvent = [ekEventStore eventWithIdentifier:event.eventIdentifier];
        [ekEventStore removeEvent:ekEvent span:EKSpanThisEvent error:nil];
    }
    if(event.isJoinedLocalNotify)
    {
        NSArray* localNotifys = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification* local in localNotifys)
        {
            NSInteger eventId = [local.userInfo[@"lk_alarm_id"] integerValue];
            if(eventId > 0 && eventId == event.eventId)
            {
                [[UIApplication sharedApplication] cancelLocalNotification:local];
                break;
            }
        }
    }
    [event deleteToDB];
}
-(void)deleteNoReceiveAlarmEvents
{
    NSArray* events = [self allNoReceiveEvents];
    EKEventStore *ekEventStore = nil;
    for (int i=0; i < events.count; i++)
    {
        LKAlarmEvent* event = events[i];
        if(event.isJoinedCalendar)
        {
            if (ekEventStore == nil)
            {
                ekEventStore = [[EKEventStore alloc] init];
            }
            
            EKEvent* ekEvent = [ekEventStore eventWithIdentifier:event.eventIdentifier];
            [ekEventStore removeEvent:ekEvent span:EKSpanThisEvent error:nil];
        }
        [event deleteToDB];
    }
    
    NSArray* localNotifys = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification* local in localNotifys)
    {
        NSInteger eventId = [local.userInfo[@"lk_alarm_id"] integerValue];
        if(eventId > 0)
        {
            [[UIApplication sharedApplication] cancelLocalNotification:local];
        }
    }
}

@end

@implementation LKAlarmDelegateObject
@end