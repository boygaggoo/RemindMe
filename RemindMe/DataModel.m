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
    [self.database executeUpdate:@"CREATE TABLE completed (id integer primary key autoincrement, reminderId integer not null, doneDate not null, foreign key(reminderId) references reminders(id) );"];
    [self.database executeUpdate:@"CREATE TABLE repeats (id integer primary key autoincrement, reminderId integer not null, repeats integer not null, repeatIncrement not null, repeateFromLastCompletion integer not null, daysToRepeat text not null, dayOfMonth integer not null, nthWeekOfMonth integer not null, foreign key(reminderId) references reminders(id) );"];
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

- (void)updateReminder:(DCReminder *)reminder
{
    NSUInteger originalIndex = [self.reminderList indexOfObject:reminder];
    [self.reminderList removeObjectAtIndex:originalIndex];
    [self addReminder:reminder fromDatabase:YES];

    [self.database open];
    [self.database executeUpdate:@"update reminders set reminderName = (?), nextDueDate = (?) where id = (?)", reminder.name, reminder.nextDueDate, reminder.uid];
    [self.database close];

    NSUInteger newIndex = [self.reminderList indexOfObject:reminder];
    [self.delegate dataModelMovedObject:reminder from:originalIndex toIndex:newIndex];
}

- (void)addCompletionDateForReminder:(DCReminder *)reminder date:(NSDate *)date
{
    [self.database open];
    [self.database executeUpdate:@"insert into completed (reminderId, doneDate) values (?, ?)", reminder.uid, date];
    [self.database close];
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

        [self.reminderList removeObjectAtIndex:index];
        
        [self.database open];
        [self.database executeUpdate:@"delete from reminders where id = ?", reminder.uid];
        [self.database close];

    }
}

- (NSInteger)numDueBefore:(NSDate *)date
{
    [self.database open];
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate < (?);", date];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    [self.database close];
    
    return count;
}

- (NSInteger)numDueAfter:(NSDate *)date1 andBefore:(NSDate *)date2
{
    [self.database open];
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate > (?) and nextDueDate < (?);", date1, date2];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    [self.database close];
    
    return count;
}

- (NSInteger)numDueAfter:(NSDate *)date
{
    [self.database open];
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate > (?);", date];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    [self.database close];
    
    return count;
}

- (NSArray *)completionDatesForReminder:(DCReminder *)reminder
{
    NSMutableArray *dates = [[NSMutableArray alloc] init];

    [self.database open];
    FMResultSet *results = [self.database executeQuery:@"select * from completed where reminderId == (?) order by doneDate;", reminder.uid];
    while ( [results next] )
    {
        NSDate *date = [results dateForColumn:@"doneDate"];
        [dates addObject:date];
    }
    [self.database close];

    [dates sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *d1 = obj1;
        NSDate *d2 = obj2;

        return [d1 compare:d2];
    }];

    return dates;
}

@end
