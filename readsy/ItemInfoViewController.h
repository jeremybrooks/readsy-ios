//
//  ItemInfoViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 12/6/16.
//  Copyright © 2016 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadsyMetadata.h"
#import "KAProgressLabel.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface ItemInfoViewController : UIViewController
@property (strong, nonatomic) ReadsyMetadata *detailItem;

@property IBOutlet KAProgressLabel *progress1;
@property IBOutlet KAProgressLabel *progress2;
@property IBOutlet UILabel *fileDescription;
@property IBOutlet UILabel *validYear;
@property IBOutlet UILabel *itemVersion;

@property IBOutlet UIButton *markReadButton;
@property IBOutlet UIButton *resetButton;

@property IBOutlet UIActivityIndicatorView *activityIndicator;

-(IBAction)markPreviousDaysRead:(id)sender;
-(IBAction)resetStatus:(id)sender;

@end
