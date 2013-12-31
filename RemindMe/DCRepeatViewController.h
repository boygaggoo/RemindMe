//
//  DCRepeatViewController.h
//  RemindMe
//
//  Created by Dan Cohn on 12/17/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCRecurringInfo.h"

@protocol NewRepeatInfoProtocol <NSObject>
- (void)didSaveRepeatInfo:(DCRecurringInfo *)repeatInfo;
@end

@interface DCRepeatViewController : UIViewController

@property (nonatomic, strong) DCRecurringInfo *recurringInfo;
@property (nonatomic, weak) id<NewRepeatInfoProtocol> delegate;

@end
