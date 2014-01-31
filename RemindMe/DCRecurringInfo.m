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
    copy.daysToRepeat = [self.daysToRepeat mutableCopy];
    copy.monthlyRepeatType = self.monthlyRepeatType;
    copy.dayOfMonth = self.dayOfMonth;
    copy.monthlyWeekDay = self.monthlyWeekDay;
    copy.nthWeekOfMonth = self.nthWeekOfMonth;

    return copy;
}

- (NSDate *)calculateNextDateFromLastDueDate:(NSDate *)lastDueDate andLastCompletionDate:(NSDate *)lastCompletionDate
{
    NSDate *startDate = nil;
    NSCalendar* calendar = [NSCalendar currentCalendar];

    // Determine starting date to start counting from
    if ( self.repeatFromLastCompletion )
    {
        NSDateComponents *completeDateComponents = [calendar components:(NSCalendarUnitTimeZone|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:lastCompletionDate];
        NSDateComponents *dueDateComponents = [calendar components:(NSCalendarUnitTimeZone|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:lastDueDate];

        completeDateComponents.hour = dueDateComponents.hour;
        completeDateComponents.minute = dueDateComponents.minute;
        
        startDate = [calendar dateFromComponents:completeDateComponents];
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
        {
            NSDateComponents *incrementDateComponent = [[NSDateComponents alloc] init];
            [incrementDateComponent setDay:self.repeatIncrement];
            return [calendar dateByAddingComponents:incrementDateComponent toDate:startDate options:0];
            break;
        }
        case DCRecurringInfoRepeatsWeekly:
            // No days selected to repeat on, so just increment one week from startDate
            if ( self.daysToRepeat == nil || self.daysToRepeat.count == 0 )
            {
                NSDateComponents *incrementDateComponent = [[NSDateComponents alloc] init];
                [incrementDateComponent setWeek:self.repeatIncrement];
                return [calendar dateByAddingComponents:incrementDateComponent toDate:startDate options:0];
            }
            // Only schedule task on specified days
            else
            {
                NSInteger daysToNextDueDate = 8; // Repeats weekly so start with a value greater than 7
                NSDateComponents *incrementDateComponent = [[NSDateComponents alloc] init];
                NSDateComponents *lastDueDateComponents = [calendar components:NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear fromDate:lastDueDate];
                NSUInteger weekdayToday = [lastDueDateComponents weekday];
                NSDate *newDate = nil;
                
                // If set to repeat the same day each week, just add 1 week to the lastDueDate
                if ( self.daysToRepeat.count == 1 )
                {
                    [incrementDateComponent setWeek:1];
                    newDate = [calendar dateByAddingComponents:incrementDateComponent toDate:lastDueDate options:0];
                }
                // If set to repeat multiple times per week, figure out the next day
                else
                {
                    // Loop through each day to repeat, looking for the minimum number of days between now and the next day
                    for ( NSNumber *day in self.daysToRepeat )
                    {
                        NSInteger daysToNextDay = (7 + 1 + [day intValue] - weekdayToday) % 7;
                        // Ignore results of 0 because that's just the same day as the lastDueDate
                        if ( daysToNextDay != 0 && daysToNextDay < daysToNextDueDate )
                        {
                            daysToNextDueDate = daysToNextDay;
                        }
                    }
                    
                    // Increment by number of days to next repeat day
                    [incrementDateComponent setDay:daysToNextDueDate];
                    newDate = [calendar dateByAddingComponents:incrementDateComponent toDate:lastDueDate options:0];
                }
                
                // Skip weeks if repeatIncrement is greater than 1
                if ( self.repeatIncrement > 1 )
                {
                    // If current date is in the same week as the last due date, no need to skip weeks
                    NSUInteger lastDueDateWeek = [lastDueDateComponents weekOfYear];
                    NSDateComponents *newDateComponents = [calendar components:NSCalendarUnitWeekOfYear fromDate:newDate];
                    NSUInteger nextDueDateWeek = [newDateComponents weekOfYear];
                    
                    // Weeks are different so skip ahead how every many weeks are necessary
                    if ( lastDueDateWeek != nextDueDateWeek )
                    {
                        NSDateComponents *addWeeksComponent = [[NSDateComponents alloc] init];
                        // Subtract one week because we already skipped to the next one
                        [addWeeksComponent setWeek:self.repeatIncrement - 1];
                        newDate = [calendar dateByAddingComponents:addWeeksComponent toDate:newDate options:0];
                    }
                }
                return newDate;
            }
            break;
            
        case DCRecurringInfoRepeatsMonthly:
        {
            NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
            NSDate *newDate = lastDueDate;
            
            switch ( self.monthlyRepeatType )
            {
                case DCRecurringInfoMonthlyTypeDayOfMonth:
                {
                    [dateComponents setMonth:self.repeatIncrement];
                    newDate = [calendar dateByAddingComponents:dateComponents toDate:lastDueDate options:0];
                    NSDateComponents *temp = [calendar components:(NSCalendarUnitTimeZone|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:newDate];
                    [temp setDay:self.dayOfMonth];
                    newDate = [calendar dateFromComponents:temp];
                    break;
                }
                    
                case DCRecurringInfoMonthlyTypeWeekOfMonth:
                {
                    [dateComponents setMonth:self.repeatIncrement];
                    newDate = [calendar dateByAddingComponents:dateComponents toDate:lastDueDate options:0];
                    NSDateComponents *temp = [calendar components:(NSCalendarUnitTimeZone|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekdayOrdinal|NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:newDate];
                    NSInteger correctMonth = [temp month];
                    [temp setWeekdayOrdinal:self.nthWeekOfMonth];
                    [temp setWeekday:self.monthlyWeekDay + 1];
                    newDate = [calendar dateFromComponents:temp];
                    
                    // If we tried to go to the 5th week of a month and it doesn't exist, it will go into the next month, so go back one week
                    temp = [calendar components:(NSCalendarUnitTimeZone|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekdayOrdinal|NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute) fromDate:newDate];
                    NSInteger newMonth = [temp month];
                    if ( correctMonth != newMonth )
                    {
                        NSDateComponents *negativeOneWeek = [[NSDateComponents alloc] init];
                        [negativeOneWeek setWeek:-1];
                        newDate = [calendar dateByAddingComponents:negativeOneWeek toDate:newDate options:0];
                    }
                    break;
                }
                    
                case DCRecurringInfoMonthlyTypeRegular:
                {
                    NSDateComponents *incrementDateComponent = [[NSDateComponents alloc] init];
                    [incrementDateComponent setMonth:self.repeatIncrement];
                    newDate = [calendar dateByAddingComponents:incrementDateComponent toDate:startDate options:0];
                    break;
                }
            }
            
            return newDate;
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

- (NSString *)weekdayStringForDay:(DCRecurringInfoWeekDays)day
{
    switch ( day )
    {
        case DCRecurringInfoWeekDaysSunday:
            return @"Sunday";
            break;
        case DCRecurringInfoWeekDaysMonday:
            return @"Monday";
            break;
        case DCRecurringInfoWeekDaysTuesday:
            return @"Tuesday";
            break;
        case DCRecurringInfoWeekDaysWednesday:
            return @"Wednesday";
            break;
        case DCRecurringInfoWeekDaysThursday:
            return @"Thursday";
            break;
        case DCRecurringInfoWeekDaysFriday:
            return @"Friday";
            break;
        case DCRecurringInfoWeekDaysSaturday:
            return @"Saturday";
            break;
    }
    
    return nil;
}

- (NSString *)weekAndDaysOfMonthString
{
    NSString *number = nil;
    if ( self.nthWeekOfMonth == 1 )
        number = @"First";
    else if ( self.nthWeekOfMonth == 2 )
        number = @"Second";
    else if ( self.nthWeekOfMonth == 3 )
        number = @"Third";
    else if ( self.nthWeekOfMonth == 4 )
        number = @"Fourth";
    else if ( self.nthWeekOfMonth == 5 )
        number = @"Fifth";
    else
    {
        number = @"Fifth";
        NSLog( @"Error: Trying to set week of month to %d", self.nthWeekOfMonth );
        self.nthWeekOfMonth = 5;
    }
    
    NSString *weekday = nil;
    switch ( self.monthlyWeekDay )
    {
        case DCRecurringInfoWeekDaysSunday:
            weekday = @"Sunday";
            break;
        case DCRecurringInfoWeekDaysMonday:
            weekday = @"Monday";
            break;
        case DCRecurringInfoWeekDaysTuesday:
            weekday = @"Tuesday";
            break;
        case DCRecurringInfoWeekDaysWednesday:
            weekday = @"Wednesday";
            break;
        case DCRecurringInfoWeekDaysThursday:
            weekday = @"Thursday";
            break;
        case DCRecurringInfoWeekDaysFriday:
            weekday = @"Friday";
            break;
        case DCRecurringInfoWeekDaysSaturday:
            weekday = @"Saturday";
            break;
    }
    
    NSString *text = [NSString stringWithFormat:@"%@ %@\nof the month", number, weekday];
    return text;
}

- (NSString *)daysOfWeekString
{
    NSMutableString *days = [NSMutableString string];
    NSArray *sortedDays = [self.daysToRepeat sortedArrayUsingSelector:@selector(compare:)];

    for ( NSUInteger index = 0; index < sortedDays.count; index++ )
    {
        if ( index != 0 )
        {
            [days appendString:@" "];
        }
        
        [days appendString:[self weekdayStringForDay:[[sortedDays objectAtIndex:index] integerValue]]];
        
        if ( sortedDays.count > 2 )
        {
            if ( sortedDays.count - index > 1 )
            {
                [days appendString:@","];
            }
        }
        
        if ( sortedDays.count - index == 2 )
        {
            [days appendString:@" and"];
        }
    }
    
    return days;
}

- (NSString *)sentenceFormat
{
    NSMutableString *sentence;
    
    switch ( self.repeats )
    {
        case DCRecurringInfoRepeatsNever:
            sentence = [@"Does not repeat" mutableCopy];
            break;
            
        case DCRecurringInfoRepeatsDaily:
            sentence = [NSMutableString stringWithFormat:@"Repeat every %d day%s", self.repeatIncrement, self.repeatIncrement == 1 ? "" : "s"];
            break;
            
        case DCRecurringInfoRepeatsWeekly:
            sentence = [NSMutableString stringWithFormat:@"Repeat every %d week%s", self.repeatIncrement, self.repeatIncrement == 1 ? "" : "s"];
            
            if ( self.daysToRepeat.count > 0 )
            {
                [sentence appendString:@" on "];
                [sentence appendString:[self daysOfWeekString]];
            }

            break;
            
        case DCRecurringInfoRepeatsMonthly:
        {
            sentence = [NSMutableString stringWithFormat:@"Repeat every %d month%s", self.repeatIncrement, self.repeatIncrement == 1 ? "" : "s"];
            
            switch ( self.monthlyRepeatType )
            {
                case DCRecurringInfoMonthlyTypeDayOfMonth:
                {
                    [sentence appendFormat:@" on the %d", self.dayOfMonth];
                    
                    switch ( self.dayOfMonth )
                    {
                        case 1:
                        case 21:
                        case 31:
                            [sentence appendString:@"st"];
                            break;
                            
                        case 2:
                        case 22:
                            [sentence appendString:@"nd"];
                            break;
                            
                        case 3:
                        case 23:
                            [sentence appendString:@"rd"];
                            break;
                            
                        default:
                            [sentence appendString:@"th"];
                            break;
                    }
                    
                    [sentence appendString:@" day of the month"];
                    break;
                }
                    
                case DCRecurringInfoMonthlyTypeWeekOfMonth:
                {
                    [sentence appendString:@" on the "];
                    NSString *weekString = [self weekAndDaysOfMonthString];
                    
                    // Make first letter lowercase
                    NSString *first = [[weekString substringToIndex:1] lowercaseString];
                    weekString = [weekString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:first];

                    [sentence appendString:weekString];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        }
            
        default:
            break;
    }
    
    [sentence appendString:@"."];

    return sentence;
}

@end
