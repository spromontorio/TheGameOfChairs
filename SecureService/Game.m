//
//  Game.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Game.h"

@implementation Game

-(id)initWithTurn:(Turn *)turn {

    self = [super init];
    if (self) {
        
        self.turns = [[NSMutableArray alloc] init];
        [self.turns addObject:turn];
    }
    return self;
}


@end
