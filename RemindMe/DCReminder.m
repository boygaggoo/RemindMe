//
//  DCReminder.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCReminder.h"

@interface DCReminder ()
@property (nonatomic, readwrite) BOOL dueSoon;
@end

@implementation DCReminder

- (id)init
{
    self = [super init];
    if ( self )
    {
        _dueSoon = NO;
    }
    
    return self;
}

- (void)setNextDueDate:(NSDate *)nextDueDate
{
    _nextDueDate = nextDueDate;
    if ( [_nextDueDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*3]] < 0 )
    {
        NSLog( @"   ***   %s  due soon ***", __FUNCTION__ );
        self.dueSoon = YES;
    }
    else
    {
        NSLog( @"   ***   %s  not due soon ***", __FUNCTION__ );
        self.dueSoon = NO;
    }
}

@end
