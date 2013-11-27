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

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController
@synthesize restClient = _restClient;
@synthesize shortFormat = _shortFormat;
@synthesize mmddFormat = _mmddFormat;

#pragma mark - Managing the detail item

- (void)setDetailItem:(ReadsyMetadata *)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        NSLog(@"New detail item");
        // Update the view.
        [self loadDataForItem];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void) loadDataForItem
{
    NSString *filename = [NSString stringWithFormat:@"/%@/%@", self.detailItem.sourceDirectory, [self.mmddFormat stringFromDate:self.detailItem.date]];
    NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), self.detailItem.fileShortDescription];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.restClient loadFile:filename intoPath:tmpFile];
}

- (NSDateFormatter *) shortFormat
{
    if (!_shortFormat) {
        _shortFormat = [[NSDateFormatter alloc] init];
        [_shortFormat setDateFormat:@"EEEE MMMM dd, yyyy"];
    }
    return _shortFormat;
}

- (NSDateFormatter *) mmddFormat
{
    if (!_mmddFormat) {
        _mmddFormat = [[NSDateFormatter alloc] init];
        [_mmddFormat setDateFormat:@"MMdd"];
    }
    return _mmddFormat;
}


- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.dateLabel.text = [self.shortFormat stringFromDate:self.detailItem.date];
    }
    if (self.entryItem) {
        self.headingLabel.text = self.entryItem.heading;
        self.contentTextView.text = self.entryItem.content;
        self.isReadSwitch.on = [self.detailItem isRead:self.detailItem.date];
    }
}


- (void)viewDidLoad
{
    [self becomeFirstResponder];
    [super viewDidLoad];
    _mmddFormat = [[NSDateFormatter alloc] init];
    [_mmddFormat setDateFormat:@"MMdd"];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self resignFirstResponder];
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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    NSString *remoteFile = [NSString stringWithFormat:@"/%@/metadata", self.detailItem.sourceDirectory];
    NSLog(@"Loading metadata for file %@", remoteFile);
    [_restClient loadMetadata:remoteFile];
}

- (void)navigateNumberOfDays:(int)days
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = days;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *newDate = [theCalendar dateByAddingComponents:dayComponent
                                                   toDate:_detailItem.date
                                                  options:0];
    _detailItem.date = newDate;
    [self loadDataForItem];

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

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    _detailItem.date = [NSDate date];
    [self loadDataForItem];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Dropbox Access
- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    NSError *error;
    NSString *entry = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"There was an error reading the file - %@", error);
    } else {
        self.entryItem = [[ReadsyEntry alloc] initWithString:entry];
        
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
        if (error) {
            NSLog(@"Could not delete temp file. %@", error);
        }
    }
    [self configureView];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    NSLog(@"There was an error loading the file - %@", error);
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSLog(@"Metadata loaded; uploading new metadata file replacing rev %@", metadata.rev);
    NSString *tmpFile = [NSString stringWithFormat:@"%@metadata", NSTemporaryDirectory()];
    NSData *properties = [[self.detailItem descriptionInPropertiesFormat] dataUsingEncoding:NSUTF8StringEncoding];
    [properties writeToFile:tmpFile atomically:YES];
    [_restClient uploadFile:@"metadata"
                     toPath:[NSString stringWithFormat:@"/%@/", self.detailItem.sourceDirectory]
              withParentRev:metadata.rev
                   fromPath:tmpFile];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSLog(@"Metadata load failed with error %@", error);
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    //todo show error message
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
    if (error) {
        NSLog(@"Could not delete temp file. %@", srcPath);
    }
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
}


#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
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
