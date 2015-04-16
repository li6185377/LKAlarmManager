//
//  LKAlarmEvent.h
//  LKAlarmManagerDemo
//
//  Created by ljh on 14/11/25.
//  Copyright (c) 2014年 Jianghuai Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LKDBHelper.h>

typedef NS_ENUM(NSUInteger, LKAlarmRepeatType) {
    ///每天重复
    LKAlarmRepeatTypeDay = NSCalendarUnitDay,
    ///每周重复
    LKAlarmRepeatTypeWeek = NSCalendarUnitWeekday,
    ///工作日重复
    LKAlarmRepeatTypeWork = NSCalendarUnitWeekdayOrdinal
    ///如有其他需求 咕~~(╯﹏╰)b。。。 自己去改改代码吧
};

/**
 *  @brief  你可以继承此对象 然后增添属性来保存需要的数据
 */
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
@property(strong,nonatomic) NSString *timeZoneName;

///是否发送过回调  如果没法送过回调 应用进来时间到的话  会自动触发
@property(assign,readonly,nonatomic) BOOL alermDidCallbacked;

///重复模式
@property LKAlarmRepeatType repeatType;

///您可能需要用来保存什么值 比如某任务的id
@property NSInteger eventTag;

///只要加入本地推送 可设为YES 就不会添加到日历当中
@property(nonatomic) BOOL isNeedJoinLocalNotify;
///是否加入到本地推送当中
@property(assign,readonly,nonatomic) BOOL isJoinedLocalNotify;

@property(copy,nonatomic)void(^onCreatingLocalNotification)(UILocalNotification* localNotification);

///是否加入到日历当中
@property(assign,readonly,nonatomic) BOOL isJoinedCalendar;
///EKEvent eventIdentifier 加入到日历中的唯一标识码
@property(strong,readonly,nonatomic) NSString *eventIdentifier;
///日历中显示的URL 为了点击跳转到应用当中
@property(strong,readonly,nonatomic) NSString* URL;

@end
