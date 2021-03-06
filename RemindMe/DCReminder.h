//
//  DCReminder.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCRecurringInfo.h"

@interface DCReminder : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *nextDueDate;
@property (nonatomic, strong) NSNumber *uid;
@property (nonatomic, strong) DCRecurringInfo *repeatingInfo;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, strong) NSString *notes;

@end
