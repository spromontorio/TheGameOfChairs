//
//  GCPositionReceiver.h
//  TheGameOfChairs
//
//  Created by silvia promontorio on 11/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AJNSessionOptions.h"

@protocol GCPositionReceiver <NSObject>

-(void)didReceiveNewPositionMessage: (NSString *)message forSession: (AJNSessionId)sessionId;


@end
