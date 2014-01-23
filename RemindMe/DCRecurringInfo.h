//
//  DCRecurringInfo.h
//  RemindMe
//
//  Created by Dan Cohn on 12/17/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, DCRecurringInfoRepeats) {
    DCRecurringInfoRepeatsNever,
    DCRecurringInfoRepeatsDaily,    // repeatIncrement + repeateFromLastCompletion
    DCRecurringInfoRepeatsWeekly,   // repeatIncrement + repeateFromLastCompletion + daysToRepeat
    DCRecurringInfoRepeatsMonthly,  // repeatIncrement + repeateFromLastCompletion -or- dayOfMonth -or- nthWeekOfMonth + daysToRepeat
    DCRecurringInfoRepeatsYearly    // repeatIncrement + repeateFromLastCompletion
};

typedef NS_ENUM(NSInteger, DCRecurringInfoWeekDays) {
    DCRecurringInfoWeekDaysSunday,
    DCRecurringInfoWeekDaysMonday,
    DCRecurringInfoWeekDaysTuesday,
    DCRecurringInfoWeekDaysWednesday,
    DCRecurringInfoWeekDaysThursday,
    DCRecurringInfoWeekDaysFriday,
    DCRecurringInfoWeekDaysSaturday
};

@interface DCRecurringInfo : NSObject <NSMutableCopying>

// How often this task repeats
@property (nonatomic, assign) DCRecurringInfoRepeats repeats;

// Repeat event every N DCRecurringInfoRepeats
@property (nonatomic, assign) NSInteger repeatIncrement;

// Next date calculated from last completion date if YES, from previous due date if NO
@property (nonatomic, assign) BOOL repeatFromLastCompletion;

// Array of DCRecurringInfoWeekDays for days of the week reminder is due
@property (nonatomic, strong) NSMutableArray *daysToRepeat;

// For monthly tasks, repeat on nth day of month if NO, nth week of month if YES
@property (nonatomic, assign) BOOL monthlyRepeatWeekly;

// Day of the month the reminder is due
@property (nonatomic, assign) NSInteger dayOfMonth;

// Which week of the month to repeat (1-4)
@property (nonatomic, assign) NSInteger nthWeekOfMonth;


- (NSDate *)calculateNextDateFromLastDueDate:(NSDate *)lastDueDate andLastCompletionDate:(NSDate *)lastCompletionDate;

@end
