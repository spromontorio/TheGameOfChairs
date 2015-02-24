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
#import "AJNProxyBusObject.h"
#import "GCTurnObject.h"
#import "GCHostObject.h"
#import "GCTurnSignalHandler.h"
#import "GCPositionObjectSignalHandler.h"
#import "ESTLocation.h"
#import "ESTLocationBuilder.h"
#import "ESTIndoorLocationManager.h"
#import "ESTIndoorLocationView.h"
#import "ESTOrientedPoint.h"
#import "Player.h"
#import "Turn.h"
#import "Station.h"
#import "Game.h"


@interface GCViewController () <GCPositionReceiver, AJNBusListener, ESTIndoorLocationManagerDelegate, AJNSessionPortListener, AJNSessionListener, GCTurnReceiver, GCHostObjectDelegate>


@property (nonatomic, strong) AJNBusAttachment *busAttachment;
@property (nonatomic, strong) GCPositionObject *positionObject;
@property (nonatomic, strong) GCTurnObject *turnObject;
@property (nonatomic, strong) GCHostObjectProxy *proxyHostObject;
@property (nonatomic, strong) GCHostObject *hostObject;

@property (nonatomic) AJNSessionId sessionId;
@property (nonatomic, strong) GCPositionObjectSignalHandler *positionHandler;
@property (nonatomic, strong) GCTurnSignalHandler *turnHandler;
@property (nonatomic, strong) ESTLocation *location;
@property (nonatomic, strong) ESTIndoorLocationManager *manager;
@property (nonatomic, strong) NSMutableDictionary *playersImageView;
@property (nonatomic, readonly) NSString *sessionlessSignalMatchRule;

@property (weak, nonatomic) IBOutlet ESTIndoorLocationView *locationView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UISwitch *sessionSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sessionTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property(nonatomic) BOOL isHost;
@property(nonatomic) BOOL started;
@property (nonatomic, strong) Player *player;
@property (nonatomic, strong) Turn *turn;
@property (nonatomic, strong) Game *game;



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
        
        NSString *name = [[UIDevice currentDevice] name];
        self.player = [[Player alloc] initWithIdPlayer:name];
        self.turn = [[Turn alloc] initWithPlayer:self.player];
        self.game = [[Game alloc] initWithTurn:self.turn];
        for (ESTPositionedBeacon *beacon in self.location.beacons) {
            
            Station *station = [[Station alloc] init];
            station.macAddress = beacon.macAddress;
            [self.turn.stations addObject:station];

        }
        
        self.isHost=[self.sessionSwitch isOn] && self.sessionTypeSegmentedControl.selectedSegmentIndex == 1;
        
        
        
        [self.manager startIndoorLocation:self.location];
    }
    else{
        [self disconnectAndDestroyBus];
        self.started=NO;
        self.sessionSwitch.enabled=YES;
        self.sessionTypeSegmentedControl.enabled=YES;
        [sender setTitle:@"Start" forState:UIControlStateNormal];
        [self.manager stopIndoorLocation];
        self.player = nil;
        self.turn = nil;
        self.game = nil;
    }
    
    NSString *name = [[UIDevice currentDevice] name];
    self.player = [[Player alloc] initWithIdPlayer:name];
    self.turn = [[Turn alloc] initWithPlayer:self.player];
    self.game = [[Game alloc] initWithTurn:self.turn];
    for (ESTPositionedBeacon *beacon in self.location.beacons) {
        
        Station *station = [[Station alloc] init];
        station.macAddress = beacon.macAddress;
        [self.turn.stations addObject:station];
    }
    
}


