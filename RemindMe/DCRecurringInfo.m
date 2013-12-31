//
//  DCRecurringInfo.m
//  RemindMe
//
//  Created by Dan Cohn on 12/17/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCRecurringInfo.h"

@implementation DCRecurringInfo

- (id)mutableCopyWithZone:(NSZone *)zone
{
    DCRecurringInfo *copy = [[DCRecurringInfo alloc] init];
    copy.repeats = self.repeats;
    copy.repeatIncrement = self.repeatIncrement;
    copy.repeatFromLastCompletion = self.repeatFromLastCompletion;
    // TODO: daysToRepeat;
    copy.dayOfMonth = self.dayOfMonth;
    copy.nthWeekOfMonth = self.nthWeekOfMonth;

    return copy;
}

@end
