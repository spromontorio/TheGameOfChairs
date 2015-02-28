//
//  Turn.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Turn.h"

@implementation Turn

-(id)init {

    self = [super init];
    if (self) {
 
        self.players = [[NSMutableArray alloc] init];
        self.stations = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(Station *)stationIdentifiedByMacAddress:(NSString *)macAddress {
    
    for (Station *station in self.stations) {
        if ([station.macAddress isEqualToString:macAddress])
            return station;
    
    }
    return nil;
}

-(Player *)playerIdentifiedById:(NSString *)ide {
    
    for (Player *player in self.players) {
        if ([player.idPlayer isEqualToString:ide ])
            return player;
    }
    return nil;
}


@end
