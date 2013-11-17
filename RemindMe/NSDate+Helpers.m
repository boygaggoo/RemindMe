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

@end
