//
//  Station.h
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Player.h"

@interface Station : NSObject

@property (nonatomic ,strong) Player *player;
@property (nonatomic, strong) NSString *macAddress;

-(BOOL)isActive;
-(BOOL)turnStationOff;

@end
