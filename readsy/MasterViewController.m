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

@interface MasterViewController () {
    NSMutableArray *_objects;
    int _workCounter;
}
@end

@implementation MasterViewController
@synthesize restClient = _restClient;

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
    
    if (!_objects) {
        NSLog(@"OBJECTS ARRAY IS NULL - WILL LOAD DATA");
        _objects = [NSMutableArray array];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.restClient loadMetadata:@"/"];
    }
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.restClient cancelAllRequests];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"**********************MEMORY WARNING");
}

//- (void)insertNewObject:(id)sender
//{
//    if (!_objects) {
//        _objects = [[NSMutableArray alloc] init];
//    }
//    [_objects insertObject:[NSDate date] atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//}


#pragma mark - Dropbox Access
- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

/*
 * Callback when directory metadata has been loaded.
 */
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    NSMutableArray *array = [NSMutableArray array];
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            [array addObject:file.filename];
        }
        _workCounter = (int)array.count;
        NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        for (NSString *file in sortedArray) {
            ReadsyMetadata *rm = [[ReadsyMetadata alloc] initWithSourceDirectory:file];
            [_objects addObject:rm];
            
            NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file];
            [self.restClient loadFile:[NSString stringWithFormat:@"/%@/metadata", file] intoPath:tmpFile];
        }
        //        for (DBMetadata *file in metadata.contents) {
        //            NSString *tmpFile = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), file.filename];
        //            [self.restClient loadFile:[NSString stringWithFormat:@"/%@/metadata", file.filename] intoPath:tmpFile];
        //        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self showErrorMessage];
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    _workCounter--;
    if (_workCounter == 0) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
    NSError *error;
    NSString *readsyMetadata = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"There was an error reading the file - %@", error);
        [self showErrorMessage];
    } else {
        for (ReadsyMetadata *rm in _objects) {
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
    _workCounter--;
    if (_workCounter == 0) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
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
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    ReadsyMetadata *rm = (ReadsyMetadata *) _objects[indexPath.row];
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


//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [_objects removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
//    }
//}

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
        ReadsyMetadata *object = _objects[indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ReadsyMetadata *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
        [[segue destinationViewController] setTitle:object.fileShortDescription];
    }
}


@end
