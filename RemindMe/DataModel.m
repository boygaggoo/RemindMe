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

static DataModel *dataModelInstance;

+ (DataModel *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataModelInstance = [[self alloc] init];
        [dataModelInstance loadData];
    });
    
    return dataModelInstance;
}

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
    NSNumber *currentVersion = @5;
    [self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS metadata (key text not null, value integer not null)"];
    
    // Get current database version
    FMResultSet *results = [self.database executeQuery:@"select value from metadata where key = \"dbversion\""];
    int dbversion = 0;
    if ( [results next] )
    {
        dbversion = [results intForColumnIndex:0];
    }
    
    if ( dbversion < 1 )
    {    
        [self.database executeUpdate:@"CREATE TABLE reminders (id integer primary key autoincrement, reminderName text not null, nextDueDate date not null);"];
        [self.database executeUpdate:@"CREATE TABLE completed (id integer primary key autoincrement, reminderId integer not null, doneDate not null, foreign key(reminderId) references reminders(id) on delete cascade );"];
        [self.database executeUpdate:@"CREATE TABLE repeats (id integer primary key autoincrement, reminderId integer not null, repeats integer not null, repeatIncrement not null, repeatsFromLastCompletion integer not null, daysToRepeat integer not null, dayOfMonth integer not null, nthWeekOfMonth integer not null, monthlyRepeatType integor not null, monthlyWeekDay integer not null, foreign key(reminderId) references reminders(id) on delete cascade );"];
    }
    
    if ( dbversion < 4 )
    {
        [self.database executeUpdate:@"alter table reminders add column muted integer not null default 0"];
    }
    
    if ( dbversion < 5 )
    {
        [self.database executeUpdate:@"alter table reminders add column notes text"];
    }
    
    if ( dbversion == 0 )
    {
        [self.database executeUpdate:@"insert into metadata (key, value) values (\"dbversion\", ?)", currentVersion];
    }
    else
    {
        [self.database executeUpdate:@"update metadata set value = (?) where key = \"dbversion\"", currentVersion];
    }
}

- (void)enableForeignKeys
{
    [self.database executeUpdate:@"PRAGMA foreign_keys = ON;"];
}

- (void)openDatabase
{
    [self.database open];
    [self enableForeignKeys];
}

- (void)loadData
{
    if ( self.database )
        return;

    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [docPaths objectAtIndex:0];
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"reminders.sql"];

    self.database = [[FMDatabase alloc] initWithPath:dbPath];
    self.database.logsErrors = YES;
    [self openDatabase];
    [self createTables];
    [self loadDatabase];
}

- (void)loadDatabase
{
    FMResultSet *results = [self.database executeQuery:@"select * from reminders;"];
    
    while( [results next] )
    {
        DCReminder *reminder = [[DCReminder alloc] init];
        reminder.name = [results stringForColumn:@"reminderName"];
        reminder.nextDueDate = [results dateForColumn:@"nextDueDate"];
        reminder.uid = [NSNumber numberWithLongLong:[results intForColumn:@"id"]];
        reminder.muted = [results boolForColumn:@"muted"];
        reminder.notes = [results stringForColumn:@"notes"];
        
        // Load repeating info
        FMResultSet *results2 = [self.database executeQuery:@"select * from repeats where reminderId = (?)", reminder.uid];
        if ( [results2 next] )
        {
            reminder.repeatingInfo = [[DCRecurringInfo alloc] init];
            reminder.repeatingInfo.repeats = [results2 intForColumn:@"repeats"];
            reminder.repeatingInfo.repeatIncrement = [results2 intForColumn:@"repeatIncrement"];
            reminder.repeatingInfo.repeatFromLastCompletion = [results2 boolForColumn:@"repeatsFromLastCompletion"];
            reminder.repeatingInfo.daysToRepeat = [self integerToDays:[results2 intForColumn:@"daysToRepeat"]];
            reminder.repeatingInfo.monthlyRepeatType = [results2 intForColumn:@"monthlyRepeatType"];
            reminder.repeatingInfo.dayOfMonth = [results2 intForColumn:@"dayOfMonth"];
            reminder.repeatingInfo.monthlyWeekDay = [results2 intForColumn:@"monthlyWeekDay"];
            reminder.repeatingInfo.nthWeekOfMonth = [results2 intForColumn:@"nthWeekOfMonth"];
        }
        
        [self addReminder:reminder fromDatabase:YES];
    }
}

