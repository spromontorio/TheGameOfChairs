//
//  Station.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "Station.h"

@interface Station ()

@property (nonatomic) BOOL active;

@end

@implementation Station

-(id)stationIdentifiedByMacAddress:(NSString *)macAddress {
    
    self.macAddress = macAddress;
    return self;
}


@end
