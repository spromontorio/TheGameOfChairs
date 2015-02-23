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

#import <alljoyn/InterfaceDescription.h>
#import <alljoyn/MessageReceiver.h>
#import "Constants.h"
#import "GCPositionObjectSignalHandlerImpl.h"
#import "GCPositionReceiver.h"

using namespace ajn;

/**
 * Constructor for the AJN signal handler implementation.
 *
 * @param aDelegate         Objective C delegate called when one of the below virtual functions is called.     
 */    
GCPositionObjectSignalHandlerImpl::GCPositionObjectSignalHandlerImpl(id<AJNSignalHandler> aDelegate) : AJNSignalHandlerImpl(aDelegate), positionSignalMember(NULL)
{
}

GCPositionObjectSignalHandlerImpl::~GCPositionObjectSignalHandlerImpl()
{
    m_delegate = NULL;
}

void GCPositionObjectSignalHandlerImpl::RegisterSignalHandler(ajn::BusAttachment &bus)
{
    if (positionSignalMember == NULL) {
        const ajn::InterfaceDescription* posIntf = bus.GetInterface([kInterfacePosition UTF8String]);
        
        /* Store the Posotion signal member away so it can be quickly looked up */
        if (posIntf) {
            positionSignalMember = posIntf->GetMember("Position");
            assert(positionSignalMember);
        }
    }
    /* Register signal handler */
    QStatus status =  bus.RegisterSignalHandler(this,
                                                (MessageReceiver::SignalHandler)(&GCPositionObjectSignalHandlerImpl::PositionSignalHandler),
                                                positionSignalMember,
                                                NULL);
    if (status != ER_OK) {
        NSLog(@"ERROR:GCPositionObjectSignalHandlerImpl::RegisterSignalHandler failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }
}

void GCPositionObjectSignalHandlerImpl::UnregisterSignalHandler(ajn::BusAttachment &bus)
{
    if (positionSignalMember == NULL) {
        const ajn::InterfaceDescription* posIntf = bus.GetInterface([kInterfacePosition UTF8String]);
        
        /* Store the Position signal member away so it can be quickly looked up */
        positionSignalMember = posIntf->GetMember("Position");
        assert(positionSignalMember);
    }
    /* Register signal handler */
    QStatus status =  bus.UnregisterSignalHandler(this, static_cast<MessageReceiver::SignalHandler>(&GCPositionObjectSignalHandlerImpl::PositionSignalHandler), positionSignalMember, NULL);

    if (status != ER_OK) {
        NSLog(@"ERROR:GCPositionObjectSignalHandlerImpl::UnregisterSignalHandler failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }
}

/** Receive a signal from another Position client */
void GCPositionObjectSignalHandlerImpl::PositionSignalHandler(const ajn::InterfaceDescription::Member* member, const char* srcPath, ajn::Message& msg)
{
    @autoreleasepool {
        NSString *message = [NSString stringWithCString:msg->GetArg(0)->v_string.str encoding:NSUTF8StringEncoding];
        NSString *from = [NSString stringWithCString:msg->GetSender() encoding:NSUTF8StringEncoding];
        NSString *objectPath = [NSString stringWithCString:msg->GetObjectPath() encoding:NSUTF8StringEncoding];
        ajn:SessionId sessionId = msg->GetSessionId();
        
        NSLog(@"Received signal [%@] from %@ on path %@ for session id %u [%s > %s]", message, from, objectPath, msg->GetSessionId(), msg->GetRcvEndpointName(), msg->GetDestination() ? msg->GetDestination() : "broadcast");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [(id<GCPositionReceiver>)m_delegate didReceiveNewPositionMessage:message forSession:sessionId];
        });
        
    }
}    
