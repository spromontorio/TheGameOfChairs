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

-(BOOL)isActive {
    
    return self.active = YES;
}

-(BOOL)turnStationOff {

    if (self.active)
        self.active = NO;
    else
        self.active = YES;
    
    return self.active;
}


@end
