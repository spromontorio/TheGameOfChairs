//
//  Turn.h
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"
#import "Station.h"


@interface Turn : NSObject

@property (nonatomic, strong) NSMutableArray *players;
@property (nonatomic, strong) NSMutableArray *stations;
@property (nonatomic, strong) NSDate *beginDate;

-(Station *)stationIdentifiedByMacAddress:(NSString *)macAddress;
-(Player *)playerIdentifiedById:(NSString *)name;


@end
