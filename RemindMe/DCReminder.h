//
//  DCReminder.h
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCReminder : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *nextDueDate;

@end
