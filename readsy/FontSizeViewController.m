//
//  SettingsViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 12/9/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import "FontSizeViewController.h"
#import "Constants.h"

@interface FontSizeViewController ()

@end

@implementation FontSizeViewController
NSInteger selectedFontRow;
NSInteger selectedFontSizeRow;

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
    NSNumber *fontSize = [defaults objectForKey:kReadsyFontSize];
    if (!fontSize) {
        fontSize = [NSNumber numberWithLong:DefaultFontSize];
    }
    
    NSString *fontName = [defaults objectForKey:kReadsyFontName];
    if (!fontName) {
        fontName = DefaultFontName;
    }
    
    self.availableFonts = [NSArray arrayWithObjects:
                           @"Al Nile",
                           @"American Typewriter",
                           @"Avenir",
                           @"Baskerville",
                           @"Cochin",
                           @"Courier",
                           @"Damascus",
                           @"Georgia",
                           @"Gill Sans",
                           @"Helvetica",
                           @"Helvetica Neue",
                           @"Kailasa",
                           @"Marion",
                           @"Menlo",
                           @"Noteworthy",
                           @"Optima",
                           @"Palatino",
                           @"Thonburi",
                           @"Times New Roman",
                           @"Verdana",
                           @"Zapfino",
                           nil];
    self.boldFonts = [NSArray arrayWithObjects:
                      @"AlNile-Bold",
                      @"AmericanTypewriter-Bold",
                      @"Avenir-HeavyOblique",
                      @"Baskerville-SemiBoldItalic",
                      @"Cochin-Bold",
                      @"Courier-BoldOblique",
                      @"Damascus-Bold",
                      @"Georgia-Bold",
                      @"GillSans-BoldItalic",
                      @"Helvetica-BoldOblique",
                      @"HelveticaNeue-MediumItalic",
                      @"Kailasa-Bold",
                      @"Marion-Bold",
                      @"Menlo-BoldItalic",
                      @"Noteworthy-Bold",
                      @"Optima-Bold",
                      @"Palatino-BoldItalic",
                      @"Thonburi-Bold",
                      @"TimesNewRomanPS-BoldItalicMT",
                      @"Verdana-BoldItalic",
                      @"Zapfino",
                      nil];
    int row = 0;
    for (NSString *name in self.availableFonts) {
        if ([name isEqualToString:fontName]) {
            selectedFontRow = row;
        }
        row++;
    }
    self.availableFontSizes = [NSMutableArray array];
    for (int i = 9; i <= 36; i++) {
        if (i == [fontSize intValue]) {
            selectedFontSizeRow = i - 9;
        }
        [self.availableFontSizes addObject:[NSNumber numberWithInt:i]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // set the initial values for the picker, and update the sample text font/size
    [self.picker selectRow:selectedFontRow inComponent:0 animated:YES];
    [self.picker selectRow:selectedFontSizeRow inComponent:1 animated:YES];
    NSNumber *size = [self.availableFontSizes objectAtIndex:selectedFontSizeRow];
    self.textView.font = [UIFont fontWithName:[self.availableFonts objectAtIndex:selectedFontRow] size:[size floatValue]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *size = [self.availableFontSizes objectAtIndex:selectedFontSizeRow];
    [defaults setObject:size forKey:kReadsyFontSize];
    [defaults setObject:[self.availableFonts objectAtIndex:selectedFontRow] forKey:kReadsyFontName];
    [defaults setObject:[self.boldFonts objectAtIndex:selectedFontRow] forKey:kReadsyBoldFontName];
    [defaults synchronize];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Picker delegate and datasource
/*
 * Picker has two components. Component zero is the font name, component 1 is the font size.
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger count;
    switch (component) {
        case 0:
            count = self.availableFonts.count;
            break;
        case 1:
            count = self.availableFontSizes.count;
            break;
    }
    return count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title;
    switch (component) {
        case 0:
            title = [self.availableFonts objectAtIndex:row];
            break;
        case 1:
            title = [NSString stringWithFormat:@"%@", [self.availableFontSizes objectAtIndex:row]];
            break;
    }
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            selectedFontRow = row;
            break;
        case 1:
            selectedFontSizeRow = row;
            break;
    }
    NSNumber *size = [self.availableFontSizes objectAtIndex:selectedFontSizeRow];
    self.textView.font = [UIFont fontWithName:[self.availableFonts objectAtIndex:selectedFontRow] size:[size floatValue]];
}

@end
