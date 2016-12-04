//
//  MasterViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "DataFileViewController.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <DataFileViewControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
//@property (strong, nonatomic) DBRestClient *restClient;
@property (strong, nonatomic) NSMutableArray *objects;

-(void) handleDataFile:(NSURL *)dataFile;

@end
