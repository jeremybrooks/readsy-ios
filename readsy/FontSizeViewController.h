//
//  SettingsViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/9/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FontSizeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *fontLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

- (IBAction)changeFontSize:(id)sender;
@end
