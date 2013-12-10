//
//  DetailViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "DetailViewController.h"
#import "MBProgressHUD.h"
#import "MasterViewController.h"
#import "AppDelegate.h"

@interface DetailViewController ()
@property (nonatomic) CGFloat lastFactor;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) int fontResizeCount;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(ReadsyMetadata *)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        //        NSLog(@"New detail item");
        //        // Update the view.
        //        [self loadDataForItem];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void) loadDataForItem
{
    NSString *filename = [NSString stringWithFormat:@"/%@/%@", self.detailItem.sourceDirectory, [self.mmddFormat stringFromDate:self.detailItem.date]];
    NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), self.detailItem.fileShortDescription];
    
    [AppDelegate setActivityIndicatorsVisible:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.restClient loadFile:filename intoPath:tmpFile];
}


- (void)configureView
{
    if (self.detailItem) {
        self.dateLabel.text = [self.shortFormat stringFromDate:self.detailItem.date];
        self.title = self.detailItem.fileShortDescription;
    } else {
        self.title = @"";
    }
    if (self.entryItem) {
        self.contentTextView.font = [UIFont fontWithName:@"Helvetica" size:self.fontSize];
        self.contentTextView.text = self.entryItem.content;
        [self.contentTextView scrollRangeToVisible:NSMakeRange(0, 1)];
        
        self.headingLabel.text = self.entryItem.heading;
        self.isReadSwitch.hidden = NO;
        self.isReadSwitchLabel.hidden = NO;
        self.isReadSwitch.on = [self.detailItem isRead:self.detailItem.date];
    } else {
        self.isReadSwitch.hidden = YES;
        self.isReadSwitchLabel.hidden = YES;
    }
}


- (void)viewDidLoad
{
    if (!self.restClient) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *size = [defaults objectForKey:@"kReadsyFontSize"];
    
    if (size) {
        self.fontSize = [size floatValue];
    } else {
        self.fontSize = 14.0;
        [defaults setObject:[NSNumber numberWithFloat:self.fontSize] forKey:@"kReadsyFontSize"];
    }
    
    [self becomeFirstResponder];
    [super viewDidLoad];
    self.mmddFormat = [[NSDateFormatter alloc] init];
    [self.mmddFormat setDateFormat:@"MMdd"];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    self.paragraphStyle.alignment = NSTextAlignmentNatural;
    self.shortFormat = [[NSDateFormatter alloc] init];
    [self.shortFormat setDateFormat:@"EEEE MMMM d, yyyy"];
    [self loadDataForItem];
    [self configureView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [AppDelegate stopAllActivityIndicators];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.restClient cancelAllRequests];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"**********************MEMORY WARNING");
}

- (IBAction)setReadFlag:(id)sender
{
    [self.detailItem setReadFlag:self.isReadSwitch.on forDate:self.detailItem.date];
    [AppDelegate setActivityIndicatorsVisible:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *remoteFile = [NSString stringWithFormat:@"/%@/metadata", self.detailItem.sourceDirectory];
    NSLog(@"Loading metadata for file %@", remoteFile);
    [self.restClient loadMetadata:remoteFile];
}

- (void)navigateNumberOfDays:(int)days
{
    // only navigate if there is a detail item
    if (self.detailItem) {
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = days;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *newDate = [theCalendar dateByAddingComponents:dayComponent
                                                       toDate:_detailItem.date
                                                      options:0];
        _detailItem.date = newDate;
        [self loadDataForItem];
    }
}

- (IBAction)swipeLeft:(id)sender
{
    switch ([sender numberOfTouches]) {
        case 1:
            [self navigateNumberOfDays:1];
            break;
        case 2:
            [self navigateNumberOfDays:7];
            break;
        default:
            break;
    }
}

- (IBAction)swipeRight:(id)sender
{
    switch ([sender numberOfTouches]) {
        case 1:
            [self navigateNumberOfDays:-1];
            break;
        case 2:
            [self navigateNumberOfDays:-7];
            break;
        default:
            break;
    }
}

/* Handle shake */
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) {
        _detailItem.date = [NSDate date];
        [self loadDataForItem];
    }
}



- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Dropbox Access
//- (DBRestClient *)restClient {
//    if (!_restClient) {
//        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
//        _restClient.delegate = self;
//    }
//    [self.navigationItem backBarButtonItem].enabled = NO;
//    return _restClient;
//}

/* File was successfully loaded from Dropbox */
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    [AppDelegate setActivityIndicatorsVisible:NO];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    NSError *error;
    NSString *entry = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"There was an error reading the file - %@", error);
        [self showErrorMessage];
    } else {
        self.entryItem = [[ReadsyEntry alloc] initWithString:entry];
        
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
        if (error) {
            NSLog(@"Could not delete temp file. %@", error);
        }
    }
    [self configureView];
//    [self.navigationItem backBarButtonItem].enabled = YES;
}

/* File load failed */
- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    [AppDelegate setActivityIndicatorsVisible:NO];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    NSLog(@"There was an error loading the file - %@", error);
//    [self.navigationItem backBarButtonItem].enabled = YES;
    [self showErrorMessage];
}

/* Loaded metadata, so attempt to upload and replace metadata */
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSLog(@"Metadata loaded; uploading new metadata file replacing rev %@", metadata.rev);
    NSString *tmpFile = [NSString stringWithFormat:@"%@metadata", NSTemporaryDirectory()];
    NSData *properties = [[self.detailItem descriptionInPropertiesFormat] dataUsingEncoding:NSUTF8StringEncoding];
    [properties writeToFile:tmpFile atomically:YES];
    [self.restClient uploadFile:@"metadata"
                         toPath:[NSString stringWithFormat:@"/%@/", self.detailItem.sourceDirectory]
                  withParentRev:metadata.rev
                       fromPath:tmpFile];
}

/* Load metadata failed */
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSLog(@"Metadata load failed with error %@", error);
    [AppDelegate setActivityIndicatorsVisible:NO];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//    [self.navigationItem backBarButtonItem].enabled = YES;
    [self showErrorMessage];
}

/* Uploaded new metadata */
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
    if (error) {
        NSLog(@"Could not delete temp file. %@", srcPath);
    }
//    [self.navigationItem backBarButtonItem].enabled = YES;
    [AppDelegate setActivityIndicatorsVisible:NO];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
//    [self.navigationItem backBarButtonItem].enabled = YES;
    [self showErrorMessage];
}

- (void)showErrorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"There was an error while communicating with Dropbox. There may be a network problem."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return [[DBSession sharedSession] isLinked];
    //    return NO;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Library", @"Library");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
