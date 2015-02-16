//
//  GCViewController.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 09/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "GCViewController.h"
#import "Constants.h"
#import "GCPositionObject.h"
#import "AJNBusAttachment.h"
#import "AJNBusListener.h"
#import "AJNSessionListener.h"
#import "AJNSessionPortListener.h"
#import "AJNBusInterface.h"
#import "GCPositionObjectSignalHandler.h"
#import "ESTLocation.h"
#import "ESTLocationBuilder.h"
#import "ESTIndoorLocationManager.h"
#import "ESTIndoorLocationView.h"
#import "ESTOrientedPoint.h"


@interface GCViewController () <GCPositionReceiver, AJNBusListener, ESTIndoorLocationManagerDelegate, AJNSessionPortListener, AJNSessionListener>


@property (nonatomic, strong) AJNBusAttachment *busAttachment;
@property (nonatomic, strong) GCPositionObject *sixiObject;
@property (nonatomic) AJNSessionId sessionId;
@property (nonatomic, strong) GCPositionObjectSignalHandler *signalHandler;
@property (nonatomic, strong) ESTLocation *location;
@property (nonatomic, strong) ESTIndoorLocationManager *manager;
@property (nonatomic, strong) NSMutableDictionary *playersImageView;
@property (nonatomic, readonly) NSString *sessionlessSignalMatchRule;

@property (weak, nonatomic) IBOutlet ESTIndoorLocationView *locationView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UISwitch *sessionSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sessionTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *label;

@property(nonatomic) BOOL started;

@end

@implementation GCViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.manager = [ESTIndoorLocationManager new];
    self.manager.delegate = self;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"location" ofType:@"json"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    self.location = [ESTLocationBuilder parseFromJSON:content];
    
    // Do any additional setup after loading the view.
    self.started=NO;
    self.playersImageView = [NSMutableDictionary dictionary];
    
    
}

-(IBAction)didTouchStartButton:(UIButton *)sender {
    
    if(!self.started)
    {
        [self createAndConnectBus];
        self.started=YES;
        self.sessionTypeSegmentedControl.enabled=NO;
        self.sessionSwitch.enabled=NO;
        if(self.sessionSwitch.isOn)
            gMessageFlags=0x0; // SIX: what a fail
        else
            gMessageFlags=kAJNMessageFlagSessionless;
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else{
        [self disconnectAndDestroyBus];
        self.started=NO;
        self.sessionSwitch.enabled=YES;
        self.sessionTypeSegmentedControl.enabled=YES;
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}


// SIX: setup method for alljoyn stuff
-(void)createAndConnectBus{
    
    QStatus status = ER_OK;
    
    
    self.busAttachment = [[AJNBusAttachment alloc] initWithApplicationName:kAppName allowRemoteMessages:YES];
    
    AJNInterfaceDescription* posInterface = [self.busAttachment createInterfaceWithName:kInterfaceName];
    
    status=[posInterface addSignalWithName:@"Position" inputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"str"]];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to add signal to chat interface. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    [posInterface activate];
    
    
    self.signalHandler = [[GCPositionObjectSignalHandler alloc] init];
    self.signalHandler.delegate = self;
    [self.busAttachment registerSignalHandler:self.signalHandler];
    
    self.sixiObject = [[GCPositionObject alloc] initWithBusAttachment:self.busAttachment onServicePath:kServicePath];
    self.sixiObject.delegate = self;
    
    [self.busAttachment registerBusObject:self.sixiObject];
    
    
    status = [self.busAttachment start];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to start bus. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    [self.busAttachment registerBusListener:self];
    
    status = [self.busAttachment connectWithArguments:@"null:"];
    
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to connect bus. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    
    if (gMessageFlags == kAJNMessageFlagSessionless) {
        NSLog(@"Adding match rule : [%@]", self.sessionlessSignalMatchRule);
        status = [self.busAttachment addMatchRule:self.sessionlessSignalMatchRule];
        
        if (status != ER_OK) {
            
            NSLog(@"ERROR: Unable to %@ match rule. %@", self.sessionSwitch.isOn ? @"remove" : @"add", [AJNStatus descriptionForStatusCode:status]);
        }
    }
    else {
        
        // get the type of session to create
        //
        NSString *serviceName = [NSString stringWithFormat:@"%@%@", kServiceName, @"gameofchairs"];
        
        if (self.sessionTypeSegmentedControl.selectedSegmentIndex == 0) {
            // join an existing session by finding the name
            //
            [self.busAttachment findAdvertisedName:serviceName];
        }
        else {
            // request the service name for the position object
            //
            [self.busAttachment requestWellKnownName:serviceName withFlags:kAJNBusNameFlagReplaceExisting|kAJNBusNameFlagDoNotQueue];
            
            // advertise a name and let others connect to our service
            //
            [self.busAttachment advertiseName:serviceName withTransportMask:kAJNTransportMaskAny];
            
            AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];
            
            [self.busAttachment bindSessionOnPort:kServicePort withOptions:sessionOptions withDelegate:self];
        }
    }

}

