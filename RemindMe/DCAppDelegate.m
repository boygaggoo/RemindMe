//
//  DCAppDelegate.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCAppDelegate.h"
#import "DataModel.h"
#import "DCReminder.h"
#import "DCNotificationScheduler.h"
#import "NSString+Helpers.h"
#import "DCViewController.h"
#import "DCNewReminderViewController.h"
#import <Crashlytics/Crashlytics.h>

@implementation DCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"3d722b3d9afb538112cca01daa1b0ffb7fd60bae"];
    
    // Is the application always in the inactive state at this point?
    if ( application.applicationState == UIApplicationStateInactive )
    {
        [[DCNotificationScheduler sharedInstance] recreateNotifications];
    }
    // Override point for customization after application launch.

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    // Update badge count
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kDCShowIconBadge] )
    {
        application.applicationIconBadgeNumber = [[DataModel sharedInstance] numDueBefore:[NSDate date]];
    }
    else
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RELOAD_DATA"object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog( @"Got local notification: %@", notification );
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RELOAD_DATA"object:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ( [url.host isEqualToString:@"add"] )
    {
        NSDictionary *options = [url.query dc_dictionaryFromURLQuery];
        
        // Create new reminder object from information provided
        DCReminder *reminder = [[DCReminder alloc] init];
        reminder.name = options[@"name"];
        if ( [options objectForKey:@"due"] )
        {
            reminder.nextDueDate = [NSDate dateWithTimeIntervalSince1970:[(NSString *)options[@"due"] doubleValue]];
        }

        // Get the root view controller, set a temporary property to our new reminder object
        UINavigationController *navigationController = (UINavigationController*) self.window.rootViewController;
        DCTableViewController *startingVC = [[navigationController viewControllers] objectAtIndex:0];
        startingVC.reminderFromURL = reminder;
        
        // Make sure to pop to the root control so pressing back brings the user to the correct location
        [navigationController popToRootViewControllerAnimated:NO];
        
        // Segue to the NewReminderViewController
        [startingVC performSegueWithIdentifier:@"newReminder" sender:self];
    }
    else
    {
        NSLog( @"Error: Unreocgnized URL host: %@", url.host );
    }

    return YES;
}

@end
