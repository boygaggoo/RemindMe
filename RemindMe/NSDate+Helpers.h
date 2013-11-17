//
//  NSDate+Helpers.h
//  RemindMe
//
//  Created by Dan Cohn on 11/16/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Helpers)

- (BOOL)dc_isDateAfter:(NSDate *)date1 andBefore:(NSDate *)date2;
- (BOOL)dc_isDateBefore:(NSDate *)date;
- (BOOL)dc_isDateAfter:(NSDate *)date;

@end
