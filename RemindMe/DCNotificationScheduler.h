//
//  DCNotificationScheduler.h
//  RemindMe
//
//  Created by Dan Cohn on 1/2/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCReminder.h"

@interface DCNotificationScheduler : NSObject

+ (DCNotificationScheduler *)sharedInstance;
- (void)scheduleNotificationForReminder:(DCReminder *)reminder;
- (void)clearNotificationForReminder:(DCReminder *)reminder;
- (void)recreateNotifications;

@end
