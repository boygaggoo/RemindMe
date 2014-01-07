//
//  DCNotificationScheduler.m
//  RemindMe
//
//  Created by Dan Cohn on 1/2/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "DCNotificationScheduler.h"
#import "DataModel.h"
#import "NSDate+Helpers.h"

@implementation DCNotificationScheduler

static DCNotificationScheduler *schedulerInstance;

+ (DCNotificationScheduler *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        schedulerInstance = [[self alloc] init];
    });
    
    return schedulerInstance;
}

- (void)createLocalNotification:(DCReminder *)reminder
{
    // No need to create a notification for dates in the past
    if ( [reminder.nextDueDate dc_isDateBefore:[NSDate date]] )
        return;
    
    // Create new notification
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = reminder.nextDueDate;
    notification.timeZone = [NSTimeZone localTimeZone];
    NSString *alertBody = [@"Reminder: " stringByAppendingString:reminder.name];
    NSString *alertAction = @"alert action";
    notification.alertBody = alertBody;
    notification.alertAction = alertAction;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.userInfo = [NSDictionary dictionaryWithObject:reminder.uid forKey:@"reminderid"];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)scheduleNotificationForReminder:(DCReminder *)reminder
{
    // Remove existing notificaiton if it exists
    [self clearNotificationForReminder:reminder];
    
    // Create the notification and schedule it
    [self createLocalNotification:reminder];
    
    // Update the badge number for each notification
    [self resetBadgeNumbersForNotifications];
}

- (void)clearNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)clearNotificationForReminder:(DCReminder *)reminder
{
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for ( UILocalNotification *local in notifications )
    {
        if ( [local.userInfo[@"reminderid"] isEqualToNumber:reminder.uid] )
        {
            [[UIApplication sharedApplication] cancelLocalNotification:local];
            [self resetBadgeNumbersForNotifications];
        }
    }
}

- (void)resetBadgeNumbersForNotifications
{
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"fireDate" ascending:YES];
    NSArray *unsortedNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    NSArray *sortedNotifications = [unsortedNotifications sortedArrayUsingDescriptors:@[sort]];
    // Next badge number will be number currently over due, plus 1
    NSInteger badgeNumber = [[DataModel sharedInstance] numDueBefore:[NSDate date]] + 1;
    
    for ( UILocalNotification *local in sortedNotifications )
    {
        local.applicationIconBadgeNumber = badgeNumber++;
    }
    
    [UIApplication sharedApplication].scheduledLocalNotifications = sortedNotifications;
}

- (void)recreateNotifications
{
    [self clearNotifications];
    NSDate *now = [NSDate date];
    
    for ( NSInteger index = 0; index < [[DataModel sharedInstance] numItems]; index++ )
    {
        DCReminder *reminder = [[DataModel sharedInstance] reminderAtIndex:index];
        if ( [reminder.nextDueDate dc_isDateBefore:now] )
        {
            continue;
        }
        
        [self createLocalNotification:reminder];
    }
    
    [self resetBadgeNumbersForNotifications];
}

@end
