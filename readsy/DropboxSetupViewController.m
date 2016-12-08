//
//  DropboxSetupViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/10/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import "DropboxSetupViewController.h"
#import "Constants.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface DropboxSetupViewController ()
@end

@implementation DropboxSetupViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateView];
}

- (void)updateView
{
    if ([DropboxClientsManager authorizedClient] != nil) {
        self.image.image = [UIImage imageNamed:@"linked.png"];
        self.label.text = @"Linked with Dropbox";
        [self.button setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
    } else {
        self.image.image = [UIImage imageNamed:@"unlinked.png"];
        self.label.text = @"Not linked with Dropbox";
        [self.button setTitle:@"Link Dropbox" forState:UIControlStateNormal];
    }
}


- (IBAction)linkOrUnlinkDropbox:(id)sender
{
    if ([DropboxClientsManager authorizedClient] == nil) {
        [DropboxClientsManager authorizeFromController:[UIApplication sharedApplication]
                                            controller:self
                                               openURL:^(NSURL *url) {
                                                   [[UIApplication sharedApplication] openURL:url];
                                               }
                                           browserAuth:NO];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unlink Dropbox?"
                                                                       message:@"You are about to unlink readsy with your Dropbox account. You will not see any content until you re-link it.\n\nDo you want to continue?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    [DropboxClientsManager unlinkClients];
                                                    [self updateView];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
