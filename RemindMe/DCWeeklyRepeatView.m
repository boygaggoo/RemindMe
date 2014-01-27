//
//  DCWeeklyRepeatView.m
//  RemindMe
//
//  Created by Dan Cohn on 1/26/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "DCWeeklyRepeatView.h"

@implementation DCWeeklyRepeatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for ( UIView *view in self.subviews )
    {
        if ( view.tag == 5 )
        {
            CGRect frame = view.frame;
            frame.origin.x = 320;
            view.frame = frame;
        }
    }
}

@end
