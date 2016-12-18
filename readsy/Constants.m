//
//  Constants.m
//  readsy
//
//  Created by Jeremy Brooks on 12/11/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import "Constants.h"

@implementation Constants
NSString* const kReadsyFontSize = @"kReadsyFontSize";
NSString* const kReadsyFontName = @"kReadsyFontName";
NSString* const kReadsyBoldFontName = @"kReadsyBoldFontName";
NSString * const kDidShowTipDetailView = @"kDidShowTipDetailView";
NSString *const kDidShowTipInfoView = @"kDidShowTipInfoView";
NSString *const kRemindersEnabled = @"kRemindersEnabled";
NSString *const kReminderTime = @"kReminderTime";

NSString *const kDataUploadInProgress = @"kDataUploadInProgress";

NSString* const DefaultFontName = @"Helvetica Neue";
NSString* const DefaultBoldFontName = @"HelveticaNeue-MediumItalic";
NSInteger const DefaultFontSize = 14;
NSString * const FeedbackEmailAddress = @"readsy@jeremybrooks.net";
NSString * const FeedbackEmailSubject = @"readsy feedback";

NSString * const ReadsyHelpURL = @"http://jeremybrooks.net/readsy/faq.html";
NSString * const ReadsyMobileDownloadURL = @"http://jeremybrooks.net/readsy/mobile.html";

NSString * const HelpText = @"readsy is designed to help you read something every day.\n\nThe Library view will show the readsy data that is in your Dropbox. Tap a row to see the entry for the day.\n\nWhen viewing an entry, you can navigate to previous and next days by swiping left and right on the screen. To return to the current day's entry, shake the device.\n\nWhen you have read the entry for a day, tap the switch to mark it as read. The main screen will let you know if you have any unread items.\n\nFor more help, visit the readsy web site at http://jeremybrooks.net/readsy/faq.html.\n\nTo download data files, visit http://jeremybrooks.net/readsy/mobile.html.";

NSString * const CreditsText = @"readsy uses the following libraries:\n  SSZipArchive by Sam Soffes\n  ObjectiveDropboxOfficial by Dropbox, Inc.\n  KAProgressLabel by Alexis Creuzot\n\nreadsy is not affiliated with or otherwise sponsored by Dropbox, Inc.";
@end
