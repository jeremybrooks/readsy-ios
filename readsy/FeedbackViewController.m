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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Send Mail"
                                                        message:[NSString stringWithFormat:@"This device is not congfigured to send email. You can send feedback to %@", FeedbackEmailAddress]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
}

/* alert view is shown when we can't send email. double check and then dismiss view */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (![MFMailComposeViewController canSendMail]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback Sent"
                                                        message:@"Your message was sent. Thanks!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
