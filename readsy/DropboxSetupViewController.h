//
//  DropboxSetupViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/10/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropboxSetupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *button;

- (IBAction)linkOrUnlinkDropbox:(id)sender;

@end
