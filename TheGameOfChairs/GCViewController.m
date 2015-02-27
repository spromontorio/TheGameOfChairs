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
#import <AVFoundation/AVFoundation.h>


#define DEFAULT_PROXIMITY_DISTANCE 0.30


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
@property (nonatomic, strong) NSMutableDictionary *stationsImageView;
@property (nonatomic, strong) NSMutableArray *images;
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
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) int numberOfPlayers;



@end

@implementation GCViewController

#pragma mark View lifecycle and buttons

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.manager = [ESTIndoorLocationManager new];
    self.manager.delegate = self;
    
    
    self.started=NO;
    self.playersImageView = [NSMutableDictionary dictionary];
    self.stationsImageView = [NSMutableDictionary dictionary];
    self.images = [[NSMutableArray alloc] initWithObjects:@"dog.png", @"cat.png", @"lion.png", nil];
    self.numberOfPlayers = self.images.count;
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    NSDictionary *location = [[NSUserDefaults standardUserDefaults] objectForKey:@"location"];
    if(!location){
        
        // temporary
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"location" ofType:@"json"];
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        ESTLocation *location = [ESTLocationBuilder parseFromJSON:content];
        NSDictionary *rawLocation = [location toDictionary];
        [[NSUserDefaults standardUserDefaults] setObject:rawLocation forKey:@"location"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self setupLocationWithDictionary:rawLocation];
        
        //[self presentLocationSetupController];
    }
    else{
        
        [self setupLocationWithDictionary:location];
    }

}


-(IBAction)didTouchStartButton:(UIButton *)sender {
    
    if(!self.started)
    {
        self.started=YES;
        self.sessionTypeSegmentedControl.enabled=NO;
        self.sessionSwitch.enabled=NO;
        if(self.sessionSwitch.isOn)
            gMessageFlags=0x0;
        else
            gMessageFlags=kAJNMessageFlagSessionless;
        
        self.isHost=[self.sessionSwitch isOn] && self.sessionTypeSegmentedControl.selectedSegmentIndex == 1;
        
        [self createAndConnectBus];

        
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
        
        
        NSString *name = [[UIDevice currentDevice] name];
        self.player = [[Player alloc] init];
        
        if(self.isHost){
            self.player.image = [self.images objectAtIndex:0];
            [self.images removeObjectAtIndex:0];
        }
        
        self.player.name = name;
        
        self.game = [[Game alloc] init];
        
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
        self.images = [[NSMutableArray alloc] initWithObjects:@"dog.png", @"cat.png", @"lion.png", nil];
    }
    
    
}

- (IBAction)didTouchSendButton:(id)sender {
    NSString *message = [[[UIDevice currentDevice] name] stringByAppendingString: @" ciao"];
    
    [self.proxyHostObject introspectRemoteObject];
    
    [self.proxyHostObject takeStation:message onSession:self.sessionId];
    
    
    [self.positionObject sendPosition:message onSession:self.sessionId];
    [self.turnObject startTurnWithMessage:message forSession:self.sessionId];
    [self.turnObject endTurnWithMessage:message forSession:self.sessionId];
    
    if (gMessageFlags != kAJNMessageFlagSessionless) {
        [self didReceiveNewPositionMessage:message forSession:self.sessionId];
    }
}

#pragma mark Estimote SDK (host and client)

- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager didUpdatePosition:(ESTOrientedPoint *)position inLocation:(ESTLocation *)location {
    
    NSLog(@"position received");
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"player"] = self.player.idPlayer;
    data[@"position"] = [position toDictionary];
    
    for (ESTPositionedBeacon *beacon in self.location.beacons) {
        
        Station *s = [self.turn stationIdentifiedByMacAddress:beacon.macAddress];
        if (s.isActive && [position distanceToPoint: beacon.position] <= DEFAULT_PROXIMITY_DISTANCE) {
            
            data[@"station"] = beacon.macAddress;
            data[@"station_position"] = [beacon.position toDictionary];
            
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

-(void)indoorLocationManager:(ESTIndoorLocationManager *)manager didFailToUpdatePositionWithError:(NSError *)error
{
    
   // NSLog(@"position error");
}


-(void)presentLocationSetupController{
    
    __weak GCViewController *weakSelf = self;
    UIViewController *nextVC = [ESTIndoorLocationManager locationSetupControllerWithCompletion:^(ESTLocation *location, NSError *error) {
        
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (location)
            {
                NSDictionary *rawLocation = [location toDictionary];
                [[NSUserDefaults standardUserDefaults] setObject:rawLocation forKey:@"location"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self setupLocationWithDictionary:rawLocation];
                
            }
        }];
    }];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextVC];
    [self presentViewController:navController animated:YES completion:nil];

}

