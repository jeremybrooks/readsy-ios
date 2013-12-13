//
//  DropboxSetupViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/10/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "DropboxSetupViewController.h"
#import "Constants.h"
#import <DropboxSDK/DropboxSDK.h>

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

- (void)updateView
{
    if ([[DBSession sharedSession] isLinked]) {

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
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
        [self updateView];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveDropboxLinkNotification:)
                                                     name:DropboxLinkNotification
                                                   object:nil];
        [[DBSession sharedSession] linkFromController:self];
    }

}

- (void)receiveDropboxLinkNotification:(NSNotification *)notification
{
    [self updateView];
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
