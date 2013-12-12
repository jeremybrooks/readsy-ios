//
//  SettingsViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/9/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FontSizeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *fontLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;

@property (strong, nonatomic) NSArray *availableFonts;
@property (strong, nonatomic) NSArray *boldFonts;
@property (strong, nonatomic) NSMutableArray *availableFontSizes;

@end
