//
//  ReadsyEntry.h
//  readsy
//
//  Created by Jeremy Brooks on 11/22/13.
//  Copyright (c) 2013 Jeremy Brooks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadsyEntry : NSObject
@property (strong, nonatomic) NSString *heading;
@property (strong, nonatomic) NSString *content;

-(id)initWithString:(NSString *)entry;
@end
