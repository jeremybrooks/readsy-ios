//
//  HelpViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/13/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "HelpViewController.h"
#import "Constants.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

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
    self.textView.text = HelpText;
}

- (IBAction)resetTips:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kDidShowTipDetailView];
    [defaults synchronize];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips Reset"
                                                    message:@"Tips have been reset."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
