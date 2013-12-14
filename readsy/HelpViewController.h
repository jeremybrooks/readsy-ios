//
//  HelpViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/13/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)resetTips:(id)sender;
@end
