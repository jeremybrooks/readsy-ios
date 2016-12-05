//
//  ReadsyMetadata.h
//  readsy
//
//  Created by Jeremy Brooks on 11/22/13.
//  Copyright (c) 2013-2016 Jeremy Brooks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadsyMetadata : NSObject
@property (strong, nonatomic) NSString *version;
@property (strong, nonatomic) NSString *year;
@property (strong, nonatomic) NSString *fileDescription;
@property (strong, nonatomic) NSString *read;
@property (strong, nonatomic) NSString *fileShortDescription;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSString *sourceDirectory;
@property (strong, nonatomic) NSData *readBytes;

- (id)initWithSourceDirectory:(NSString *)sourceDirectory;
- (id)initWithMetadata:(NSString *)metadata;

- (void)setMetadata:(NSString *)metadata;

- (BOOL)isRead:(NSDate *)date;
- (void)setReadFlag:(BOOL)read forDate:(NSDate *)date;
- (int)getUnreadCountForDate:(NSDate *)date;

- (BOOL) dataValidForDate:(NSDate *)date;

- (NSString *)descriptionInPropertiesFormat;
@end