//setup method for alljoyn stuff
-(void)createAndConnectBus{
    
    QStatus status = ER_OK;
    
    
    self.busAttachment = [[AJNBusAttachment alloc] initWithApplicationName:kAppName allowRemoteMessages:YES];
    
    AJNInterfaceDescription* posInterface = [self.busAttachment createInterfaceWithName:kInterfacePosition];
    
    status=[posInterface addSignalWithName:@"Position" inputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"str"]];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to add signal to the interface. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    [posInterface activate];

    AJNInterfaceDescription* turnInterface = [self.busAttachment createInterfaceWithName:kInterfaceTurn];

    status=[turnInterface addSignalWithName:@"StartTurn" inputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"str"]];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to add signal to the interface. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    status=[turnInterface addSignalWithName:@"EndTurn" inputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"str"]];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to add signal to the interface. %@", [AJNStatus descriptionForStatusCode:status]);
    }

    [turnInterface activate];

    AJNInterfaceDescription* hostInterface = [self.busAttachment createInterfaceWithName:kInterfaceHost];

        status = [hostInterface addMethodWithName:@"TakeStation" inputSignature:@"s" outputSignature:@"" argumentNames:[NSArray arrayWithObjects:@"message", nil]];
        if (status != ER_OK) {
            NSLog(@"ERROR: Failed to add method to the interface. %@", [AJNStatus descriptionForStatusCode:status]);
        }
    
    [hostInterface activate];
    
    self.positionHandler = [[GCPositionObjectSignalHandler alloc] init];
    self.positionHandler.delegate = self;
    [self.busAttachment registerSignalHandler:self.positionHandler];
    
    self.turnHandler = [[GCTurnSignalHandler alloc] init];
    self.turnHandler.delegate = self;
    [self.busAttachment registerSignalHandler:self.turnHandler];
    
    
    self.positionObject = [[GCPositionObject alloc] initWithBusAttachment:self.busAttachment onServicePath:kServicePath];
    self.positionObject.delegate = self;
    [self.busAttachment registerBusObject:self.positionObject];
    
    self.turnObject = [[GCTurnObject alloc] initWithBusAttachment:self.busAttachment onServicePath:kServicePath];
    [self.busAttachment registerBusObject:self.turnObject];
    
    if (self.isHost) {

        self.hostObject = [[GCHostObject alloc] initWithBusAttachment:self.busAttachment onPath:kServicePath];
        self.hostObject.delegate = self;
        status=[self.busAttachment registerBusObject:self.hostObject];
        if (ER_OK != status) {
            NSLog(@"ERROR: Could not register host bus object");
        }
    }
    
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
        
        if (self.sessionTypeSegmentedControl.selectedSegmentIndex == 0) {
            // join an existing session by finding the name
            //
            [self.busAttachment findAdvertisedName:kServiceName];
        }
        else {
            // request the service name for the position object
            //
            [self.busAttachment requestWellKnownName:kServiceName withFlags:kAJNBusNameFlagReplaceExisting|kAJNBusNameFlagDoNotQueue];
            
            // advertise a name and let others connect to our service
            
            [self.busAttachment advertiseName:kServiceName withTransportMask:kAJNTransportMaskAny];
           
            
            AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];
            
            [self.busAttachment bindSessionOnPort:kServicePort withOptions:sessionOptions withDelegate:self];
        }
    }

}


//setup method for cleaning alljoyn stuff
-(void)disconnectAndDestroyBus{
    // leave the  session
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
    
    // unregister our listeners and the  bus object
    //
    [self.busAttachment unregisterBusListener:self];
    
    [self.busAttachment unregisterSignalHandler:self.positionHandler];
    
    [self.busAttachment unregisterBusObject:self.positionObject];
    
    // stop the bus and wait for the stop operation to complete
    //
    [self.busAttachment stop];
    
    [self.busAttachment waitUntilStopCompleted];
    
    // dispose of everything
    //
    self.positionHandler.delegate = nil;
    self.positionHandler = nil;
    
    self.positionObject.delegate = nil;
    self.positionObject = nil;
    
    self.busAttachment = nil;

}

