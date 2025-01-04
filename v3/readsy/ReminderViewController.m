//
//  ReminderViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/15/16.
//  Copyright © 2016 Jeremy Brooks. All rights reserved.
//

#import "ReminderViewController.h"
#import "Constants.h"

@interface ReminderViewController ()

@end

@implementation ReminderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (settings.types == UIUserNotificationTypeNone) {
        self.reminderSwitch.on = NO;
        self.timePicker.enabled = NO;
        
        // clean up for the case where user used to allow notifications,
        // but disabled them in settings.
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notifications Not Allowed"
                                                                       message:@"At this time, readsy is not allowed to display notifications.\n\nPlease to go to Settings -> readsy -> Notifications and turn on 'Allow Notifications'."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * _Nonnull action) {
                              [self.navigationController popViewControllerAnimated:YES];
                          }]];
        
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    } else {
        NSString *remindersEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:kRemindersEnabled];
        NSDate *reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:kReminderTime];
        if (remindersEnabled) {
            self.reminderSwitch.on = YES;
            self.timePicker.enabled = YES;
        } else {
            self.reminderSwitch.on = NO;
            self.timePicker.enabled = NO;
        }
        if (reminderTime) {
            self.timePicker.date = reminderTime;
        } else {
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            calendar.timeZone = [NSTimeZone localTimeZone];
            NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
            components.hour = 9;
            components.minute = 0;
            self.timePicker.date = [calendar dateFromComponents:components];
        }
    }
}

- (void)switchChanged:(id)sender {
    self.timePicker.enabled = self.reminderSwitch.on;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // delete any existing local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.reminderSwitch.on) {
        [defaults setObject:@"YES" forKey:kRemindersEnabled];
        [defaults setObject:self.timePicker.date forKey:kReminderTime];
        
        // schedule a local notification
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [self calculateNextReminderTime:self.timePicker.date];
        notification.timeZone = [NSTimeZone localTimeZone] ;
        notification.alertBody = @"Time to read!";
        notification.soundName = @"pageturn.wav";
        notification.repeatInterval = NSCalendarUnitDay;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    } else {
        [defaults removeObjectForKey:kRemindersEnabled];
    }
    [defaults synchronize];
}

- (NSDate *)calculateNextReminderTime:(NSDate *)time {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *nowComponents = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                                          fromDate:[NSDate date]];
    NSDateComponents *inTimeComponents = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                                      fromDate:time];
    // notificaton is for tomorrow if:
    //   selected time is less than current time OR
    BOOL tomorrow = NO;
    if (inTimeComponents.hour < nowComponents.hour) {
        tomorrow = YES;
    } else if (([inTimeComponents hour] == [nowComponents hour]) &&
               ([inTimeComponents minute] < [nowComponents minute])) {
        tomorrow = YES;
    }
    
    NSDateComponents *nextNotification = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute)
                                                      fromDate:[NSDate date]];
    nextNotification.hour = [inTimeComponents hour];
    nextNotification.minute = [inTimeComponents minute];
    if (tomorrow) {
        nextNotification.day = [nextNotification day] + 1;
    }
    
    return [gregorian dateFromComponents:nextNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
