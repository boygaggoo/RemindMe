//
//  DCReminder.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCReminder.h"

@interface DCReminder ()
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

@end
