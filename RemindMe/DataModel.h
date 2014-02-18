//
//  DataModel.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCReminder.h"
#import "DCRecurringInfo.h"

@protocol DataModelProtocol <NSObject>

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index;
- (void)dataModelMovedObject:(DCReminder *)reminder from:(NSUInteger)from toIndex:(NSUInteger)to;

@end

@interface DataModel : NSObject

@property (nonatomic, weak) id<DataModelProtocol>delegate;

+ (DataModel *)sharedInstance;
- (NSInteger)numItems;
- (void)addReminder:(DCReminder *)reminder;
- (void)updateReminder:(DCReminder *)reminder;
- (void)addCompletionDateForReminder:(DCReminder *)reminder date:(NSDate *)date;
- (DCReminder *)reminderAtIndex:(NSInteger)index;
- (void)removeReminderAtIndex:(NSInteger)index;
- (NSArray *)completionDatesForReminder:(DCReminder *)reminder;


- (NSInteger)numDueBefore:(NSDate *)date;
- (NSInteger)numDueAfter:(NSDate *)date1 andBefore:(NSDate *)date2;
- (NSInteger)numDueAfter:(NSDate *)date;
- (NSInteger)numMuted;

@end
