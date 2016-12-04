//
//  DetailViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "DetailViewController.h"
#import "MasterViewController.h"
#import "Constants.h"

@interface DetailViewController ()
@property (nonatomic) CGFloat lastFactor;
@property (nonatomic) CGFloat fontSize;
@property (nonatomic) NSString *fontName;
@property (nonatomic) NSString *boldFontName;
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
    }
     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
         [self loadDataForItem];
     }
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void) loadDataForItem
{
    if (self.detailItem) {
        if ([self.detailItem dataValidForDate:self.detailItem.date]) {
            NSString *filename = [NSString stringWithFormat:@"/%@/%@", self.detailItem.sourceDirectory, [self.mmddFormat stringFromDate:self.detailItem.date]];
            NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), self.detailItem.fileShortDescription];
            [self showActivityIndicators:YES];
//            [self.restClient loadFile:filename intoPath:tmpFile];
        } else {
            self.dateLabel.text = [self.shortFormat stringFromDate:self.detailItem.date];
            self.headingLabel.text = @"";
            self.contentTextView.text = @"No entry found for this date.";
        }
    }
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kDidShowTipDetailView]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tip"
                                                                        message:@"To navigate to the next or previous day, swipe left or right. To navigate to today, shake the device."
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:^{
                                                  [defaults setObject:@"Y" forKey:kDidShowTipDetailView];
                                                  [defaults synchronize];
                                              }];
        
    }
}


- (void)viewDidLoad
{
    //If in portrait mode, display the master view
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.navigationItem.leftBarButtonItem.target performSelector:self.navigationItem.leftBarButtonItem.action withObject:self.navigationItem];
        #pragma clang diagnostic pop
    }
    
//    if (!self.restClient) {
//        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
//        self.restClient.delegate = self;
//    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *size = [defaults objectForKey:kReadsyFontSize];
    self.fontName = [defaults objectForKey:kReadsyFontName];
    self.boldFontName = [defaults objectForKey:kReadsyBoldFontName];
    if (size) {
        self.fontSize = [size floatValue];
    } else {
        self.fontSize = DefaultFontSize;
        [defaults setObject:[NSNumber numberWithFloat:self.fontSize] forKey:kReadsyFontSize];
        [defaults synchronize];
    }

    if (!self.fontName) {
        self.fontName = DefaultFontName;
        [defaults setObject:self.fontName forKey:kReadsyFontName];
        [defaults synchronize];
    }
    if (!self.boldFontName) {
        self.boldFontName = DefaultBoldFontName;
    }
    [self becomeFirstResponder];
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kReadsyFontName options:NSKeyValueObservingOptionNew context:NULL];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kReadsyFontSize options:NSKeyValueObservingOptionNew context:NULL];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kReadsyBoldFontName options:NSKeyValueObservingOptionNew context:NULL];
    }
    self.mmddFormat = [[NSDateFormatter alloc] init];
    [self.mmddFormat setDateFormat:@"MMdd"];
    self.shortFormat = [[NSDateFormatter alloc] init];
    [self.shortFormat setDateFormat:@"EEEE MMMM d, yyyy"];
    [self updateFonts];
    [self loadDataForItem];
    [self configureView];
}

- (void)updateFonts
{
    self.contentTextView.font = [UIFont fontWithName:self.fontName size:self.fontSize];
    self.headingLabel.font = [UIFont fontWithName:self.boldFontName size:(self.fontSize + 2)];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self resignFirstResponder];
    [self hideAllActivityIndicators];
//    [self.restClient cancelAllRequests];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kReadsyFontName];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kReadsyFontSize];
    }
    [super viewWillDisappear:animated];
}

/* Respond to changes in font name/size when this view is visible. */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kReadsyFontName]) {
        self.fontName = [change objectForKey:NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:kReadsyFontSize]) {
        self.fontSize = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    } else if ([keyPath isEqualToString:kReadsyBoldFontName]) {
        self.boldFontName = [change objectForKey:NSKeyValueChangeNewKey];
    }
    [self updateFonts];
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
    
    self.navigationItem.hidesBackButton = YES;

    [self showActivityIndicators:YES];
    
    NSString *remoteFile = [NSString stringWithFormat:@"/%@/metadata", self.detailItem.sourceDirectory];
    NSLog(@"Loading metadata for file %@", remoteFile);
