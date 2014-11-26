//
//  LKAlarmEvent.h
//  LKAlarmManagerDemo
//
//  Created by ljh on 14/11/25.
//  Copyright (c) 2014年 Jianghuai Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LKDBHelper.h>

typedef NS_ENUM(NSUInteger, LKAlarmRepeatType) {
    ///每天重复
    LKAlarmRepeatTypeDay = NSCalendarUnitDay,
    ///每周重复
    LKAlarmRepeatTypeWeek = NSCalendarUnitWeekday,
    ///工作日重复
    LKAlarmRepeatTypeWork = NSCalendarUnitWeekdayOrdinal
};

@interface LKAlarmEvent : NSObject
///LK中的事件id 自增 只有保存完数据库 才会有值
@property (assign,readonly,nonatomic) NSInteger eventId;
///标题
@property (strong,nonatomic) NSString *title;
///内容
@property (strong,nonatomic) NSString *content;
///开始时间
@property (strong,nonatomic) NSDate *startDate;
///结束时间 如果没有默认1小时
@property (strong,nonatomic) NSDate *endDate;
///开始时间前 几秒提醒
@property NSInteger beforeTime;
///地区
@property(strong,nonatomic) NSString *location;
///时区
@property(strong,nonatomic) NSTimeZone *timeZone;

///重复模式
@property LKAlarmRepeatType repeatType;


///只要加入本地推送 可设为YES 就不会添加到日历当中
@property(nonatomic) BOOL isNeedJoinLocalNotify;
///是否加入到本地推送当中
@property(assign,readonly,nonatomic) BOOL isJoinedLocalNotify;


///是否加入到日历当中
@property(assign,readonly,nonatomic) BOOL isJoinedCalendar;
///EKEvent eventIdentifier 加入到日历中的唯一标识码
@property (strong,readonly,nonatomic) NSString *eventIdentifier;
///日历中显示的URL 为了点击跳转到应用当中
@property(strong,readonly,nonatomic)NSString* URL;

@end