-(void)setupLocationWithDictionary: (NSDictionary *)location{
    
    
    self.location = [ESTLocation locationFromDictionary:location];
    
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
    
    
    UIImage *image = [UIImage imageNamed:self.player.image];
    self.locationView.positionImage = image;
    
    [self.locationView drawLocation:self.location];
    
}


#pragma mark Position signal handler (host and client)

-(void)didReceiveNewPositionMessage:(NSString *)message forSession:(AJNSessionId)sessionId{
    
    if(gMessageFlags != kAJNMessageFlagSessionless && self.sessionId!=sessionId)
        NSLog(@"Session Error");
    
    NSLog(@"Position Signal received %@", message);
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if(jsonError)
        return;
    Station *occupiedStation = [self.turn stationIdentifiedByMacAddress:data[@"station"]];
    
    if (occupiedStation == nil) {
        
        Player *player = [self.turn playerIdentifiedById:data[@"player"]];
        if (![player.idPlayer isEqualToString:self.player.idPlayer]) {
            UIImageView *view = self.playersImageView[player];
            if (!view) {
                
                view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:player.image]];
                [self.locationView addSubview:view];
                self.playersImageView[player.idPlayer] = view;
            }
            
            ESTOrientedPoint *point = [ESTOrientedPoint pointFromDictionary:data[@"position"]];
            [self.locationView drawObject:view withPosition:point];
            
            self.label.text = player.idPlayer;
            
        }
    }
    
    else {
        
        ESTOrientedPoint *stationPosition = [ESTOrientedPoint pointFromDictionary:data[@"station_position"]];
        
        Player *player = [self.turn playerIdentifiedById:data[@"player"]];
        
        if (![player.idPlayer isEqualToString:self.player.idPlayer]) {
            UIImageView *view = self.stationsImageView[occupiedStation.macAddress];
            if (!view) {
                view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red.png"]];
                view.alpha = 0.5;
                [self.locationView addSubview:view];
                self.stationsImageView[occupiedStation.macAddress] = view;
            }
            [self.locationView drawObject:view withPosition:stationPosition];
            
            
        }
        else {
            UIImageView *view = self.stationsImageView[occupiedStation.macAddress];
            if (!view) {
                view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green.png"]];
                view.alpha = 0.5;
                [self.locationView addSubview:view];
                self.stationsImageView[occupiedStation.macAddress] = view;
            }
            [self.locationView drawObject:view withPosition:stationPosition];
            
        }
        
        occupiedStation.player = player;
        player.hasStation = YES;
        occupiedStation.isActive = NO;
        
    }
    
    
}

#pragma mark TakeStation bus method (host)

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
    Station *station = [self.turn stationIdentifiedByMacAddress:data[@"station"]];
    ESTOrientedPoint *stationPosition = [ESTOrientedPoint pointFromDictionary:data[@"station_position"]];
    if (station.isActive && [playerPosition distanceToPoint:stationPosition] <= DEFAULT_PROXIMITY_DISTANCE) {
        
        [self.positionObject sendPosition:message onSession:self.sessionId];
        [self didReceiveNewPositionMessage:message forSession:self.sessionId];
        
        BOOL endTurn = YES;
        
        for(Station *s in self.turn.stations){
            if(s.isActive){
                endTurn = NO;
                break;
            }
        }
        
        if(endTurn){
            [self endTurn];
        }
    }
    
}

#pragma mark Turn logic (host)

