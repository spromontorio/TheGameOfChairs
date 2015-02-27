//
//  Game.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Game.h"

@implementation Game

-(id)init {

    self = [super init];
    if (self) {
        
        self.turns = [[NSMutableArray alloc] init];
        self.players = [NSMutableArray array];
    }
    return self;
}


@end
