//
//  FeedbackViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/11/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
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
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        [mail setSubject:FeedbackEmailSubject];
        [mail setToRecipients:[NSArray arrayWithObject:FeedbackEmailAddress]];
        [mail setMessageBody:[NSString stringWithFormat:@"Sent from readsy version %@ (%@)\n\n",
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]]
                      isHTML:NO];
        mail.mailComposeDelegate = self;
        [self presentViewController:mail animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot Send Mail"
                                                                       message:[NSString stringWithFormat:@"Mail services are not available. You can send feedback to %@", FeedbackEmailAddress]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:^{
                                                  [self.navigationController popViewControllerAnimated:YES];
                                              }];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *message;
    if (result == MFMailComposeResultSent) {
        message = @"Your message was sent.";
    } else if (result == MFMailComposeResultFailed) {
        message = @"Could not send the message.";
    }
    if (message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self.navigationController popViewControllerAnimated:YES];
                                            }]];
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
