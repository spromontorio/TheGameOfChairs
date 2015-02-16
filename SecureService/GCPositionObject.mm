////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2012, AllSeen Alliance. All rights reserved.
//
//    Permission to use, copy, modify, and/or distribute this software for any
//    purpose with or without fee is hereby granted, provided that the above
//    copyright notice and this permission notice appear in all copies.
//
//    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
//    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
////////////////////////////////////////////////////////////////////////////////

#import "GCPositionObject.h"
#import "Constants.h"
#import "AJNBusAttachment.h"
#import "GCPositionObjectImpl.h"
#import "AJNInterfaceDescription.h"

@interface GCPositionObject()

@property (nonatomic) NSInteger sessionType;

@end

@implementation GCPositionObject

@synthesize delegate = _delegate;

- (id)initWithBusAttachment:(AJNBusAttachment *)busAttachment onServicePath:(NSString *)path
{
    self = [super initWithBusAttachment:busAttachment onPath:path];
    if (self) {
        // create the internal C++ bus object
        //
        GCPositionObjectImpl *busObject = new GCPositionObjectImpl(*((ajn::BusAttachment*)busAttachment.handle), [path UTF8String], self);
        NSLog(@"%s", [path UTF8String]);
        
        self.handle = busObject;
    }
    
    return self;
}

- (void)sendPosition:(NSString*)message onSession:(AJNSessionId)sessionId
{
    QStatus status = static_cast<GCPositionObjectImpl*>(self.handle)->SendPositionSignal([message UTF8String], sessionId);
    if (status != ER_OK) {
        NSLog(@"ERROR: sendPosition failed. %@", [AJNStatus descriptionForStatusCode:status]);
    }
}

-(void)didReceiveNewPositionMessage:(NSString *)message forSession:(AJNSessionId)sessionId{
    [self.delegate didReceiveNewPositionMessage:message forSession:sessionId];
}



@end
