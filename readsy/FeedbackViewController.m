//
//  FeedbackViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/11/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "FeedbackViewController.h"
#import "Constants.h"
#import <MessageUI/MessageUI.h>

@interface FeedbackViewController ()

@end

@implementation FeedbackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setSubject:FeedbackEmailSubject];
        [mail setToRecipients:[NSArray arrayWithObject:FeedbackEmailAddress]];
        mail.mailComposeDelegate = self;
        [self presentViewController:mail animated:YES completion:NULL];
                               
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Send Mail"
                                                                       message:[NSString stringWithFormat:@"This device is not configured to send email. You can send feedback to %@", FeedbackEmailAddress]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:^{
                                                    if (![MFMailComposeViewController canSendMail]) {
                                                        [self.navigationController popViewControllerAnimated:YES];
                                                    }
                                                }];
        
    }
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Feedback Sent"
                                                                       message:@"Your message was sent. Thanks!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
