//
//  DataFileViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 1/16/15.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import "DataFileViewController.h"
#import "SSZipArchive.h"
#import "MasterViewController.h"
#import "Constants.h"

@interface DataFileViewController ()

@end

@implementation DataFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"DATA FILE IS %@", self.dataFile);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    self.installDirectory = [documentsDirectory stringByAppendingPathComponent:@"/install"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // if a data file was provided, AND the install directory already exists,
    // confirm that the process should continue
    if (self.dataFile && [[NSFileManager defaultManager] fileExistsAtPath:self.installDirectory]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Install In Progress"
                                                                       message:@"There may be a different data file installation that has not completed. Would you like to continue with this installation and abandon the other one?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [[NSFileManager defaultManager] removeItemAtPath:self.installDirectory
                                                                                               error:nil];
                                                    [self startInstall];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
                                                    [self.navigationController popViewControllerAnimated:YES];
                                                }]];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
        
    // else if a data file was provided, start the install process
    } else if (self.dataFile) {
        [self startInstall];
        
    // else continue any in progress installs
    } else {
        // set the data directory based on the value saved in UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.dataDirectory = [defaults objectForKey:kDataUploadInProgress];
        if (self.dataDirectory) {
            self.dataDirectoryPath = [self.installDirectory stringByAppendingPathComponent:self.dataDirectory];
            [self startFileUpload];
        } else {
            // this should not happen... no data file to work on, and no value saved in user defaults
            // to tell us what we were uploading.
            // warn user, and try to clean things up.
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDataUploadInProgress];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSFileManager defaultManager] removeItemAtPath:self.installDirectory error:nil];
            [self handleError:@"Data file upload is in an inconsistent state. Please try installing the data file again."];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) startInstall {
    // unzip files
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.installDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.installDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
    }
    
    if (error) {
        [self handleError:@"Unable to create local install directory."];
    }
    
    NSString *source = [NSString stringWithFormat:@"%s", [self.dataFile fileSystemRepresentation]];
    [SSZipArchive unzipFileAtPath:source toDestination:self.installDirectory];
    
    // delete data file archive
    // ignore errors - they won't affect operation
    [[NSFileManager defaultManager] removeItemAtURL:self.dataFile
                                              error:nil];
    
    // get the directory that was unzipped
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.installDirectory
                                                      error:&error];
    if (error) {
        [self handleError:@"Error listing archive contents."];
    } else if (files.count == 0) {
        [self handleError:@"No directories in archive."];
    } else {
        // data directory is the name of the directory holding the data files
        self.dataDirectory = [files objectAtIndex:0];
        
        // this is the full path to the data directory
        self.dataDirectoryPath = [self.installDirectory stringByAppendingPathComponent:self.dataDirectory];
        
        // save the data directory to indicate an upload is in progress
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.dataDirectory forKey:kDataUploadInProgress];
        [defaults synchronize];
    }
    
    // update UI
    self.statusLabel.text = @"Checking dropbox...";
    
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    [[client.filesRoutes listFolder:@""] response:^(DBFILESListFolderResult * result, DBFILESListFolderError * routeError, DBRequestError * error) {
        if (result) {
            BOOL installed = NO;
            for (DBFILESMetadata *entry in result.entries) {
                if ([entry.name isEqualToString:self.dataDirectory]) {
                    installed = YES;
                }
            }
            if (installed) {
                // already installed, so remove install directory and in progress key
                [[NSFileManager defaultManager] removeItemAtPath:self.installDirectory
                                                           error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDataUploadInProgress];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self handleError:[NSString stringWithFormat:@"Data for '%@' is already installed.", self.dataDirectory]];
            } else {
                // not installed, check for existing temp directory
                NSString *tmpDir = [NSString stringWithFormat:@"/%@_tmp_", self.dataDirectory];
                for (DBFILESMetadata *entry in result.entries) {
                    if ([entry.name isEqualToString:tmpDir]) {
                        tmpDir = nil;   // set to nil if it exists
                    }
                }
                // if tmpdir is not nil, it does not exist, so we create it
                if (tmpDir) {
                    [[client.filesRoutes createFolder:tmpDir] response:^(DBFILESFolderMetadata *result, DBFILESCreateFolderError *routeError, DBRequestError *error) {
                        if (routeError || error) {
                            [self handleError:[NSString stringWithFormat:@"Could not create directory '%@' on Dropbox.", tmpDir]];
                        } else {
                            [self startFileUpload];
                        }
                    }];
                }
            }
            
        } else {
            [self handleError:@"Error communicating with Dropbox."];
        }
    }];
}

- (void)startFileUpload
{
    NSError *error;
    self.uploadFileList = [NSMutableArray arrayWithArray:
                           [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.dataDirectoryPath
                                                                               error:&error]];

    if (error) {
        [self handleError:@"Error getting listing of files."];
    } else {
        self.statusLabel.text = @"Preparing to upload, please wait...";
        [self.statusSpinner stopAnimating];
        self.statusProgress.progress = 0.0;
        self.statusProgress.hidden = NO;
        self.listSize = self.uploadFileList.count;
        self.uploadCount = 1;
        
        [self uploadNextFile];
    }
}

- (void)uploadNextFile
{
    DropboxClient *client = [DropboxClientsManager authorizedClient];
    DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithOverwrite];
    self.statusLabel.text = [NSString stringWithFormat:@"Uploading %ld/%ld, please wait...", (long)self.uploadCount, (long)self.listSize];
    
    if (self.uploadFileList.count > 0) {
        NSString *file = [self.uploadFileList objectAtIndex:0];
        [self.uploadFileList removeObjectAtIndex:0];
        
        NSString *remoteFile = [NSString stringWithFormat:@"/%@_tmp_/%@", self.dataDirectory, file];
        NSString *localFile = [NSString stringWithFormat:@"%@/%@", self.dataDirectoryPath, file];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:localFile];
        [[client.filesRoutes uploadData:remoteFile
                                   mode:mode
                             autorename:nil
                         clientModified:nil
                                   mute:nil
                              inputData:data] response:^(DBFILESFileMetadata * _Nullable result, DBFILESUploadError * _Nullable routeError, DBRequestError * _Nullable error) {
            if (result) {
                [[NSFileManager defaultManager] removeItemAtPath:localFile
                                                           error:nil];
                self.statusProgress.progress = self.uploadCount/(float)self.listSize;
                self.uploadCount = self.uploadCount + 1;
                [self uploadNextFile];
            } else {
                [self handleError:@"There was a error during upload. Please try again later."];
            }
        }];
    } else {
        self.statusProgress.progress = 1.0;
        self.statusLabel.text = @"Upload complete.";
        [[NSFileManager defaultManager] removeItemAtPath:self.installDirectory error:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDataUploadInProgress];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [client.filesRoutes move:[NSString stringWithFormat:@"/%@_tmp_", self.dataDirectory]
                          toPath:[NSString stringWithFormat:@"/%@", self.dataDirectory]];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Finished"
                                                                       message:[NSString stringWithFormat:@"Upload of data for %@ is complete. Refresh the Library list to see the new content.", self.dataDirectory]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self.navigationController popViewControllerAnimated:YES];
                                                }]];
        [self.navigationController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    }
}

-(void)handleError:(NSString *)message {
    [self.statusSpinner stopAnimating];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self.navigationController popViewControllerAnimated:YES];
                                                   }];
    [alert addAction:action];
    
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end
