//
//  DCReminderTableViewCell.m
//  RemindMe
//
//  Created by Dan Cohn on 11/11/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCReminderTableViewCell.h"

@implementation DCReminderTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    NSLog( @"   ***   %s   ***", __FUNCTION__ );
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog( @"   ***   %s   ***", __FUNCTION__ );
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        
    }
    
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
