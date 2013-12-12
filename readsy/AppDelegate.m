//
//  AppDelegate.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "Secrets.h"
#import "AppDelegate.h"
#import "DropboxSetupViewController.h"
#import "Constants.h"
#import <DropboxSDK/DropboxSDK.h>



@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    DBSession *dbSession = [[DBSession alloc] initWithAppKey:kDbAppKey
                                                   appSecret:kDbAppSecret
                                                        root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];

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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/* Called when user has authorized Dropbox */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            NSDictionary *dict = [NSDictionary dictionaryWithObject:DropboxLinkResultSuccess forKey:kLinkResult];
            NSNotification *notification = [NSNotification notificationWithName:DropboxLinkNotification object:nil userInfo:dict];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        } else {
            NSLog(@"App was not linked.");
            NSDictionary *dict = [NSDictionary dictionaryWithObject:DropboxLinkResultFailure forKey:kLinkResult];
            NSNotification *notification = [NSNotification notificationWithName:DropboxLinkNotification object:nil userInfo:dict];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
        return YES;
    }
    
    NSLog(@"App was not linked.");
    NSDictionary *dict = [NSDictionary dictionaryWithObject:DropboxLinkResultFailure forKey:kLinkResult];
    NSNotification *notification = [NSNotification notificationWithName:DropboxLinkNotification object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    return NO;
}

//+ (void)setActivityIndicatorsVisible:(BOOL)visible
//{
//    [AppDelegate setActivityIndicatorsVisible:visible andReset:NO];
//}
//
//+ (void)setActivityIndicatorsVisible:(BOOL)visible andReset:(BOOL)reset
//{
//    static NSInteger callCount = 0;
//    if (visible) {
//        callCount++;
//    } else {
//        callCount--;
//    }
//    
//    if (reset) {
//        callCount = 0;
//    }
//
//    // The assertion helps to find programmer errors in activity indicator management.
//    // Since a negative NumberOfCallsToSetVisible is not a fatal error,
//    // it should probably be removed from production code.
////    NSAssert(callCount >= 0, @"Network Activity Indicator was asked to hide more often than shown");
//    if (callCount < 0 ) {
//        callCount = 0;
//    }
//    // Display the indicator as long as our static counter is > 0.
//    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(callCount > 0)];
//}
//
//+ (void)stopAllActivityIndicators
//{
//    [AppDelegate setActivityIndicatorsVisible:NO andReset:YES];
//}

@end