// SIX: setup method for cleaning alljoyn stuff
-(void)disconnectAndDestroyBus{
    // leave the chat session
    //
    
    NSString *serviceName = [NSString stringWithFormat:@"%@%@", kServiceName, @"gameofchairs"];
    if(gMessageFlags!=kAJNMessageFlagSessionless && self.sessionId)
        [self.busAttachment leaveSession:self.sessionId];
    
    // cancel the advertised name search, or the advertisement, depending on if this is a
    // service or client
    //
    if (self.sessionTypeSegmentedControl.selectedSegmentIndex == 0) {
        [self.busAttachment cancelFindAdvertisedName:serviceName];
    }
    else {
        [self.busAttachment cancelAdvertisedName:serviceName withTransportMask:kAJNTransportMaskAny];
    }
    
    // disconnect from the bus
    //
    [self.busAttachment disconnectWithArguments:@"null:"];
    
    // unregister our listeners and the chat bus object
    //
    [self.busAttachment unregisterBusListener:self];
    
    [self.busAttachment unregisterSignalHandler:self.signalHandler];
    
    [self.busAttachment unregisterBusObject:self.sixiObject];
    
    // stop the bus and wait for the stop operation to complete
    //
    [self.busAttachment stop];
    
    [self.busAttachment waitUntilStopCompleted];
    
    // dispose of everything
    //
    self.signalHandler.delegate = nil;
    self.signalHandler = nil;
    
    self.sixiObject.delegate = nil;
    self.sixiObject = nil;
    
    self.busAttachment = nil;

}

