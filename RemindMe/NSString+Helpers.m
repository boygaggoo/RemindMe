//
//  NSString+Helpers.m
//  RemindMe
//
//  Created by Dan Cohn on 1/30/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "NSString+Helpers.h"

@implementation NSString (Helpers)

- (NSDictionary *)dc_dictionaryFromURLQuery
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    for ( NSString *optionPair in [self componentsSeparatedByString:@"&"] )
    {
        NSArray *keyValueArray = [optionPair componentsSeparatedByString:@"="];
        
        if ( keyValueArray.count != 2 )
        {
            NSLog( @"Mailformed url query: %@", optionPair );
            continue;
        }
        
        NSString *key = [[keyValueArray objectAtIndex:0] stringByRemovingPercentEncoding];
        NSString *value = [[keyValueArray objectAtIndex:1] stringByRemovingPercentEncoding];
        
        [options setValue:value forKey:key];
    }
    
    return options;
}

@end
