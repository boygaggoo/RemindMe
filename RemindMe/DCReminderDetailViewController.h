//
//  DCReminderDetailViewController.h
//  RemindMe
//
//  Created by Dan Cohn on 11/30/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCReminder.h"

@protocol ReminderDetailProtocol <NSObject>
@end

@interface DCReminderDetailViewController : UITableViewController

@property (nonatomic, weak) id<ReminderDetailProtocol> delegate;
@property (nonatomic, strong) DCReminder *reminder;

@end
