//
//  DCNewReminderViewController.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCReminder.h"

@protocol NewReminderProtocol <NSObject>
- (void)didAddNewReminder:(DCReminder *)newReminder;
@end

@interface DCNewReminderViewController : UITableViewController

@property (nonatomic, weak) id<NewReminderProtocol> delegate;

@end
