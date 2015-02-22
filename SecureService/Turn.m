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

    self = [super init];
    if (self) {
 
        self.players = [[NSMutableArray alloc] init];
        [self.players addObject:player];
        self.stations = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(Station *)stationIdentifiedByMacAddress:(NSString *)macAddress {
    
    for (Station *station in self.stations) {
        if (station.macAddress == macAddress)
            return station;
    
    }
    return nil;
}


@end
