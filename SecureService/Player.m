//
//  Player.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Player.h"

@implementation Player

-(id)initWithIdPlayer:(NSString *)name {
    
    self = [super init];
    if (self) {
        self.idPlayer = name;
    }
    return self;

}

@end
