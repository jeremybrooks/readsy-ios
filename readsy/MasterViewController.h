//
//  MasterViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataFileViewController.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <DataFileViewControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NSMutableArray *objects;

-(void) handleDataFile:(NSURL *)dataFile;

@end
