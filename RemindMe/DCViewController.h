//
//  DCViewController.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DCHideableSectionViewController.h>
#import "DCReminder.h"

@interface DCTableViewController : DCHideableSectionViewController

@property (nonatomic, strong) DCReminder *reminderFromURL;

@end
