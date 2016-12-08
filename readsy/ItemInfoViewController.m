//
//  ItemInfoViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/6/16.
//  Copyright © 2016 Jeremy Brooks. All rights reserved.
//

#import "ItemInfoViewController.h"
#import "Constants.h"

@interface ItemInfoViewController ()

@end

@implementation ItemInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.fileDescription.text = self.detailItem.fileDescription;
    if ([self.detailItem.year isEqualToString:@"0"]) {
        self.validYear.text = @"Valid for any year.";
    } else {
        self.validYear.text = [NSString stringWithFormat:@"Valid for %@", self.detailItem.year];
    }
    self.itemVersion.text = [NSString stringWithFormat:@"Version %@", self.detailItem.version];
    
    self.progress1.backgroundColor = [UIColor clearColor];
    self.progress1.trackWidth = 22;
    self.progress1.progressWidth = 22;
//    self.progress1.roundedCornersWidth = 22;
    self.progress1.trackColor = [[UIColor purpleColor] colorWithAlphaComponent:.2];
    self.progress1.progressColor = [UIColor purpleColor];
    self.progress1.labelVCBlock = ^(KAProgressLabel *label){
        //self.pLabel1.startLabel.text = [NSString stringWithFormat:@"%.f",self.pLabel1.progress*100];
    };
    self.progress1.isEndDegreeUserInteractive = NO;
    
    self.progress2.backgroundColor = [UIColor clearColor];
    self.progress2.trackWidth = 22;
    self.progress2.progressWidth = 22;
//    self.progress2.roundedCornersWidth = 22;
    self.progress2.trackColor = [[UIColor greenColor] colorWithAlphaComponent:.2];
    self.progress2.progressColor = [UIColor greenColor];
    self.progress2.labelVCBlock = ^(KAProgressLabel *label){
        //self.pLabel2.startLabel.text = [NSString stringWithFormat:@"%.f",self.pLabel2.progress*100];
    };
    [self.progress2 setIsEndDegreeUserInteractive:NO];
    
    [self updateReadStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kDidShowTipInfoView]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tip"
                                                                       message:@"This view shows information about the data file.\n\nThe outer ring of the graph shows how far you should be based on the current date. The inner ring shows where you actually are.\n\nYou can mark all previous days read, or reset your progress. Reset is handy for the start of a new year, since you won't have to install the data file over again."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:^{
                                                  [defaults setObject:@"Y" forKey:kDidShowTipInfoView];
                                                  [defaults synchronize];
                                              }];
        
    }
}

- (void)updateReadStatus
{
    NSDate *today = [NSDate date];
    NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                                                   fromDate:today];
    [components setMonth:12];
    [components setDay:31];
    
    // if item is valid for the current year...
    if ([self.detailItem dataValidForDate:today]) {
        self.resetButton.hidden = NO;
        self.markReadButton.hidden = NO;
        // Calculate where we should be this year
        NSInteger dayOfYear = [[NSCalendar currentCalendar] ordinalityOfUnit:NSCalendarUnitDay
                                                                      inUnit:NSCalendarUnitYear
                                                                     forDate:today];
        
        NSInteger daysInYear = [self.detailItem getDaysInYear:today];
        
        [self.progress1 setProgress:(float)dayOfYear / daysInYear
                             timing:TPPropertyAnimationTimingEaseInEaseOut
                           duration:0.5
                              delay:0.2];
        
        
        // Calculate where we actually are
        NSDate *lastDayOfYear = [[NSCalendar currentCalendar] dateFromComponents:components];
        
        NSInteger daysRead = daysInYear - [self.detailItem getUnreadCountForDate:lastDayOfYear];
        [self.progress2 setProgress:(float)daysRead / daysInYear
                             timing:TPPropertyAnimationTimingEaseInEaseOut
                           duration:0.5
                              delay:0.2];
    } else {
        self.resetButton.hidden = YES;
        self.markReadButton.hidden = YES;
        // if item is for a past year...
        if ([self.detailItem.year integerValue] < components.year) {
            [self.progress1 setProgress:1.0
                                 timing:TPPropertyAnimationTimingEaseInEaseOut
                               duration:0.5
                                  delay:0.2];
            
            [components setYear:[self.detailItem.year integerValue]];
            NSInteger daysInYear = [self.detailItem getDaysInYear:[[NSCalendar currentCalendar] dateFromComponents:components]];
            NSDate *lastDayOfYear = [[NSCalendar currentCalendar] dateFromComponents:components];
            
            NSInteger daysRead = daysInYear - [self.detailItem getUnreadCountForDate:lastDayOfYear];
            [self.progress2 setProgress:(float)daysRead / daysInYear
                                 timing:TPPropertyAnimationTimingEaseInEaseOut
                               duration:0.5
                                  delay:0.2];
        } else {
            // item is for a future year
            self.progress1.progress = 0.0;
            self.progress2.progress = 0.0;
        }
    }
}



- (void)markPreviousDaysRead:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Mark Read?"
                                                                   message:@"This will mark all previous days as 'Read'. Are you sure?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self.detailItem markPreviousDaysRead:[NSDate date]];                                                
                                                [self updateDropbox];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}

- (void)resetStatus:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Mark Read?"
                                                                   message:@"This will mark all the days for this item as 'Unread'. Are you sure?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self.detailItem resetReadingStatus];
                                                [self updateDropbox];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];

}

- (void)updateDropbox
{
    NSString *remoteFile = [NSString stringWithFormat:@"/%@/metadata", self.detailItem.sourceDirectory];
    NSData *data = [[self.detailItem descriptionInPropertiesFormat] dataUsingEncoding:NSUTF8StringEncoding];
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithOverwrite];
    
    [self.activityIndicator startAnimating];
    self.navigationItem.hidesBackButton = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[client.filesRoutes uploadData:remoteFile
                               mode:mode
                         autorename:nil
                     clientModified:nil
                               mute:nil
                          inputData:data] response:^(DBFILESFileMetadata *result, DBFILESUploadError *routeError, DBRequestError *error) {
        [self updateReadStatus];
        self.navigationItem.hidesBackButton = NO;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        if (result) {
//            NSLog(@"Upload of '%@' successful", remoteFile);
        } else {
            NSLog(@"Upload error. routeError=%@, error=%@", routeError, error);
            NSString *errorMessage = [NSString stringWithFormat:@"There was an error communicating with Dropbox."];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:errorMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
            [alert addAction:ok];
            [self.navigationController presentViewController:alert
                                                    animated:YES
                                                  completion:nil];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