- (IBAction)didTouchSendButton:(id)sender {
    NSString *message = [[[UIDevice currentDevice] name] stringByAppendingString: @" ciao"];
    
    [self.proxyHostObject introspectRemoteObject];
    
    [self.proxyHostObject takeStation:message onSession:self.sessionId];
    
    
    
    [self.positionObject sendPosition:message onSession:self.sessionId];
    [self.turnObject startTurnWithMessage:message forSession:self.sessionId];
    [self.turnObject endTurnWithMessage:message forSession:self.sessionId];
    //IF THE COMMUNICATION USES SESSION DATA YOU WONT RECEIVE THE MESSAGE YOU SEND. IF YOU WANT TO RECEIVE IT YOU MANAULLY CALL YOUR DELEGATE METHOD
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
    self.locationView.positionImage = [UIImage imageNamed:@"cat.png"];

    [self.locationView drawLocation:self.location];
    
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
    
    //IF YOU ARE USING SESSION YOU FILTER HERE THE MESSAGES THAT DON'T BELONG TO THE CURRENT SESSION
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
    
    if (data[@"station"] == nil) {
        
        NSString *player = data[@"player"];
        if (![player isEqualToString:self.player.idPlayer]) {
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
    
    else {
    
        Station *occupiedStation = [self.turn stationIdentifiedByMacAddress:data[@"station"]];
        ESTOrientedPoint *stationPosition = [ESTOrientedPoint pointFromDictionary:data[@"point"]];
        occupiedStation.player = [self.turn playerIdentifiedByName:data[@"player"]];
        
        [occupiedStation turnStationOff];
        
        UIImageView *red = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red.png"]];
        red.alpha = 0.5;
        [self.locationView drawObject:red withPosition:stationPosition];
    }


}

-(void)takeStation:(NSString *)message onSession:(AJNSessionId)sessionId{
    NSLog(@"Take Station: %@", message);
    
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if(jsonError)
        return;
    
    ESTOrientedPoint *playerPosition = [ESTOrientedPoint pointFromDictionary:data[@"position"]];
    ESTOrientedPoint *stationPosition = [ESTOrientedPoint pointFromDictionary:data[@"point"]];
    
    if ([playerPosition distanceToPoint:stationPosition] <= 10.00)
        
        [self.positionObject sendPosition:message onSession:self.sessionId];

}

- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager didUpdatePosition:(ESTOrientedPoint *)position inLocation:(ESTLocation *)location {
    NSLog(@"posizione ricevuta");
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"player"] = self.player.idPlayer;
    data[@"position"] = [position toDictionary];
    
    for (ESTPositionedBeacon *beacon in self.location.beacons) {
        
        if ([[self.turn stationIdentifiedByMacAddress:beacon.macAddress] isActive]) {
            
            data[@"station"] = beacon.macAddress;
            data[@"point"] = [beacon.position toDictionary];
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: NSJSONWritingPrettyPrinted error:&error];
            NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (self.isHost)
            
                [self takeStation:message onSession:self.sessionId];
           
            else {
                
                [self.proxyHostObject introspectRemoteObject];
                [self.proxyHostObject takeStation:message onSession:self.sessionId];
            }
            
        }

    }
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: NSJSONWritingPrettyPrinted error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self.positionObject sendPosition:message onSession:self.sessionId];

    
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


-(void)startTurnWithMessage: (NSString *)message forSession: (AJNSessionId)sessionId {

}

-(void)endTurnWithMessage: (NSString *)message forSession: (AJNSessionId)sessionId {

}

-(void)didEndTurnWithMessage:(NSString *)message forSession:(AJNSessionId)sessionId {

    NSLog(@"end turn %@", message);
    
}

-(void)didStartTurnWithMessage:(NSString *)message forSession:(AJNSessionId)sessionId {
    
    NSLog(@"start turn %@", message);
    
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
        self.proxyHostObject=[[GCHostObjectProxy alloc] initWithBusAttachment:self.busAttachment serviceName:kServiceName objectPath:kServicePath sessionId:self.sessionId];
    }
}

- (void)didLoseAdvertisedName:(NSString*)name withTransportMask:(AJNTransportMask)transport namePrefix:(NSString*)namePrefix
{
    NSString *message = [NSString stringWithFormat:@"%@", [[name componentsSeparatedByString:@"."] lastObject]];
    
    NSLog(@"Lost message: \"%@\"\n", message);
}


- (void)listenerDidRegisterWithBus:(AJNBusAttachment *)busAttachment{
    self.player.idPlayer = busAttachment.uniqueName;
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
