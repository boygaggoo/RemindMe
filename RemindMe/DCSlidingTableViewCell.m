//
//  DCSlidingTableViewCell.m
//  RemindMe
//
//  Created by Dan Cohn on 11/11/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCSlidingTableViewCell.h"

@interface DCSlidingTableViewCell () {
    CGPoint startingPoint;
}
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@end

@implementation DCSlidingTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cellMoving:)];
        [self addGestureRecognizer:_panRecognizer];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)cellMoving:(UIPanGestureRecognizer *)recognizer
{
    switch ( recognizer.state )
    {
        case UIGestureRecognizerStateBegan:
            startingPoint = [recognizer locationInView:recognizer.view.superview];
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint newPoint = [recognizer locationInView:recognizer.view.superview];
            CGRect currentFrame = self.frame;
            currentFrame.origin.x = newPoint.x - startingPoint.x;
            self.frame = currentFrame;
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        {
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 CGRect currentFrame = self.frame;
                                 currentFrame.origin.x = 0;
                                 self.frame = currentFrame;
                             } completion:nil];
        }
            break;
            
        case UIGestureRecognizerStatePossible:
            break;
    }
}

@end
