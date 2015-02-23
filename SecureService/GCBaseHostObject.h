
#import <Foundation/Foundation.h>
#import "AJNBusAttachment.h"
#import "AJNBusInterface.h"
#import "AJNProxyBusObject.h"
#import "AJNSessionOptions.h"


@protocol GCBaseHostObjectDelegate <AJNBusInterface>

- (void)takeStation:(NSString *)message onSession: (AJNSessionId)sessionId;

@end


@interface GCBaseHostObject : AJNBusObject<GCBaseHostObjectDelegate>

// properties
//

// methods
//
- (void)takeStation:(NSString *)message onSession: (AJNSessionId)sessionId;


// signals
//


@end

////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//
//  BasicObject Proxy
//
////////////////////////////////////////////////////////////////////////////////

@interface GCHostObjectProxy : AJNProxyBusObject

// properties
//

// methods
//
- (void)takeStation:(NSString *)message onSession: (AJNSessionId)sessionId;

@end

////////////////////////////////////////////////////////////////////////////////
