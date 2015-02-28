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

#import "GCPositionObjectImpl.h"
#import <alljoyn/BusAttachment.h>
#import "GCPositionObject.h"
#import "Constants.h"

GCPositionObjectImpl::GCPositionObjectImpl(ajn::BusAttachment &bus, const char *path, id<AJNBusObject> aDelegate) : AJNBusObjectImpl(bus,path,aDelegate)
{
    const ajn::InterfaceDescription* posIntf = bus.GetInterface([kInterfacePosition UTF8String]);
    assert(posIntf);
    AddInterface(*posIntf);
    
    /* Store the Position signal member away so it can be quickly looked up when signals are sent */
    positionSignalMember = posIntf->GetMember("Position");
    assert(positionSignalMember);
}

/* send a position signal */
QStatus GCPositionObjectImpl::SendPositionSignal(const char* msg, ajn::SessionId sessionId)
{
    
    ajn::MsgArg posArg("s", msg);
    
     //if we are using sessionless signals, ignore the session (obviously)
    if (gMessageFlags == kAJNMessageFlagSessionless) {
        sessionId = 0;
    }
    
    return Signal(NULL, sessionId, *positionSignalMember, &posArg, 1, 0, gMessageFlags);
}


