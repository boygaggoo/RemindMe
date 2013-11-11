//
//  DataModel.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DataModel.h"
#import <FMDatabase.h>

@interface DataModel ()
@property (nonatomic, strong) NSMutableArray *reminderList;
@property (nonatomic, assign) NSInteger numDueSoon;
@property (nonatomic, strong) FMDatabase *database;
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

- (void)createTables
{
    [self.database open];
    [self.database executeUpdate:@"CREATE TABLE reminders (id integer primary key autoincrement, reminderName text not null, nextDueDate date not null);"];
    [self.database close];
}

- (void)loadData
{
    if ( self.database )
        return;

    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"reminders.sql"];

    self.database = [[FMDatabase alloc] initWithPath:dbPath];
    [self createTables];
    [self loadDatabase];
    
}

- (void)loadDatabase
{
    [self.database open];
    FMResultSet *results = [self.database executeQuery:@"select * from reminders;"];
    
    while( [results next] )
    {
        DCReminder *reminder = [[DCReminder alloc] init];
        reminder.name = [results stringForColumn:@"reminderName"];
        reminder.nextDueDate = [results dateForColumn:@"nextDueDate"];
        reminder.uid = [NSNumber numberWithLongLong:[results intForColumn:@"id"]];
        [self addReminder:reminder fromDatabase:YES];
    }
    
    [self.database close];
}

- (NSInteger)numItems
{
    return self.reminderList.count;
}

- (void)addReminder:(DCReminder *)reminder fromDatabase:(BOOL)fromdb
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
    
    reminder.dueSoon = [self.delegate dataModelIsReminderDueSoon:reminder];
    
    if ( reminder.dueSoon )
    {
        self.numDueSoon++;
    }
    
    [self.reminderList insertObject:reminder atIndex:insertIndex];

    if ( !fromdb )
    {
        [self.database open];
        [self.database executeUpdate:@"insert into reminders (reminderName, nextDueDate) values (?, ?)", reminder.name, reminder.nextDueDate];
        reminder.uid = [NSNumber numberWithLongLong:[self.database lastInsertRowId]];
        [self.database close];
    
        [self.delegate dataModelInsertedObject:reminder atIndex:insertIndex];
    }
}

- (void)addReminder:(DCReminder *)reminder
{
    [self addReminder:reminder fromDatabase:NO];
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
        
        [self.database open];
        [self.database executeUpdate:@"delete from reminders where id = ?", reminder.uid];
        [self.database close];

    }
}

@end
