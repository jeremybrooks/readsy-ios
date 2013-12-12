//
//  DetailViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadsyMetadata.h"
#import "ReadsyEntry.h"
#import <DropboxSDK/DropboxSDK.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, DBRestClientDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *headingLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UISwitch *isReadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *isReadSwitchLabel;

@property (strong, nonatomic) ReadsyMetadata *detailItem;
@property (strong, nonatomic) ReadsyEntry *entryItem;
@property (strong, nonatomic) DBRestClient *restClient;
@property (strong, nonatomic) NSDateFormatter *mmddFormat;
@property (strong, nonatomic) NSDateFormatter *shortFormat;

- (IBAction)setReadFlag:(id)sender;
- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeRight:(id)sender;

@end

