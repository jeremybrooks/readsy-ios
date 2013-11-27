//
//  WelcomeViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "Secrets.h"
#import "WelcomeViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *letsReadButton;
@property (weak, nonatomic) IBOutlet UITextView *message;
@end

@implementation WelcomeViewController

static NSString * const KEY_DBX_ACCESS_TOKEN = @"dbxAccessToken";
static NSString * const SEGUE_ID_MAIN_VIEW = @"mainViewSegue";

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
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(applicationDidBecomeActive:)
//                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

    if ([[DBSession sharedSession] isLinked]) {
        [self performSegueWithIdentifier:SEGUE_ID_MAIN_VIEW sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateDisplay];
}

/*
 * This can happen when the app returns from the background, and also after the
 * user has returned from authorizing Dropbox.
 *
 * In either case, we want to segue to the master view, but only if this view is
 * currently visible.
 */
//- (void)applicationDidBecomeActive:(NSNotification *)notification
//{
//    if ([[DBSession sharedSession] isLinked]) {
//        if (self.isViewLoaded && self.view.window){
//            [self performSegueWithIdentifier:SEGUE_ID_MAIN_VIEW sender:self];
//        }
//    }
//}

- (void)updateDisplay
{
    if ([[DBSession sharedSession]isLinked]) {
        self.message.text = @"readsy is connected to your Dropbox account.\n\nTo copy readsy content to your Dropbox account, you can use the desktop readsy app, or copy files from your desktop.\n\nTo learn more, visit the readsy home page.";
        [self.actionButton setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
        [self.letsReadButton setEnabled:YES];
    } else {
        self.message.text = @"readsy is a program to help you read something every day.\n\nTo get started, lets connect readsy to your Dropbox account so it can find some things to read!";
        [self.actionButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
        [self.letsReadButton setEnabled:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doAction:(id)sender
{
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
    } else {
        [[DBSession sharedSession] linkFromController:self];
    }
    [self updateDisplay];
}

//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

@end
