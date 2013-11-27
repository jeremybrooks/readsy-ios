//
//  ReadsyEntry.m
//  readsy
//
//  Created by Jeremy Brooks on 11/22/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import "ReadsyEntry.h"

@implementation ReadsyEntry

-(id)initWithString:(NSString *)entry
{
    self = [self init];
    
    if (self) {
        NSArray *lines = [entry componentsSeparatedByString:@"\n"];
        self.heading = [lines objectAtIndex:0];
        NSMutableString *builder = [[NSMutableString alloc] init];
        for (int i = 1; i < lines.count; i++) {
            [builder appendString:[lines objectAtIndex:i]];
            [builder appendString:@"\n"];
        }
        self.content = builder;
    }
    
    return self;
}

@end
