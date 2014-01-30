//
//  DCViewController.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCReminder.h"

@interface DCTableViewController : UITableViewController

@property (nonatomic, strong) DCReminder *reminderFromURL;

@end
