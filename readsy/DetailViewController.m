//
//  DetailViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
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
}

- (void) loadDataForItem
{
    if (self.detailItem) {
        if ([self.detailItem dataValidForDate:self.detailItem.date]) {
            NSString *filename = [NSString stringWithFormat:@"/%@/%@", self.detailItem.sourceDirectory, [self.mmddFormat stringFromDate:self.detailItem.date]];
            [self showActivityIndicators:YES];
            DropboxClient *client = [DropboxClientsManager authorizedClient];
            [[client.filesRoutes downloadData:filename] response:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBRequestError *error, NSData *fileData) {
                 [self showActivityIndicators:NO];
                 if (result) {
                     NSString *entry = [[NSString alloc] initWithData:fileData
                                                                encoding:NSUTF8StringEncoding];
                     self.entryItem = [[ReadsyEntry alloc] initWithString:entry];
                     [self configureView];
                 } else {
                     NSString *errorMessage = [NSString stringWithFormat:@"Error reading file '%@' from Dropbox.", filename];
                     [self showErrorMessage:errorMessage];
                 }
             }];
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
    
    NSString *remoteFile = [NSString stringWithFormat:@"/%@/metadata", self.detailItem.sourceDirectory];
    NSData *data = [[self.detailItem descriptionInPropertiesFormat] dataUsingEncoding:NSUTF8StringEncoding];
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithOverwrite];
    
    self.navigationItem.hidesBackButton = YES;
    [self showActivityIndicators:YES];
    [[client.filesRoutes uploadData:remoteFile
                               mode:mode
                         autorename:nil
                     clientModified:nil
                               mute:nil
                          inputData:data] response:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *error) {
         self.navigationItem.hidesBackButton = NO;
         [self showActivityIndicators:NO];
         if (result) {
//             NSLog(@"Upload of '%@' successful", remoteFile);
         } else {
             NSLog(@"Upload error. routeError=%@, error=%@", routeError, error);
             NSString *errorMessage = [NSString stringWithFormat:@"There was an error communicating with Dropbox."];
             [self showErrorMessage:errorMessage];
         }
     }];
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

- (void)showErrorMessage
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:@"There was an error while communicating with Dropbox. There may be a network problem."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil]];
    
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
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
        self.navigationItem.hidesBackButton = YES;
    }
    if (callCount < 1) {
        callCount = 0;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        self.navigationItem.hidesBackButton = NO;
    }
}

- (void)showErrorMessage: (NSString *)message {
    if (!message) {
        message = @"There was an error while communicating with Dropbox. There may be a network problem.";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alert addAction:ok];
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}
@end
