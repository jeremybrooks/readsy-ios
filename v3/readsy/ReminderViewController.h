//
//  ReminderViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/15/16.
//  Copyright © 2016 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReminderViewController : UIViewController

@property IBOutlet UISwitch *reminderSwitch;
@property IBOutlet UIDatePicker *timePicker;

-(IBAction)switchChanged:(id)sender;

@end
