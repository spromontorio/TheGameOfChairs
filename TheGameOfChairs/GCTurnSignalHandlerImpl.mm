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
#import "GCTurnSignalHandlerImpl.h"
#import "GCTurnReceiver.h"

using namespace ajn;

/**
 * Constructor for the AJN signal handler implementation.
 *
 * @param aDelegate         Objective C delegate called when one of the below virtual functions is called.     
 */    
GCTurnSignalHandlerImpl::GCTurnSignalHandlerImpl(id<AJNSignalHandler> aDelegate) : AJNSignalHandlerImpl(aDelegate), startTurnSignalMember(NULL), endTurnSignalMember(NULL)
{
}

GCTurnSignalHandlerImpl::~GCTurnSignalHandlerImpl()
{
    m_delegate = NULL;
}

void GCTurnSignalHandlerImpl::RegisterSignalHandler(ajn::BusAttachment &bus)
{
    if (startTurnSignalMember == NULL) {
        const ajn::InterfaceDescription* intf = bus.GetInterface([kInterfaceTurn UTF8String]);
        
        /* Store the Posotion signal member away so it can be quickly looked up */
        if (intf) {
            startTurnSignalMember = intf->GetMember("StartTurn");
            assert(startTurnSignalMember);
        }
    }
    
    if (endTurnSignalMember == NULL) {
        const ajn::InterfaceDescription* intf = bus.GetInterface([kInterfaceTurn UTF8String]);
        
        if (intf) {
            endTurnSignalMember = intf->GetMember("EndTurn");
            assert(endTurnSignalMember);
        }
    }
    /* Register signal handler */
    QStatus status =  bus.RegisterSignalHandler(this,
                                                (MessageReceiver::SignalHandler)(&GCTurnSignalHandlerImpl::StartTurnSignalHandler),
                                                startTurnSignalMember,
                                                NULL);
    if (status != ER_OK) {
        NSLog(@"ERROR:GCTurnSignalHandlerImpl::RegisterSignalHandler StartTurn failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }
    
    status =  bus.RegisterSignalHandler(this,
                                        (MessageReceiver::SignalHandler)(&GCTurnSignalHandlerImpl::EndTurnSignalHandler),
                                        endTurnSignalMember,
                                        NULL);
    if (status != ER_OK) {
        NSLog(@"ERROR:GCTurnSignalHandlerImpl::RegisterSignalHandler EndTurn failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }

}

void GCTurnSignalHandlerImpl::UnregisterSignalHandler(ajn::BusAttachment &bus)
{
    if (startTurnSignalMember == NULL) {
        const ajn::InterfaceDescription* posIntf = bus.GetInterface([kInterfaceTurn UTF8String]);
        
        startTurnSignalMember = posIntf->GetMember("StartTurn");
        assert(startTurnSignalMember);
    }
    
    
    QStatus status =  bus.UnregisterSignalHandler(this, static_cast<MessageReceiver::SignalHandler>(&GCTurnSignalHandlerImpl::StartTurnSignalHandler), startTurnSignalMember, NULL);

    if (status != ER_OK) {
        NSLog(@"ERROR:GCTurnSignalHandlerImpl::UnregisterSignalHandler StartTurn failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }
    
    if (endTurnSignalMember == NULL) {
        const ajn::InterfaceDescription* posIntf = bus.GetInterface([kInterfaceTurn UTF8String]);
        
        endTurnSignalMember = posIntf->GetMember("EndTurn");
        assert(endTurnSignalMember);
    }
    
    /* Register signal handler */
    
    status =  bus.UnregisterSignalHandler(this, static_cast<MessageReceiver::SignalHandler>(&GCTurnSignalHandlerImpl::EndTurnSignalHandler), endTurnSignalMember, NULL);
    
    if (status != ER_OK) {
        NSLog(@"ERROR:GCTurnSignalHandlerImpl::UnregisterSignalHandler EndTurn failed. %@", [AJNStatus descriptionForStatusCode:status] );
    }

}

void GCTurnSignalHandlerImpl::StartTurnSignalHandler(const ajn::InterfaceDescription::Member* member, const char* srcPath, ajn::Message& msg)
{
    @autoreleasepool {
        NSString *message = [NSString stringWithCString:msg->GetArg(0)->v_string.str encoding:NSUTF8StringEncoding];
       
        ajn:SessionId sessionId = msg->GetSessionId();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [(id<GCTurnReceiver>)m_delegate didStartTurnWithMessage: message forSession:sessionId];
        });
        
    }
}

void GCTurnSignalHandlerImpl::EndTurnSignalHandler(const ajn::InterfaceDescription::Member* member, const char* srcPath, ajn::Message& msg)
{
    @autoreleasepool {
        NSString *message = [NSString stringWithCString:msg->GetArg(0)->v_string.str encoding:NSUTF8StringEncoding];
       
        ajn:SessionId sessionId = msg->GetSessionId();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [(id<GCTurnReceiver>)m_delegate didEndTurnWithMessage: message forSession:sessionId];
        });
        
    }
}

