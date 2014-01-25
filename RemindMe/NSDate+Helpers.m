//
//  NSDate+Helpers.m
//  RemindMe
//
//  Created by Dan Cohn on 11/16/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "NSDate+Helpers.h"

@implementation NSDate (Helpers)

- (BOOL)dc_isDateAfter:(NSDate *)date1 andBefore:(NSDate *)date2
{
    return [self dc_isDateAfter:date1] && [self dc_isDateBefore:date2];
}

- (BOOL)dc_isDateBefore:(NSDate *)date
{
    return ([self timeIntervalSinceDate:date] < 0);
}

- (BOOL)dc_isDateAfter:(NSDate *)date
{
    return ([self timeIntervalSinceDate:date] > 0);
}

- (NSString *)dc_relativeDateString
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Get today's date with no time set
    NSDate *now = [NSDate date];
    NSDateComponents *nowDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:now];
    now = [calendar dateFromComponents:nowDateComponents];
    
    if ( now == nil )
        return nil;

    // Get this object's date with no time set
    NSDateComponents *myDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self];
    NSDate *myDate = [calendar dateFromComponents:myDateComponents];
    
    if ( myDate == nil )
        return nil;
    
    if ( [now compare:myDate] == NSOrderedSame )
    {
        return @"Today";
    }
    
    NSDateComponents *addDayComponent = [[NSDateComponents alloc] init];
    [addDayComponent setDay:1];

    NSDate *tomorrowDate = [calendar dateByAddingComponents:addDayComponent toDate:now options:0];

    if ( [tomorrowDate compare:myDate] == NSOrderedSame )
    {
        return @"Tomorrow";
    }
    
    [addDayComponent setDay:-1];
    NSDate *yesterdayDate = [calendar dateByAddingComponents:addDayComponent toDate:now options:0];
    
    if ( [yesterdayDate compare:myDate] == NSOrderedSame )
    {
        return @"Yesterday";
    }
    
    return nil;
}

+ (NSDate *)dc_dateWithoutSecondsFromDate:(NSDate *)date
{
    NSTimeInterval time = floor([date timeIntervalSinceReferenceDate] / 60.0) * 60.0;
    return [NSDate dateWithTimeIntervalSinceReferenceDate:time];
}

@end
