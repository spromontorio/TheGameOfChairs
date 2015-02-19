//
//  Turn.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Turn.h"

@implementation Turn

-(id)initWithPlayer:(Player *)player {

    self.players = [[NSMutableArray alloc] init];
    [self.players addObject:player];
    
    return self;
}

@end
