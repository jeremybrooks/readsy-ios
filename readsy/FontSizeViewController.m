//
//  SettingsViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/9/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "FontSizeViewController.h"

@interface FontSizeViewController ()

@end

@implementation FontSizeViewController

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *fontSize = [defaults objectForKey:@"kReadsyFontSize"];
    if (fontSize) {
        self.slider.value = [fontSize floatValue];
    } else {
        self.slider.value = 14.0;
    }
    
    [self changeFontSize:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:self.slider.value] forKey:@"kReadsyFontSize"];
    
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeFontSize:(id)sender
{
    self.fontLabel.font = [UIFont fontWithName:@"Helvetica" size:self.slider.value];
}

@end
