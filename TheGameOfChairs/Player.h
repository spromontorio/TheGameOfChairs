//
//  Player.h
//  TheGameOfChairs
//
//  Created by silvia promontorio on 19/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject

@property (nonatomic, strong) NSString *idPlayer;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL hasStation;



@end
