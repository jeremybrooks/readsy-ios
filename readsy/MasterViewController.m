//
//  MasterViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "DataFileViewController.h"
#import "ReadsyMetadata.h"
#import "AppDelegate.h"
#import "Constants.h"

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (!self.objects) {
        self.objects = [NSMutableArray array];
    }
    [self.refreshControl addTarget:self
                            action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
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
    
    // check for pending file uploads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kDataUploadInProgress]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Continue?"
                                                                       message:@"There is a data file upload in progress. Would you like to continue uploading files now?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        [self performSegueWithIdentifier:@"handleDataFile" sender:nil];
                                                    }]];
        [alert addAction: [UIAlertAction actionWithTitle:@"Later"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Stop Trying"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
                                                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                                    NSString *documentsDirectory = [paths objectAtIndex:0];
                                                    NSString *installDirectory = [documentsDirectory stringByAppendingPathComponent:@"/install"];
                                                    [[NSFileManager defaultManager] removeItemAtPath:installDirectory error:nil];
                                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                    [defaults removeObjectForKey:kDataUploadInProgress];
                                                    [defaults synchronize];
                                                }]];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    }
}

- (void)initDropbox
{
    if ([DropboxClientsManager authorizedClient] == nil) {
        [self hideAllActivityIndicators];
        if (self.objects.count > 0) {
            [self.objects removeAllObjects];
            [[self tableView] reloadData];
        }
        [self showDropboxNotLinkedAlert];
    } else {
        if (self.objects.count == 0) {
            [self refresh];
        }
    }
}

- (void)refresh
{
    if (self.objects.count > 0) {
        [self.objects removeAllObjects];
        [[self tableView] reloadData];
    }
    DropboxClient * client = [DropboxClientsManager authorizedClient];
    if (client == nil) {
        [self hideAllActivityIndicators];
        [self showDropboxNotLinkedAlert];
    } else {
        [self showActivityIndicators:YES];
        [[client.filesRoutes listFolder:@""] response:^(DBFILESListFolderResult *result, DBFILESListFolderError *routeError, DBError *error) {
            if (result) {
                if (result.entries.count == 0) {
                    [self hideAllActivityIndicators];
                    [self showNoContentMessage];
                } else {
                    // add entries to an array, then sort
                    NSMutableArray *array = [NSMutableArray array];
                    for (DBFILESMetadata *entry in result.entries) {
                        if ([entry.name hasSuffix:@"_tmp_"]) {
                            NSLog(@"Skipping incomplete upload '%@'", entry.name);
                        } else {
                            [array addObject:entry.name];
                        }
                    }
                    NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                    
                    // now get metadata for the sorted entries
                    for (NSString *name in sortedArray) {
                        ReadsyMetadata *rm = [[ReadsyMetadata alloc] initWithSourceDirectory:name];
                        [self.objects addObject:rm];
                        [self.tableView reloadData];
                        NSString *metadataPath = [NSString stringWithFormat:@"/%@/metadata", name];
                        [[client.filesRoutes downloadData:metadataPath]
                         response:^(DBFILESFileMetadata *result, DBFILESDownloadError *routeError, DBError *error, NSData *fileData) {
                             if (result) {
                                 NSString *metadata = [[NSString alloc] initWithData:fileData
                                                                            encoding:NSUTF8StringEncoding];
                                 [rm setMetadata:metadata];
                                 [self.tableView reloadData];
                             } else {
                                 NSString *errorMessage = [NSString stringWithFormat:@"Error reading file '/%@/metadata' from Dropbox.", name];
                                 [self showErrorMessage:errorMessage];
                             }
                         }];
                    }
                    
                    [self hideAllActivityIndicators];
                }
            } else {
                [self hideAllActivityIndicators];
                UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:@"Error"
                                                    message:@"Error reading directory"
                                             preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert
                                   animated:YES
                                 completion:nil];
            }
        }];
    }
}

-(void)showDropboxNotLinkedAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dropbox Not Linked"
                                                                   message:@"There is no Dropbox account linked with readsy. To link your Dropbox account, tap Settings. Would you like to go to settings now?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self performSegueWithIdentifier:@"showSettingsSegue" sender:nil];
                                                }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                                 style:UIAlertActionStyleCancel
                                               handler:nil]];
    
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self hideAllActivityIndicators];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"**********************MEMORY WARNING");
}

- (void)showNoContentMessage
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nothing To Read"
                                                                   message:@"It looks like you do not have any data files in Dropbox. To learn more about how to install and create data files, visit the readsy website."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Visit Website"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ReadsyMobileDownloadURL]];
                                                }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Not Now"
                                                 style:UIAlertActionStyleCancel
                                               handler:nil]];
    
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}

- (void)showErrorMessage: (NSString *)message {
    if (!message) {
        message = @"There was an error while communicating with Dropbox. There may be a network problem.";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:nil];
    [alert addAction:ok];
    [self.navigationController presentViewController:alert
                                            animated:YES
                                          completion:nil];
}

#pragma mark - Dropbox Access
/*
 * Callback when directory metadata has been loaded.
 */
//- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
//{
//    [self showActivityIndicators:NO];
//    NSMutableArray *array = [NSMutableArray array];
//    if (metadata.isDirectory) {
//        for (DBMetadata *file in metadata.contents) {
//            [array addObject:file.filename];
//        }
//        if (array.count == 0) {
//            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nothing To Read"
//                                                                           message:@"It looks like you do not have any data files in Dropbox. To learn more about how to install and create data files, visit the readsy website."
//                                                                    preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Visit Website"
//                                                          style:UIAlertActionStyleDefault
//                                                        handler:^(UIAlertAction *action) {
//                                                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ReadsyMobileDownloadURL]];
//                                                        }];
//            UIAlertAction *no = [UIAlertAction actionWithTitle:@"Not Now"
//                                                         style:UIAlertActionStyleCancel
//                                                       handler:nil];
//            [alert addAction:yes];
//            [alert addAction:no];
//            [self.navigationController presentViewController:alert
//                                                    animated:YES
//                                                  completion:nil];
//        } else {
//            NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//
//            for (NSString *file in sortedArray) {
//                if ([file hasSuffix:@"_tmp_"]) {
//                    NSLog(@"Skipping incomplete upload '%@'", file);
//                } else {
//                    ReadsyMetadata *rm = [[ReadsyMetadata alloc] initWithSourceDirectory:file];
//                    [self.objects addObject:rm];
//                    [self.tableView reloadData];
//                    NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file];
//                    [self showActivityIndicators:YES];
//                    //            [AppDelegate setActivityIndicatorsVisible:YES];
//                    [self.restClient loadFile:[NSString stringWithFormat:@"/%@/metadata", file] intoPath:tmpFile];
//                }
//            }
//        }
//    }
//}
//
//- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
//{
//    [self showActivityIndicators:NO];
//    [self showErrorMessage:nil];
//    NSLog(@"Error loading metadata: %@", error);
//}
//
//- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
//       contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
//    [self showActivityIndicators:NO];
//    NSError *error;
//    NSString *readsyMetadata = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
//    if (error) {
//        [self showErrorMessage:[NSString stringWithFormat:@"Unable to read file '%@'.", localPath]];
//    } else {
//        for (ReadsyMetadata *rm in self.objects) {
//            if ([rm.sourceDirectory isEqualToString:[localPath lastPathComponent]]) {
//                [rm setMetadata:readsyMetadata];
//            }
//        }
//        [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
//        if (error) {
//            NSLog(@"Could not delete temp file. %@", error);
//        }
//    }
//    [self.tableView reloadData];
//}
//
//- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
//    [self showActivityIndicators:NO];
//    NSString *message = nil;
//    // if we cannot load metadata, we look at the error message
//    // and determine the path of the file we were loading.
//    //
//    // Then, we try to remove that ReadsyMetadata object from the data model,
//    // and refresh the table view so that it doesn't show a stuck "Loading" message
//    // for the failed load.
//    //
//    // The path dictionary entry looks like this: "path=/Test/metadata" -- we need path component number 1, not 0,
//    // because 0 would be the leading "/"
//    NSString *sourceDirFailed = [[[[error userInfo] objectForKey:@"path"] pathComponents] objectAtIndex:1];
//    if (sourceDirFailed) {
//        message = [NSString stringWithFormat:@"Unable to load file '%@' from Dropbox. This may be due to a network error, or to missing files on Dropbox.", sourceDirFailed];
//        for (ReadsyMetadata *rm in self.objects) {
//            if ([rm.sourceDirectory isEqualToString:sourceDirFailed]) {
//                [self.objects removeObject:rm];
//            }
//            [self.tableView reloadData];
//        }
//    }
//
//    [self showErrorMessage:message];
//}
//
//- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
//    NSLog(@"Delete path '%@' successful", path);
//}
//
//- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Failed"
//                                                                   message:@"Unable to delete the data from Dropbox at this time. Try again later."
//                                                            preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
//                                                 style:UIAlertActionStyleDefault
//                                               handler:^(UIAlertAction *action) {
//                                                   [self refresh];
//                                               }];
//    [alert addAction:ok];
//    [self presentViewController:alert
//                       animated:YES
//                     completion:nil];
//}



//-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
//{
//    NSLog(@"IN MASTER VIEW: shouldHideViewController");
//    return NO;
//}

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
            if (count == 1) {
                cell.detailTextLabel.text = @"There is 1 unread item";
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"There are %d unread items", count];
            }
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ReadsyMetadata *rm = [self.objects objectAtIndex:indexPath.row];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?"
                                                                       message:[NSString stringWithFormat:@"You are about to delete %@. This will remove the data from Dropbox. Are you sure?", rm.fileDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction *action) {
                                                       DropboxClient *client = [DropboxClientsManager authorizedClient];
                                                       [client.filesRoutes delete_:[NSString stringWithFormat:@"/%@", rm.sourceDirectory]];
                                                       
                                                       [self.objects removeObjectAtIndex:indexPath.row];
                                                       [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                                        withRowAnimation:UITableViewRowAnimationFade];
                                                   }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [tableView setEditing:NO animated:YES];
                                                       }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ReadsyMetadata *object = [self.objects objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
        [[segue destinationViewController] setTitle:object.fileShortDescription];
    } else if ([[segue identifier] isEqualToString:@"handleDataFile"]) {
        [[segue destinationViewController] setDataFileDelegate:self];
        [[segue destinationViewController] setDataFile:sender];
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
    }
    if (callCount <= 0) {
        callCount = 0;
        [self.refreshControl endRefreshing];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.navigationItem.title = @"Library";
    }
}

#pragma mark - Import data file methods
- (void)handleDataFile:(NSURL *)dataFile
{
    NSLog(@"Handling data file...");
    [self performSegueWithIdentifier:@"handleDataFile" sender:dataFile];
}

- (void)dataLoadFinished:(BOOL)finished {
    if (finished) {
        [self.objects removeAllObjects];
    }
}

@end
