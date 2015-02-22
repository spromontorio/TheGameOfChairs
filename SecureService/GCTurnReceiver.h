//
//  TurnReceiver.m
//  TheGameOfChairs
//
//  Created by Giovanni Quattrocchi on 22/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AJNSessionOptions.h"

@protocol GCTurnReceiver <NSObject>

-(void)didStartTurnWithMessage: (NSString *)message forSession: (AJNSessionId)sessionId;
-(void)didEndTurnWithMessage: (NSString *)message forSession: (AJNSessionId)sessionId;


@end
