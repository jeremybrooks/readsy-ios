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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips Reset"
                                                                   message:@"Tips have been reset."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alert addAction:ok];
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
