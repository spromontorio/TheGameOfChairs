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

#import "GCTurnObjectImpl.h"
#import <alljoyn/BusAttachment.h>
#import "GCTurnObject.h"
#import "Constants.h"

GCTurnObjectImpl::GCTurnObjectImpl(ajn::BusAttachment &bus, const char *path, id<AJNBusObject> aDelegate) : AJNBusObjectImpl(bus,path,aDelegate)
{
    const ajn::InterfaceDescription* intf = bus.GetInterface([kInterfaceTurn UTF8String]);
    assert(intf);
    AddInterface(*intf);
    
    startTurnSignalMember = intf->GetMember("StartTurn");
    endTurnSignalMember = intf->GetMember("EndTurn");

    assert(startTurnSignalMember);
    assert(endTurnSignalMember);

}

QStatus GCTurnObjectImpl::SendStartTurnSignal(const char* msg, ajn::SessionId sessionId)
{
    ajn::MsgArg args("s", msg);
    
     //if we are using sessionless signals, ignore the session (obviously)
    if (gMessageFlags == kAJNMessageFlagSessionless) {
        sessionId = 0;
    }
    
    return Signal(NULL, sessionId, *startTurnSignalMember, &args, 1, 0, gMessageFlags);
}

QStatus GCTurnObjectImpl::SendEndTurnSignal(const char* msg, ajn::SessionId sessionId)
{
    
    ajn::MsgArg args("s", msg);
    
    //if we are using sessionless signals, ignore the session (obviously)
    if (gMessageFlags == kAJNMessageFlagSessionless) {
        sessionId = 0;
    }
    
    return Signal(NULL, sessionId, *endTurnSignalMember, &args, 1, 0, gMessageFlags);
}


