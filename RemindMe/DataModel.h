//
//  DataModel.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCReminder.h"

@interface DataModel : NSObject

- (NSInteger)numItems;
- (void)addReminder:(DCReminder *)reminder;
- (DCReminder *)reminderAtIndex:(NSInteger)index;

@end
