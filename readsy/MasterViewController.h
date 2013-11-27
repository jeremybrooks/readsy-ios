//
//  MasterViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController <DBRestClientDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, readonly, nonatomic) DBRestClient *restClient;

@end