-(void)startTurn {
    
    self.turn = [[Turn alloc] init];
    [self.game.turns addObject:self.turn];
    
    for(Player *player in self.game.players){
        if(player.isActive){
            [self.turn.players addObject:player];
            player.hasStation = NO;
        }
    }
    
    int i=0;
    for (ESTPositionedBeacon *beacon in self.location.beacons) {
        
        if(i==[self.turn.players count]-1)
            break;
        
        Station *station = [[Station alloc] init];
        station.macAddress = beacon.macAddress;
        [self.turn.stations addObject:station];
        
        i++;
        
    }

    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    NSMutableArray *players = [NSMutableArray array];
    
    for(Player *player in self.turn.players){
        [players addObject:[NSDictionary dictionaryWithObjectsAndKeys:player.idPlayer, @"id", player.image, @"image", nil]];
    }
    
    data[@"players"]=players;
    
    NSMutableArray *stations = [NSMutableArray array];

    for(Station *station in self.turn.stations){
        [stations addObject:station.macAddress];
    }
    
    data[@"stations"]=stations;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: NSJSONWritingPrettyPrinted error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    
    [self.turnObject startTurnWithMessage:message forSession:self.sessionId];
    //[self didStartTurnWithMessage:message forSession:self.sessionId];
    [self playSound:@"go" afterSeconds:2];
}

-(void)endTurn {
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for(Player *p in self.turn.players){
        if(!p.hasStation){
            data[@"loser"]=p.idPlayer;
        }
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options: NSJSONWritingPrettyPrinted error:&error];
    NSString *message = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self.turnObject endTurnWithMessage:message forSession:self.sessionId];
    
}

#pragma mark Turn signal handler (client)

-(void)didStartTurnWithMessage:(NSString *)message forSession:(AJNSessionId)sessionId {
    
    NSLog(@"Start turn signal received %@", message);
    
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if(jsonError)
        return;
    
    self.turn=[Turn new];
    NSArray *stations = data[@"stations"];
    
    for(NSString *macAddress in stations){
        Station *station = [Station new];
        station.macAddress = macAddress;
        [self.turn.stations addObject: station];
    }
    
    NSArray *players = data[@"players"];
    
    for(NSDictionary *playerDic in players){
        Player *player = [Player new];
        player.idPlayer = playerDic[@"id"];
        player.image = playerDic[@"image"];
        [self.turn.players addObject:player];
    }

    
    
}

-(void)didEndTurnWithMessage:(NSString *)message forSession:(AJNSessionId)sessionId {
    
    NSLog(@"End turn signal received %@", message);
    
}


#pragma mark Utility

-(void)playSound: (NSString *)soundName afterSeconds: (int)seconds{
    
    NSString *path  = [[NSBundle mainBundle] pathForResource:soundName ofType:@"wav"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSError *error;
        NSURL *pathURL = [NSURL fileURLWithPath : path];
        self.audioPlayer = [[AVAudioPlayer alloc]
                            initWithContentsOfURL:pathURL
                            error:&error];
        [self.audioPlayer play];
    });
    
    
    
}


#pragma mark AllJoyn bus stuff

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
        
        if (!self.isHost) {
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
    if (!self.isHost) {
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
    
    [self.busAttachment unregisterSignalHandler:self.turnHandler];
    
    [self.busAttachment unregisterBusObject:self.positionObject];
    
    [self.busAttachment unregisterBusObject:self.turnObject];
    
    if(self.isHost)
        [self.busAttachment unregisterBusObject:self.hostObject];
    
    
    
    
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
    
    self.turnHandler.delegate = nil;
    self.turnObject = nil;
    
    self.hostObject = nil;
    
    self.proxyHostObject = nil;
    
    self.busAttachment = nil;
    
}

- (void)listenerDidRegisterWithBus:(AJNBusAttachment *)busAttachment{
    self.player.idPlayer = busAttachment.uniqueName;
}

- (NSString *)sessionlessSignalMatchRule
{
    return @"sessionless='t'";
}

# pragma mark AllJoyn session stuff (client)

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


# pragma mark AllJoyn session stuff (host)

- (void)didJoin:(NSString *)joiner inSessionWithId:(AJNSessionId)sessionId onSessionPort:(AJNSessionPort)sessionPort
{
    NSLog(@"JOIN");
    if([self.game.players count] == self.numberOfPlayers)
        return;
    
    if(!self.player.idPlayer)
        self.player.idPlayer=self.busAttachment.uniqueName;
    
    
    self.sessionId = sessionId;
    Player *player = [[Player alloc] initWithIdPlayer:joiner];
    [self.game.players addObject:player];
    player.image = [self.images objectAtIndex:0];
    [self.images removeObjectAtIndex:0];
    
    if(self.numberOfPlayers == [self.game.players count])
    {
        [self startTurn];
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
