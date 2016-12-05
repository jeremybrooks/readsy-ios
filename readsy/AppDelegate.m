//
//  AppDelegate.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "Secrets.h"
#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DropboxSetupViewController.h"
#import "Constants.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>




@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DropboxClientsManager setupWithAppKey:kDbAppKey];
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

/*
 * Handles the case of:
 *   1) User opening a .readsy file
 *   2) Authorization from Dropbox
 */
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url.isFileURL && [url.path hasSuffix:@".readsy"]) {
        NSLog(@"TRYING TO HANDLE %@", url);
        UINavigationController *myNavCon = (UINavigationController*)self.window.rootViewController;
        MasterViewController *masterView = (MasterViewController*) [[myNavCon viewControllers] objectAtIndex:0];
        [masterView handleDataFile:url];
    } else {
        DBOAuthResult *authResult = [DropboxClientsManager handleRedirectURL:url];
        if (authResult != nil) {
            if ([authResult isSuccess]) {
                NSLog(@"Success! User is logged into Dropbox.");
                // Get the current view controller; it is most likely the dropbox setup view controller
                // If it IS the dropbox setup view controller, update the view to show
                // the state of the Dropbox link
                UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIViewController *currentController = [AppDelegate findBestViewController:viewController];
                if ([currentController isKindOfClass:[DropboxSetupViewController class]]) {
                    DropboxSetupViewController *dsvc = (DropboxSetupViewController*)currentController;
                    [dsvc updateView];
                }
            } else if ([authResult isCancel]) {
                NSLog(@"Authorization flow was manually canceled by user!");
            } else if ([authResult isError]) {
                NSLog(@"Error: %@", authResult);
            }
        }
    }
    return YES;
}

+(UIViewController*) findBestViewController:(UIViewController*)vc {
    
    if (vc.presentedViewController) {
        
        // Return presented view controller
        return [AppDelegate findBestViewController:vc.presentedViewController];
        
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        
        // Return right hand side
        UISplitViewController* svc = (UISplitViewController*) vc;
        if (svc.viewControllers.count > 0)
            return [AppDelegate findBestViewController:svc.viewControllers.lastObject];
        else
            return vc;
        
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        
        // Return top view
        UINavigationController* svc = (UINavigationController*) vc;
        if (svc.viewControllers.count > 0)
            return [AppDelegate findBestViewController:svc.topViewController];
        else
            return vc;
        
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        
        // Return visible view
        UITabBarController* svc = (UITabBarController*) vc;
        if (svc.viewControllers.count > 0)
            return [AppDelegate findBestViewController:svc.selectedViewController];
        else
            return vc;
        
    } else {
        
        // Unknown view controller type, return last child view controller
        return vc;
        
    }
    
}


@end
