//
//  ReadsyMetadata.m
//  readsy
//
//  Created by Jeremy Brooks on 11/22/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "ReadsyMetadata.h"

@implementation ReadsyMetadata
static NSString * const kVersion = @"version";
static NSString * const kYear = @"year";
static NSString * const kDescription = @"description";
static NSString * const kShortDescription = @"shortDescription";
static NSString * const kRead = @"read";

-(id)initWithSourceDirectory:(NSString *)sourceDirectory
{
    self = [self init];
    if (self) {
        self.date = [NSDate date];
        self.sourceDirectory = sourceDirectory;
    }
    return self;
}


-(id)initWithMetadata:(NSString *)metadata
{
    self = [self init];
    
    if (self) {
        self.date = [NSDate date];
        NSArray *lines = [metadata componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            NSArray *keyValue = [line componentsSeparatedByString:@"="];
            if ([keyValue count] == 2) {
                if ([[keyValue objectAtIndex:0]isEqualToString:kVersion]) {
                    self.version = [keyValue objectAtIndex:1];
                } else if ([[keyValue objectAtIndex:0] isEqualToString:kYear]) {
                    self.year = [keyValue objectAtIndex:1];
                } else if ([[keyValue objectAtIndex:0] isEqualToString:kDescription]) {
                    self.fileDescription = [keyValue objectAtIndex:1];
                } else if ([[keyValue objectAtIndex:0] isEqualToString:kShortDescription]) {
                    self.fileShortDescription = [keyValue objectAtIndex:1];
                } else if ([[keyValue objectAtIndex:0] isEqualToString:kRead]) {
                    self.read = [keyValue objectAtIndex:1];
                    self.readBytes = [self hexToBytes:self.read];
                }
            }
        }
    }
    
    return self;
}

-(void)setMetadata:(NSString *)metadata
{
    NSArray *lines = [metadata componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *keyValue = [line componentsSeparatedByString:@"="];
        if ([keyValue count] == 2) {
            if ([[keyValue objectAtIndex:0]isEqualToString:kVersion]) {
                self.version = [keyValue objectAtIndex:1];
            } else if ([[keyValue objectAtIndex:0] isEqualToString:kYear]) {
                self.year = [keyValue objectAtIndex:1];
            } else if ([[keyValue objectAtIndex:0] isEqualToString:kDescription]) {
                self.fileDescription = [keyValue objectAtIndex:1];
            } else if ([[keyValue objectAtIndex:0] isEqualToString:kShortDescription]) {
                self.fileShortDescription = [keyValue objectAtIndex:1];
            } else if ([[keyValue objectAtIndex:0] isEqualToString:kRead]) {
                self.read = [keyValue objectAtIndex:1];
                self.readBytes = [self hexToBytes:self.read];
            }
        }
    }
}

- (void)setRead:(NSString *)read
{
    _read = read;
    self.readBytes = [self hexToBytes:read];
}


- (BOOL)isRead:(NSDate *)date
{
    NSUInteger dayOfYear = [self calculateDayOfYear:date];
    NSRange range = NSMakeRange((dayOfYear-1)/8, 1);
    unsigned char buffer[1];
    [self.readBytes getBytes:&buffer range:range];

    int mask = pow(2, (dayOfYear-1)%8);
    return (buffer[0] & mask) == mask;
}

- (void)setReadFlag:(BOOL)read forDate:(NSDate *)date
{
    if (![self isRead:date] == read) {
        unsigned char buffer[46];
        [self.readBytes getBytes:&buffer];
        
        NSUInteger dayOfYear = [self calculateDayOfYear:date];
        int mask = pow(2, (dayOfYear-1)%8);
        int byte = (int)(dayOfYear-1)/8;
        
        buffer[byte] = buffer[byte] ^ mask;
        
        self.readBytes = [NSData dataWithBytes:&buffer length:46];
        
        NSString *byteString = [self.readBytes description];
        byteString = [byteString stringByReplacingOccurrencesOfString:@" " withString:@""];
        byteString = [byteString stringByReplacingOccurrencesOfString:@"<" withString:@""];
        self.read = [byteString stringByReplacingOccurrencesOfString:@">" withString:@""];
    }
}

/*
 * Get the number of unread items from day 1 up to and including the current day of the year.
 */
- (int)getUnreadCountForDate:(NSDate *)date
{
    int count = 0;
    if ([self dataValidForDate:date]) {
        int day = 1;
        NSUInteger dayOfYear = [self calculateDayOfYear:date];
        NSCalendar *calendar = [NSCalendar currentCalendar];

        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitDay
                                              fromDate:date];
                            
        while (day <= dayOfYear) {
            comps.day = day;
            if (![self isRead:[calendar dateFromComponents:comps]]) {
                count++;
            }
            day++;
        }
    }
    return count;
}


- (NSUInteger) calculateDayOfYear:(NSDate *)date
{
    NSUInteger dayOfYear = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit
                                                                   inUnit:NSYearCalendarUnit
                                                                  forDate:date];
    return dayOfYear;
}

- (BOOL) dataValidForDate:(NSDate *)date
{
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:date];
    return ( [self.year isEqualToString:@"0"] || ([comps year] == [self.year integerValue]) );
}


-(NSData*) hexToBytes:(NSString *)hexString {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= hexString.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"date=%@,version=%@,year=%@,description=%@,shortDescription=%@,read=%@,sourceDirectory=%@",
            self.date, self.version, self.year, self.fileDescription, self.fileShortDescription, self.read, self.sourceDirectory];
}

/*
 * The properties file should look like this
 
 #readsy-iOS
 #<date>
 version=1
 year=2013
 description=Examining the Scriptures Daily 2013
 read=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3f0000000000
 shortDescription=esd2013
 
 */
- (NSString *)descriptionInPropertiesFormat
{
    NSMutableString *properties = [[NSMutableString alloc] init];
    [properties appendString:@"#readsy iOS\n"];
    [properties appendString:[NSString stringWithFormat:@"#%@\n", [[NSDate date] description]]];
    [properties appendString:[NSString stringWithFormat:@"%@=%@\n", kVersion, self.version]];
    [properties appendString:[NSString stringWithFormat:@"%@=%@\n", kYear, self.year]];
    [properties appendString:[NSString stringWithFormat:@"%@=%@\n", kDescription, self.fileDescription]];
    [properties appendString:[NSString stringWithFormat:@"%@=%@\n", kRead, self.read]];
    [properties appendString:[NSString stringWithFormat:@"%@=%@", kShortDescription, self.fileShortDescription]];
    
    return properties;
}
@end
