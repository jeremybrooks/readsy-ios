//
//  MasterViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "ReadsyMetadata.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    //self.navigationItem.rightBarButtonItem = addButton;
    
    if (!self.objects) {
        self.objects = [NSMutableArray array];
    }
    [self.refreshControl addTarget:self
                            action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

/*
 * When the view is ready to appear, call initDropbox.
 * This will ensure that a dropbox client is created and the view is set up
 * in the case where the user comes back from settings.
 */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDropbox];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[self tableView] reloadData];
}

- (void)initDropbox
{
    if ([[DBSession sharedSession] isLinked]) {
        if (!self.restClient) {
            self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
            self.restClient.delegate = self;
            NSLog(@"Dropbox client created");
        }
        
        if (self.objects.count == 0) {
            [self refresh];
        }
    } else {
        // Dropbox is not linked
        // if the user unlinked the account, we will need to get rid of any dropbox client,
        // clear out the data model,
        // and refresh the table view
//        [self.refreshControl endRefreshing];
        [self hideAllActivityIndicators];
        if (self.restClient) {
            self.restClient = nil;
        }
        if (self.objects.count > 0) {
            [self.objects removeAllObjects];
            [[self tableView] reloadData];
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dropbox Not Linked"
                                                        message:@"There is no Dropbox account linked with readsy. To link your Dropbox account, tap Settings."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
}

- (void)refresh
{
    if ([[DBSession sharedSession] isLinked]) {
        [self.objects removeAllObjects];
        [self showActivityIndicators:YES];
//        [AppDelegate setActivityIndicatorsVisible:YES];
//        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [self.restClient loadMetadata:@"/"];
    } else {
        // Dropbox is not linked
        // if the user unlinked the account, we will need to get rid of any dropbox client,
        // clear out the data model,
        // and refresh the table view
//        [self.refreshControl endRefreshing];
        [self hideAllActivityIndicators];
        if (self.restClient) {
            self.restClient = nil;
        }
        if (self.objects.count > 0) {
            [self.objects removeAllObjects];
            [[self tableView] reloadData];
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dropbox Not Linked"
                                                        message:@"There is no Dropbox account linked with readsy. To link your Dropbox account, tap Settings."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [self.refreshControl endRefreshing];
    [self hideAllActivityIndicators];
//    [AppDelegate stopAllActivityIndicators];
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.restClient cancelAllRequests];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"**********************MEMORY WARNING");
}

#pragma mark - Dropbox Access
/*
 * Callback when directory metadata has been loaded.
 */
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    [self showActivityIndicators:NO];
//    [AppDelegate setActivityIndicatorsVisible:NO];
    NSMutableArray *array = [NSMutableArray array];
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            [array addObject:file.filename];
        }
//        self.workCounter = (int)array.count;
        NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        for (NSString *file in sortedArray) {
            ReadsyMetadata *rm = [[ReadsyMetadata alloc] initWithSourceDirectory:file];
            [self.objects addObject:rm];
            
            NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file];
            [self showActivityIndicators:YES];
//            [AppDelegate setActivityIndicatorsVisible:YES];
            [self.restClient loadFile:[NSString stringWithFormat:@"/%@/metadata", file] intoPath:tmpFile];
        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
//    [self.refreshControl endRefreshing];
    [self showActivityIndicators:NO];
//    [AppDelegate setActivityIndicatorsVisible:NO];
//    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self showErrorMessage];
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    [self showActivityIndicators:NO];
//    [AppDelegate setActivityIndicatorsVisible:NO];
//    self.workCounter--;
//    if (self.workCounter == 0) {
//        [self.refreshControl endRefreshing];
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//    }
    NSError *error;
    NSString *readsyMetadata = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"There was an error reading the file - %@", error);
        [self showErrorMessage];
    } else {
        for (ReadsyMetadata *rm in self.objects) {
            if ([rm.sourceDirectory isEqualToString:[localPath lastPathComponent]]) {
                [rm setMetadata:readsyMetadata];
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
        if (error) {
            NSLog(@"Could not delete temp file. %@", error);
        }
    }
    [self.tableView reloadData];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    [self showActivityIndicators:NO];
//    [AppDelegate setActivityIndicatorsVisible:NO];
//    self.workCounter--;
//    if (self.workCounter == 0) {
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//    }
    NSLog(@"There was an error loading the file - %@", error);
    [self showErrorMessage];
}

- (void)showErrorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"There was an error while communicating with Dropbox. There may be a network problem."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    NSLog(@"IN MASTER VIEW: shouldHideViewController");
    return NO;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    ReadsyMetadata *rm = (ReadsyMetadata *) [self.objects objectAtIndex:indexPath.row];
    if (rm.fileDescription) {
        cell.textLabel.text = rm.fileDescription;
        int count = [rm getUnreadCountForDate:[NSDate date]];
        if (count == 0) {
            cell.detailTextLabel.text = @"You are all up to date!";
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"There are %d unread items", count];
        }
    }
    return cell;
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        ReadsyMetadata *object = [self.objects objectAtIndex:indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ReadsyMetadata *object = [self.objects objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
        [[segue destinationViewController] setTitle:object.fileShortDescription];
    }
}

#pragma mark - Activity indicator stuff
- (void)showActivityIndicators:(BOOL)showIndicators
{
    [self showActivityIndicators:showIndicators andReset:NO];
}
- (void)hideAllActivityIndicators
{
    [self showActivityIndicators:NO andReset:YES];
}

- (void)showActivityIndicators:(BOOL)showIndicators andReset:(BOOL)reset
{
    static NSInteger callCount = 0;
    if (showIndicators) {
        callCount++;
    } else {
        callCount--;
    }
    if (reset) {
        callCount = 0;
    }
    
    if (callCount > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        self.navigationItem.title = @"Loading...";
//        if (callCount == 1) {
//            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        }
    }
    if (callCount <= 0) {
        callCount = 0;
        [self.refreshControl endRefreshing];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.navigationItem.title = @"Library";
//        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
}

@end