- (NSInteger)numItems
{
    return self.reminderList.count;
}

- (NSInteger)daysToInteger:(NSArray *)dayArray
{
    NSInteger daysAsInt = 0;
    
    for ( NSNumber *day in dayArray )
    {
        DCRecurringInfoWeekDays dayEnum = [day intValue];
        
        if ( daysAsInt == 0 )
        {
            daysAsInt = 1;
        }
        
        switch ( dayEnum ) {
            case DCRecurringInfoWeekDaysSunday:
                daysAsInt *= 2;
                break;
            case DCRecurringInfoWeekDaysMonday:
                daysAsInt *= 3;
                break;
            case DCRecurringInfoWeekDaysTuesday:
                daysAsInt *= 5;
                break;
            case DCRecurringInfoWeekDaysWednesday:
                daysAsInt *= 7;
                break;
            case DCRecurringInfoWeekDaysThursday:
                daysAsInt *= 11;
                break;
            case DCRecurringInfoWeekDaysFriday:
                daysAsInt *= 13;
                break;
            case DCRecurringInfoWeekDaysSaturday:
                daysAsInt *= 17;
                break;
        }
    }
    
    return daysAsInt;
}

- (NSMutableArray *)integerToDays:(NSInteger)daysAsInt
{
    NSMutableArray *days = [[NSMutableArray alloc] init];
    if ( daysAsInt == 0 )
        return days;
    
    if ( daysAsInt % 2 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysSunday]];
    if ( daysAsInt % 3 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysMonday]];
    if ( daysAsInt % 5 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysTuesday]];
    if ( daysAsInt % 7 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysWednesday]];
    if ( daysAsInt % 11 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysThursday]];
    if ( daysAsInt % 13 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysFriday]];
    if ( daysAsInt % 17 == 0 )
        [days addObject:[NSNumber numberWithInt:DCRecurringInfoWeekDaysSaturday]];
    return days;
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
                                                  if ( r1.muted == r2.muted )
                                                  {
                                                      if ( [date2 timeIntervalSinceDate:date1] > 0 )
                                                          return NSOrderedAscending;
                                                      return NSOrderedDescending;
                                                  }
                                                  else
                                                  {
                                                      if ( r1.muted )
                                                      {
                                                          return NSOrderedDescending;
                                                      }
                                                      return NSOrderedAscending;
                                                  }
                                              }];
    
    [self.reminderList insertObject:reminder atIndex:insertIndex];

    if ( !fromdb )
    {
        [self.database executeUpdate:@"insert into reminders (reminderName, nextDueDate, muted, notes) values (?, ?, ?, ?)", reminder.name, reminder.nextDueDate, [NSNumber numberWithInt:reminder.muted], reminder.notes];
        reminder.uid = [NSNumber numberWithLongLong:[self.database lastInsertRowId]];
        [self addRecurringInfoForReminder:reminder];
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
    [self.database executeUpdate:@"update reminders set reminderName = (?), nextDueDate = (?), muted = (?), notes = (?) where id = (?)", reminder.name, reminder.nextDueDate, [NSNumber numberWithInt:reminder.muted], reminder.notes, reminder.uid];
    NSUInteger newIndex = [self.reminderList indexOfObject:reminder];
    [self updateRecurringInfoForReminder:reminder];
    [self.delegate dataModelMovedObject:reminder from:originalIndex toIndex:newIndex];
}

