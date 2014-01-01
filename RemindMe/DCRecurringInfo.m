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

- (NSDate *)calculateNextDateFromLastDueDate:(NSDate *)lastDueDate andLastCompletionDate:(NSDate *)lastCompletionDate
{
    NSTimeInterval interval = 0;
    NSDate *startDate = nil;

    // Determine starting date to start counting from
    if ( self.repeatFromLastCompletion )
    {
        startDate = lastCompletionDate;
    }
    else
    {
        startDate = lastDueDate;
    }
    
    // Calculate next due date starting from startDate
    switch ( self.repeats )
    {
        case DCRecurringInfoRepeatsNever:
            return nil;
            break;
            
        case DCRecurringInfoRepeatsDaily:
            interval = 60 * 60 * 24 * self.repeatIncrement;
            return [startDate dateByAddingTimeInterval:interval];
            break;
            
        case DCRecurringInfoRepeatsWeekly:
            interval = 60 * 60 * 24 * 7 * self.repeatIncrement;
            return [startDate dateByAddingTimeInterval:interval];
            break;
            
        case DCRecurringInfoRepeatsMonthly:
        {
            NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setMonth:1];
            NSCalendar* calendar = [NSCalendar currentCalendar];
            return [calendar dateByAddingComponents:dateComponents toDate:startDate options:0];
            break;
        }
            
        case DCRecurringInfoRepeatsYearly:
            return nil;
            break;
            
        default:
            break;
    }
    
    return nil;
}

@end
