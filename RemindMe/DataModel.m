//
//  DataModel.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DataModel.h"

@interface DataModel ()
@property (nonatomic, strong) NSMutableArray *reminderList;
@property (nonatomic, assign) NSInteger numDueSoon;
@end

@implementation DataModel

- (id)init
{
    self = [super init];
    if ( self )
    {
        _reminderList = [[NSMutableArray alloc] initWithCapacity:5];
    }
    
    return self;
}

- (NSInteger)numItems
{
    return self.reminderList.count;
}

- (void)addReminder:(DCReminder *)reminder
{
    NSUInteger insertIndex = [self.reminderList indexOfObject:reminder
                                                inSortedRange:(NSRange){0, self.reminderList.count}
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                  DCReminder *r1 = (DCReminder *)obj1;
                                                  DCReminder *r2 = (DCReminder *)obj2;
                                                  NSDate *date1 = r1.nextDueDate;
                                                  NSDate *date2 = r2.nextDueDate;
                                                  if ( [date2 timeIntervalSinceDate:date1] > 0 )
                                                      return NSOrderedAscending;
                                                  return NSOrderedDescending;
                                              }];
    
    if ( reminder.dueSoon )
    {
        self.numDueSoon++;
    }
    
    [self.reminderList insertObject:reminder atIndex:insertIndex];
    [self.delegate dataModelInsertedObject:reminder atIndex:insertIndex];
}

- (DCReminder *)reminderAtIndex:(NSInteger)index
{
    if ( index >= [self numItems] )
        return nil;
    
    return self.reminderList[index];
}

- (void)removeReminderAtIndex:(NSInteger)index
{
    if ( index < [self numItems] )
    {
        DCReminder *reminder = [self.reminderList objectAtIndex:index];
        if ( reminder.dueSoon )
        {
            self.numDueSoon--;
        }
        [self.reminderList removeObjectAtIndex:index];
    }
}

//- (NSInteger)numDueSoon
//{
//    return self.numDueSoon;
//}

@end
