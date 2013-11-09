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
    [self.reminderList addObject:reminder];
}

- (DCReminder *)reminderAtIndex:(NSInteger)index
{
    if ( index >= [self numItems] )
        return nil;
    
    return self.reminderList[index];
}

@end
