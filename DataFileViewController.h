//
//  DataFileViewController.h
//  readsy
//
//  Created by Jeremy Brooks on 1/16/15.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>


@protocol DataFileViewControllerDelegate <NSObject>
-(void)dataLoadFinished:(BOOL)finished;
@end

@interface DataFileViewController : UIViewController

@property (weak, nonatomic) id <DataFileViewControllerDelegate> dataFileDelegate;

@property NSURL *dataFile;
@property NSString *dataDirectory;
@property NSString *dataDirectoryPath;
@property NSMutableArray *uploadFileList;
@property NSString *installDirectory;
@property NSInteger uploadCount;
@property NSInteger listSize;

@property IBOutlet UILabel *statusLabel;
@property IBOutlet UIActivityIndicatorView *statusSpinner;
@property IBOutlet UIProgressView *statusProgress;

@end
