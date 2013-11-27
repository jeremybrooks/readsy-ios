//
//  readsyTests.m
//  readsyTests
//
//  Created by Jeremy Brooks on 11/20/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ReadsyMetadata.h"

@interface readsyTests : XCTestCase

@end

@implementation readsyTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMdd"];
    NSDate *date = [format dateFromString:@"20130101"];
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    rm.read = @"01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    XCTAssertTrue([rm isRead:date], @"FAILED: returned false, should be true");
    
    rm.read = @"00020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    XCTAssertFalse([rm isRead:date], @"FAILED: returned true for 20130101 should be false.");
    
    date = [format dateFromString:@"20130109"];
    XCTAssertFalse([rm isRead:date], @"FAILED: should be false.");
    
    date = [format dateFromString:@"20130110"];
    XCTAssertTrue([rm isRead:date], @"FAILED: should be true.");
}

- (void)testKnownDays
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMdd"];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:2013];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    rm.read = @"04010000040000000008000000000000000200002000000000000200000080000000000000041000001000000010";
    int days[] = {3,9,35,76,138,166,210,248,299,309,333,365};
    
    for (int i = 1; i<=365; i++) {
        [comps setDay:i];
        NSDate *date = [calendar dateFromComponents:comps];
        BOOL isRead = [rm isRead:date];
        BOOL isDayInArray = NO;
        
        for (int x = 0; x < 12; x++) {
            if (days[x] == i) {
                isDayInArray = YES;
            }
        }
        XCTAssertEqual(isRead, isDayInArray, @"FAILED for day");
    }
    
}

- (void)testSetReadFlag
{
    NSString *zero = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    NSString *expected = @"04010000040000000008000000000000000200002000000000000200000080000000000000041000001000000010";
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:2013];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    rm.read = zero;
    
    int days[] = {3,9,35,76,138,166,210,248,299,309,333,365};
    
    for (int x = 0; x < 12; x++) {
        [comps setDay:days[x]];
        [rm setReadFlag:true forDate:[calendar dateFromComponents:comps]];
    }
    
    XCTAssertTrue([expected isEqualToString:rm.read], @"FAILED: Expected equal values");
}

- (void)testMod
{
    NSDate *now = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:now];
    NSLog(@"************* %ld", (long)[comps day]);
}

- (void)testDataValidForDate
{
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    // set year to 0; should be valid
    rm.year = @"0";
    XCTAssertTrue([rm dataValidForDate:[NSDate date]], @"FAILED: data should be vaild for current date.");
    
    // set year to 1999; should not be valid
    rm.year = @"1999";
    XCTAssertFalse([rm dataValidForDate:[NSDate date]], @"FAILED: data should not be valid for any date.");
    
    // set year to current year; should be valid
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    rm.year = [NSString stringWithFormat:@"%ld", (long)[comps year]];
    XCTAssertTrue([rm dataValidForDate:[NSDate date]], @"FAILED: data should be vaild for current date.");
}


- (void)testGetUnreadItemCount
{
    // this string has unread items at Nov 23, and Nov 25 to end of the year for year 2013
    NSString *read = @"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf0000000000";
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    rm.read = read;
    rm.year = @"2013";
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.year = 2013;
    comps.month = 11;
    comps.day = 25;
    rm.date = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    int count = [rm getUnreadCountForDate:rm.date];

    XCTAssertEqual(2, count, @"FAILED: invalid count");
}

- (void)testGetUnreadItemCountInvalidYear
{
    // this string has unread items at Nov 23, and Nov 25 to end of the year for year 2013
    NSString *read = @"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf0000000000";
    ReadsyMetadata *rm = [[ReadsyMetadata alloc] init];
    rm.read = read;
    rm.year = @"2013";
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.year = 2012;
    comps.month = 11;
    comps.day = 25;
    rm.date = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    int count = [rm getUnreadCountForDate:rm.date];
    
    XCTAssertEqual(0, count, @"FAILED: invalid count");
}

@end
