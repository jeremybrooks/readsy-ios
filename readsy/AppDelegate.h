//
//  AppDelegate.h
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (void)setActivityIndicatorsVisible:(BOOL)visible;
+ (void)stopAllActivityIndicators;
@end