- (void)addRecurringInfoForReminder:(DCReminder *)reminder
{
    NSInteger daysAsInt = [self daysToInteger:reminder.repeatingInfo.daysToRepeat];
    
    [self.database executeUpdate:@"insert into repeats (reminderId, repeats, repeatIncrement, repeatsFromLastCompletion, daysToRepeat, monthlyRepeatType, dayOfMonth, monthlyWeekDay, nthWeekOfMonth) values (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        reminder.uid,
        [NSNumber numberWithInt:reminder.repeatingInfo.repeats],
        [NSNumber numberWithInteger:reminder.repeatingInfo.repeatIncrement],
        [NSNumber numberWithBool:reminder.repeatingInfo.repeatFromLastCompletion],
        [NSNumber numberWithInteger:daysAsInt],
        [NSNumber numberWithInteger:reminder.repeatingInfo.monthlyRepeatType],
        [NSNumber numberWithInteger:reminder.repeatingInfo.dayOfMonth],
        [NSNumber numberWithInteger:reminder.repeatingInfo.monthlyWeekDay],
        [NSNumber numberWithInteger:reminder.repeatingInfo.nthWeekOfMonth] ];
}

- (void)updateRecurringInfoForReminder:(DCReminder *)reminder
{
    NSInteger daysAsInt = [self daysToInteger:reminder.repeatingInfo.daysToRepeat];
    
    [self.database executeUpdate:@"update repeats set repeats = (?), repeatIncrement = (?), repeatsFromLastCompletion = (?), daysToRepeat = (?), monthlyRepeatType = (?), dayOfMonth = (?), monthlyWeekDay = (?), nthWeekOfMonth = (?)  where reminderId = (?)",
        [NSNumber numberWithInt:reminder.repeatingInfo.repeats],
        [NSNumber numberWithInteger:reminder.repeatingInfo.repeatIncrement],
        [NSNumber numberWithBool:reminder.repeatingInfo.repeatFromLastCompletion],
        [NSNumber numberWithInteger:daysAsInt],
        [NSNumber numberWithInteger:reminder.repeatingInfo.monthlyRepeatType],
        [NSNumber numberWithInteger:reminder.repeatingInfo.dayOfMonth],
        [NSNumber numberWithInteger:reminder.repeatingInfo.monthlyWeekDay],
        [NSNumber numberWithInteger:reminder.repeatingInfo.nthWeekOfMonth],
        reminder.uid];
}

- (void)addCompletionDateForReminder:(DCReminder *)reminder date:(NSDate *)date
{
    [self.database executeUpdate:@"insert into completed (reminderId, doneDate) values (?, ?)", reminder.uid, date];
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
        
        [self.database executeUpdate:@"delete from reminders where id = ?", reminder.uid];
    }
}

- (NSInteger)numDueBefore:(NSDate *)date
{
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate < (?) and muted == 0;", date];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    
    return count;
}

- (NSInteger)numDueAfter:(NSDate *)date1 andBefore:(NSDate *)date2
{
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate > (?) and nextDueDate < (?) and muted == 0;", date1, date2];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    
    return count;
}

- (NSInteger)numDueAfter:(NSDate *)date
{
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where nextDueDate > (?) and muted == 0;", date];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    
    return count;
}

- (NSInteger)numMuted
{
    FMResultSet *results = [self.database executeQuery:@"select count(*) from reminders where muted == 1;"];
    [results next];
    NSInteger count = [results intForColumnIndex:0];
    
    return count;
}

- (NSArray *)completionDatesForReminder:(DCReminder *)reminder
{
    NSMutableArray *dates = [[NSMutableArray alloc] init];

    FMResultSet *results = [self.database executeQuery:@"select * from completed where reminderId == (?) order by doneDate;", reminder.uid];
    while ( [results next] )
    {
        NSDate *date = [results dateForColumn:@"doneDate"];
        [dates addObject:date];
    }

    [dates sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *d1 = obj1;
        NSDate *d2 = obj2;

        return [d1 compare:d2];
    }];

    return dates;
}

- (void)dealloc
{
    [self.database close];
}

@end
