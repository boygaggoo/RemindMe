//
//  DataModel.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCReminder.h"

@protocol DataModelProtocol <NSObject>

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index;

@end

@interface DataModel : NSObject

@property (nonatomic, weak) id<DataModelProtocol>delegate;

- (NSInteger)numItems;
- (void)addReminder:(DCReminder *)reminder;
- (DCReminder *)reminderAtIndex:(NSInteger)index;
- (void)removeReminderAtIndex:(NSInteger)index;
- (NSInteger)numDueSoon;

@end
