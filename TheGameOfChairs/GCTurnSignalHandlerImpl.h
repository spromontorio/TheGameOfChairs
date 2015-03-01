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

#import <Foundation/Foundation.h>
#import "AJNSignalHandlerImpl.h"

class GCTurnSignalHandlerImpl : public AJNSignalHandlerImpl {
  private:
    const ajn::InterfaceDescription::Member* startTurnSignalMember;
    const ajn::InterfaceDescription::Member* endTurnSignalMember;

    void StartTurnSignalHandler(const ajn::InterfaceDescription::Member* member, const char* srcPath, ajn::Message& msg);
     void EndTurnSignalHandler(const ajn::InterfaceDescription::Member* member, const char* srcPath, ajn::Message& msg);

  public:
    /**
     * Constructor for the AJN signal handler implementation.
     *
     * @param aDelegate         Objective C delegate called when one of the below virtual functions is called.
     */
    GCTurnSignalHandlerImpl(id<AJNSignalHandler> aDelegate);

    virtual void RegisterSignalHandler(ajn::BusAttachment& bus);

    virtual void UnregisterSignalHandler(ajn::BusAttachment& bus);

    /**
     * Virtual destructor for derivable class.
     */
    virtual ~GCTurnSignalHandlerImpl();
};