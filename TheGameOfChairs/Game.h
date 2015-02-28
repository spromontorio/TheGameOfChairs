//
//  Game.h
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Turn.h"

@interface Game : NSObject

@property (nonatomic, strong) NSMutableArray *turns;
@property (nonatomic, strong) NSMutableArray *players;

-(Player *)playerIdentifiedById:(NSString *)ide;

@end
