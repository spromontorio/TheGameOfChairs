

#import <alljoyn/BusAttachment.h>
#import <alljoyn/BusObject.h>
#import "AJNBusObjectImpl.h"
#import "AJNInterfaceDescription.h"
#import "AJNSignalHandlerImpl.h"
#import "GCBaseHostObject.h"
#import "Constants.h"

using namespace ajn;

////////////////////////////////////////////////////////////////////////////////
//
//  C++ Bus Object class declaration for BasicObjectImpl
//
////////////////////////////////////////////////////////////////////////////////
class GCBaseHostObjectImpl : public AJNBusObjectImpl
{
private:

public:
    GCBaseHostObjectImpl(BusAttachment &bus, const char *path, id<GCBaseHostObjectDelegate> aDelegate);


    // properties
    //

    // methods
    //
    void TakeStation(const InterfaceDescription::Member* member, Message& msg);

    // signals
    //

};
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//  C++ Bus Object implementation for BasicObjectImpl
//
////////////////////////////////////////////////////////////////////////////////

GCBaseHostObjectImpl::GCBaseHostObjectImpl(BusAttachment &bus, const char *path, id<GCBaseHostObjectDelegate> aDelegate) :
    AJNBusObjectImpl(bus,path,aDelegate)
{
    const InterfaceDescription* interfaceDescription = NULL;
    QStatus status = ER_OK;


    interfaceDescription = bus.GetInterface([kInterfaceHost UTF8String]);
    assert(interfaceDescription);
    AddInterface(*interfaceDescription, ANNOUNCED);

    assert(interfaceDescription->GetMember("TakeStation"));
    assert(static_cast<MessageReceiver::MethodHandler>(&GCBaseHostObjectImpl::TakeStation));
 
    const MethodEntry methodEntriesForBasicStringsDelegate[] = {
        
        {
            
            interfaceDescription->GetMember("TakeStation"), static_cast<MessageReceiver::MethodHandler>(&GCBaseHostObjectImpl::TakeStation)
        },
    };
    
    status = AddMethodHandlers(methodEntriesForBasicStringsDelegate, sizeof(methodEntriesForBasicStringsDelegate) / sizeof(methodEntriesForBasicStringsDelegate[0]));
    if (ER_OK != status) {
        // TODO: perform error checking here
    }
}

void GCBaseHostObjectImpl::TakeStation(const InterfaceDescription::Member *member, Message& msg)
{
    @autoreleasepool {



    
    // get all input arguments
    //
    qcc::String inArg0 = msg->GetArg(0)->v_string.str;

    // declare the output arguments

    // call the Objective-C delegate method
    //

    [(id<GCBaseHostObjectDelegate>)delegate takeStation:[NSString stringWithCString:inArg0.c_str() encoding:NSUTF8StringEncoding] onSession:msg->GetSessionId()];
    }
        
}


////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//  Objective-C Bus Object implementation for AJNBasicObject
//
////////////////////////////////////////////////////////////////////////////////

@implementation GCBaseHostObject

@dynamic handle;


- (GCBaseHostObjectImpl*)busObject
{
    return static_cast<GCBaseHostObjectImpl*>(self.handle);
}

- (id)initWithBusAttachment:(AJNBusAttachment *)busAttachment onPath:(NSString *)path
{
    self = [super initWithBusAttachment:busAttachment onPath:path];
    if (self) {

        // create the internal C++ bus object
        //
        GCBaseHostObjectImpl *busObject = new GCBaseHostObjectImpl(*((ajn::BusAttachment*)busAttachment.handle), [path UTF8String], (id<GCBaseHostObjectDelegate>)self);

        self.handle = busObject;
    }
    return self;
}

- (void)dealloc
{
    GCBaseHostObjectImpl *busObject = [self busObject];
    delete busObject;
    self.handle = nil;
}


-(void)takeStation:(NSString *)message onSession:(AJNSessionId)sessionId
{
  
    @throw([NSException exceptionWithName:@"NotImplementedException" reason:@"You must override this method in a subclass" userInfo:nil]);
}

@end

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//  Objective-C Proxy Bus Object implementation for BasicObject
//
////////////////////////////////////////////////////////////////////////////////

@interface GCHostObjectProxy(Private)

@property (nonatomic, strong) AJNBusAttachment *bus;

- (ProxyBusObject*)proxyBusObject;

@end

@implementation GCHostObjectProxy

-(void)takeStation:(NSString *)message onSession:(AJNSessionId)sessionId
{
    [self addInterfaceNamed:kInterfaceHost];
    
    Message reply(*((BusAttachment*)self.bus.handle));
    MsgArg inArgs[1];

    inArgs[0].Set("s", [message UTF8String]);


    // make the function call using the C++ proxy object
    //
    QStatus status = self.proxyBusObject->MethodCall([kInterfaceHost UTF8String], "TakeStation", inArgs, 1, reply, 1);
    
    if (ER_OK != status) {
        NSLog(@"ERROR: ProxyBusObject::MethodCall failed. %@", [AJNStatus descriptionForStatusCode:status]);

    }
}

@end

////////////////////////////////////////////////////////////////////////////////
