//
//  DataFileViewController.m
//  readsy
//
//  Created by Jeremy Brooks on 1/16/15.
//  Copyright (c) 2015 Jeremy Brooks. All rights reserved.
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
    
    if (!self.restClient) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    
    // Do any additional setup after loading the view.
    NSLog(@"DATA FILE IS %@", self.dataFile);
    
    if (self.dataFile) {
        [self startInstall];
    } else {
        // a nil dataFile indicates that an upload was in progress
        // attempt to set the data directory based on the value saved in UserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.dataDirectory = [defaults objectForKey:kDataUploadInProgress];
        if (self.dataDirectory) {
            NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"data"];
            self.dataDirectoryPath = [NSString stringWithFormat:@"%@/%@", tmpFile, self.dataDirectory];
            [self startFileUploads];
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) startInstall {
    // unzip files
    NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"data"];
    NSString *source = [NSString stringWithFormat:@"%s", [self.dataFile fileSystemRepresentation]];
    [SSZipArchive unzipFileAtPath:source toDestination:tmpFile];
    
    // delete data file archive
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtURL:self.dataFile error:&error];
    if (error) {
        [self handleError:@"Unable to delete source file."];
    }
    
    // get the directory that was unzipped
    NSArray *files = [fileManager contentsOfDirectoryAtPath:tmpFile error:&error];
    if (error) {
        [self handleError:@"Error listing archive contents."];
    } else if (files.count == 0) {
        [self handleError:@"No directories in archive."];
    } else {
        // data directory is the name of the directory holding the data files
        self.dataDirectory = [files objectAtIndex:0];
        
        // this is the full path to the data directory
        self.dataDirectoryPath = [NSString stringWithFormat:@"%@/%@", tmpFile, self.dataDirectory];
        
        // save the data directory to indicate an upload is in progress
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.dataDirectory forKey:kDataUploadInProgress];
        [defaults synchronize];
    }
    
    // update UI
    self.statusLabel.text = @"Checking dropbox...";
    
    // kick off a dropbox file listing
    [self.restClient loadMetadata:@"/"];
}


#pragma  mark - Dropbox callbacks

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"GOT %@", file.filename);
            if ([file.filename isEqualToString:self.dataDirectory]) {
                [self handleError:[NSString stringWithFormat:@"Data for '%@' is already installed.", self.dataDirectory]];
            }
        }
        
        // no match, see if we have started copying to a temp directory
        NSString *tempDir = [NSString stringWithFormat:@"/%@_tmp_", self.dataDirectory];
        for (DBMetadata *file in metadata.contents) {
            if ([file.filename isEqualToString:tempDir]) {
                tempDir = nil;
            }
        }
        // if tempDir was not set to nil, we can create it
        // otherwise, continue with file uploads
        if (tempDir) {
            [self.restClient createFolder:tempDir];
        } else {
            [self startFileUploads];
        }
    }
}

- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder {
    // folder was created, so start uploading files
    NSLog(@"Created folder %@", folder);
    [self startFileUploads];
}



- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error {
    [self handleError:[NSString stringWithFormat:@"Unable to create folder in Dropbox."]];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
    NSLog(@"UPLOADED FILE %@", destPath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *file = [NSString stringWithFormat:@"/%@/%@", self.dataDirectoryPath, [destPath lastPathComponent]];
    NSLog(@"DELETE %@", file);
    [fileManager removeItemAtPath:file error:&error];
    if (error) {
        NSLog(@"Error deleting file %@: %@", file, error);
    }
  
    NSInteger number = 365 - self.uploadFileList.count;
    
    self.statusProgress.progress = number/365.0;
    self.statusLabel.text = [NSString stringWithFormat:@"Uploading %ld/365, please wait...", (long)number];
    [self uploadAFile];
}
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"ERROR UPLOADING FILE %@", error);
    [self handleError:@"Error uploading files."];
}


- (void)startFileUploads {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    self.uploadFileList = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:self.dataDirectoryPath
                                                                                          error:&error]];
    
    
    if (error) {
        [self handleError:@"Error getting listing of files."];
    } else {
        self.statusLabel.text = @"Uploading 1/365, please wait...";
        [self.statusSpinner stopAnimating];
        self.statusProgress.progress = 0.0;
        self.statusProgress.hidden = NO;
        
        [self uploadAFile];
    }
}


- (void) uploadAFile {
    if (self.uploadFileList.count > 0) {
        NSString *destPath = [NSString stringWithFormat:@"/%@_tmp_", self.dataDirectory];
        NSString *filename = [self.uploadFileList objectAtIndex:0];
        [self.uploadFileList removeObjectAtIndex:0];
        NSString *source = [NSString stringWithFormat:@"%@/%@", self.dataDirectoryPath, filename];
        [self.restClient uploadFile:filename toPath:destPath withParentRev:nil fromPath:source];
    } else {
        self.statusLabel.text = @"Cleaning up...";
        
        // delete local temp data on the device
        NSString *tmpFile = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"data"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        [fileManager removeItemAtPath:tmpFile error:&error];
        if (error) {
            NSLog(@"Unable to delete temp directory %@", tmpFile);
        }
        
        // move the temp directory on Dropbox to the correct name
        [self.restClient moveFrom:[NSString stringWithFormat:@"/%@_tmp_", self.dataDirectory]
                           toPath:[NSString stringWithFormat:@"/%@", self.dataDirectory]];
    }
}

// Dropbox callback -- this indicates that the temp directory has been moved successfully, and we are done
- (void)restClient:(DBRestClient *)client movedPath:(NSString *)from_path to:(DBMetadata *)result {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kDataUploadInProgress];
    [defaults synchronize];
    
    self.statusLabel.text = @"Complete";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Complete"
                                                                   message:@"Files have been uploaded"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                                                   [self.dataFileDelegate dataLoadFinished:YES];
                                                   [self.navigationController popViewControllerAnimated:YES];
                                               }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// Dropbox callback -- this indicates that the temp directory move failed
- (void)restClient:(DBRestClient *)client movePathFailedWithError:(NSError *)error {
    [self handleError:@"Files have been copied to Dropbox, but directory rename failed. You may be able to rename the directory manually on Dropbox. Look for a directory that ends with '_tmp_', and remove the '_tmp'."];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