- (IBAction)didTouchSendButton:(id)sender {
    NSString *message = [[[UIDevice currentDevice] name] stringByAppendingString: @"ciao"];
    [self.sixiObject sendPosition:message onSession:self.sessionId];
    // SIX: IF THE COMMUNICATION USES SESSION DATA YOU WONT RECEIVE THE MESSAGE YOU SEND. IF YOU WANT TO RECEIVE IT YOU MANAULLY CALL YOUR DELEGATE METHOD
    if (gMessageFlags != kAJNMessageFlagSessionless) {
        [self didReceiveNewPositionMessage:message forSession:self.sessionId];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.locationView.backgroundColor = [UIColor clearColor];
    
    self.locationView.showTrace               = NO;
    self.locationView.rotateOnPositionUpdate  = YES;
    
    self.locationView.showWallLengthLabels    = YES;
    
    self.locationView.locationBorderColor     = [UIColor blackColor];
    self.locationView.locationBorderThickness = 4;
    self.locationView.doorColor               = [UIColor brownColor];
    self.locationView.doorThickness           = 6;
    self.locationView.traceColor              = [UIColor blueColor];
    self.locationView.traceThickness          = 2;
    self.locationView.wallLengthLabelsColor   = [UIColor blackColor];
    
    
    // You can change the avatar using positionImage property of ESTIndoorLocationView class.
    //self.locationView.positionImage = [UIImage imageNamed:@"cat.png"];

    [self.locationView drawLocation:self.location];
    
    //  [self.manager startIndoorLocation:self.location];
}

- (NSString *)sessionlessSignalMatchRule
{
    return @"sessionless='t'";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)didReceiveNewPositionMessage:(NSString *)message forSession:(AJNSessionId)sessionId{
    
    //SIX: IF YOU ARE USING SESSION YOU FILTER HERE THE MESSAGES THAT DON'T BELONG TO THE CURRENT SESSION
    if(gMessageFlags != kAJNMessageFlagSessionless && self.sessionId!=sessionId)
        NSLog(@"POSIZIONE RICEVUTA MA SESSIONE ERRATA");
    
    NSLog(@"RICEVUTA POSIZIONE: %@", message);
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if(jsonError)
        return;
    
    NSString *player = data[@"player"];
    if (![player isEqualToString:[[UIDevice currentDevice] name]]) {
        UIImageView *view = self.playersImageView[player];
        if (!view) {
            view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cat.png"]];
            [self.locationView addSubview:view];
            self.playersImageView[player] = view;
        }
        
        ESTOrientedPoint *point = [ESTOrientedPoint pointFromDictionary:data[@"position"]];
        [self.locationView drawObject:view withPosition:point];
        
        self.label.text = player;
    }

}

- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager didUpdatePosition:(ESTOrientedPoint *)position inLocation:(ESTLocation *)location {
    NSLog(@"posizione ricevuta");
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"player"] = [[UIDevice currentDevice] name];
    data[@"position"] = [NSDictionary dictionaryWithObjectsAndKeys:@(position.x), @"x", @(position.y), @"y", @(position.orientation), @"orientation", nil];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: NSJSONWritingPrettyPrinted error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self.sixiObject sendPosition:message onSession:self.sessionId];

    
    [self.locationView updatePosition:position];
}
/**
 * Tells the delegate that position update could not be determined.
 *
 * @param manager The manager object that generated the event.
 * @param error Error why position could not be determined.
 */
- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager didFailToUpdatePositionWithError:(NSError *)error {
    
    NSLog(@"errore posizione");

}

#pragma mark - AJNBusListener delegate methods

- (void)didFindAdvertisedName:(NSString *)name withTransportMask:(AJNTransportMask)transport namePrefix:(NSString *)namePrefix
{
    NSString *message = [NSString stringWithFormat:@"%@", [[name componentsSeparatedByString:@"."] lastObject]];
    
    NSLog(@"Discovered message: \"%@\"\n", message);
    
    [self.busAttachment enableConcurrentCallbacks];
    
    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];
    
    AJNSessionId sessionId = [self.busAttachment joinSessionWithName:name onPort:kServicePort withDelegate:self options:sessionOptions];
    if (sessionId != 0) {
        self.sessionId = sessionId;
    }
}

- (void)didLoseAdvertisedName:(NSString*)name withTransportMask:(AJNTransportMask)transport namePrefix:(NSString*)namePrefix
{
    NSString *message = [NSString stringWithFormat:@"%@", [[name componentsSeparatedByString:@"."] lastObject]];
    
    NSLog(@"Lost message: \"%@\"\n", message);
}

#pragma mark - AJNSessionPortListener delegate methods


- (void)didJoin:(NSString *)joiner inSessionWithId:(AJNSessionId)sessionId onSessionPort:(AJNSessionPort)sessionPort
{
    if (self.sessionTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.sessionId = sessionId;
        NSLog(@"%@", joiner);
    }
}

- (BOOL)shouldAcceptSessionJoinerNamed:(NSString *)joiner onSessionPort:(AJNSessionPort)sessionPort withSessionOptions:(AJNSessionOptions *)options {

    return sessionPort == kServicePort;

}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