//    [self.restClient loadMetadata:remoteFile];
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

/*
 * NOTE: two-touch swipes seem to be causing crashes.
 *       commenting out the switch to detect the number of touches
 *       until this can get sorted out.
 */
- (IBAction)swipeLeft:(id)sender
{
    [self navigateNumberOfDays:1];
    
//    switch ([sender numberOfTouches]) {
//        case 1:
//            [self navigateNumberOfDays:1];
//            break;
//        case 2:
//            [self navigateNumberOfDays:7];
//            break;
//        default:
//            break;
//    }
}

- (IBAction)swipeRight:(id)sender
{
    [self navigateNumberOfDays:-1];
    
//    switch ([sender numberOfTouches]) {
//        case 1:
//            [self navigateNumberOfDays:-1];
//            break;
//        case 2:
//            [self navigateNumberOfDays:-7];
//            break;
//        default:
//            break;
//    }
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
/* File was successfully loaded from Dropbox */
//- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
//       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
//    [self showActivityIndicators:NO];
//    NSError *error;
//    NSString *entry = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
//    if (error) {
//        NSLog(@"There was an error reading the file - %@", error);
//        [self showErrorMessage];
//    } else {
//        self.entryItem = [[ReadsyEntry alloc] initWithString:entry];
//        
//        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
//        if (error) {
//            NSLog(@"Could not delete temp file. %@", error);
//        }
//    }
//    [self configureView];
//}
//
///* File load failed */
//- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
//    [self showActivityIndicators:NO];
//    NSLog(@"There was an error loading the file - %@", error);
//    [self showErrorMessage];
//}
//
///* Loaded metadata, so attempt to upload and replace metadata */
//- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
//{
//    NSLog(@"Metadata loaded; uploading new metadata file replacing rev %@", metadata.rev);
//    NSString *tmpFile = [NSString stringWithFormat:@"%@metadata", NSTemporaryDirectory()];
//    NSData *properties = [[self.detailItem descriptionInPropertiesFormat] dataUsingEncoding:NSUTF8StringEncoding];
//    [properties writeToFile:tmpFile atomically:YES];
//    [self.restClient uploadFile:@"metadata"
//                         toPath:[NSString stringWithFormat:@"/%@/", self.detailItem.sourceDirectory]
//                  withParentRev:metadata.rev
//                       fromPath:tmpFile];
//}
//
///* Load metadata failed */
//- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
//{
//    NSLog(@"Metadata load failed with error %@", error);
//    [self showActivityIndicators:NO];
//    [self showErrorMessage];
//}
//
///* Uploaded new metadata */
//- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
//              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
//    [self showActivityIndicators:NO];
//    NSLog(@"File uploaded successfully to path: %@", metadata.path);
//    NSError *error;
//    [[NSFileManager defaultManager] removeItemAtPath:srcPath error:&error];
//    if (error) {
//        NSLog(@"Could not delete temp file. %@", srcPath);
//    }
//    
//}
//
//- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
//    [self showActivityIndicators:NO];
//    NSLog(@"File upload failed with error - %@", error);
//    [self showErrorMessage];
//}

- (void)showErrorMessage
{
    // probably should not replace content; a pop up is sufficient
//    self.headingLabel.text = @"";
//    self.contentTextView.text = @"There was an error while communicating with Dropbox. Do you have a network connection?";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:@"There was an error while communicating with Dropbox. There may be a network problem."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alert addAction:ok];
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}



#pragma mark - Split view
//-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
//{
//    return [[DBSession sharedSession] isLinked];
//    //    return NO;
//}

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


#pragma mark - Activity indicator stuff
- (void)showActivityIndicators:(BOOL)showIndicators
{
    [self showActivityIndicators:showIndicators andReset:NO];
}
- (void)hideAllActivityIndicators
{
    [self showActivityIndicators:NO andReset:YES];
}

- (void)showActivityIndicators:(BOOL)showIndicators andReset:(BOOL)reset
{
    static NSInteger callCount = 0;
    if (showIndicators) {
        callCount++;
    } else {
        callCount--;
    }
    if (reset) {
        callCount = 0;
    }
    
    if (callCount > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self.activityIndicator startAnimating];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.navigationItem.hidesBackButton = YES;
        }
    }
    if (callCount < 1) {
        callCount = 0;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.navigationItem.hidesBackButton = NO;
        }
    }
}
@end
