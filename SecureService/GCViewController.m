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


@interface GCViewController () <GCPositionReceiver, AJNBusListener, ESTIndoorLocationManagerDelegate>


@property (nonatomic, strong) AJNBusAttachment *busAttachment;
@property (nonatomic, strong) GCPositionObject *sixiObject;
@property (nonatomic) AJNSessionId sessionId;
@property (nonatomic, strong) GCPositionObjectSignalHandler *signalHandler;
@property (nonatomic, strong) ESTLocation *location;
@property (nonatomic, strong) ESTIndoorLocationManager *manager;
@property (nonatomic, strong) NSMutableDictionary *playersImageView;
@property (weak, nonatomic) IBOutlet ESTIndoorLocationView *locationView;



@end

@implementation GCViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.manager = [ESTIndoorLocationManager new];
    self.manager.delegate = self;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"location" ofType:@"json"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    self.location = [ESTLocationBuilder parseFromJSON:content];
    
    QStatus status = ER_OK;
    
    
    self.busAttachment = [[AJNBusAttachment alloc] initWithApplicationName:kAppName allowRemoteMessages:YES];
    
    AJNInterfaceDescription* posInterface = [self.busAttachment createInterfaceWithName:kInterfaceName];
    
    [posInterface addSignalWithName:@"Position" inputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"str"]];
    if (status != ER_OK) {
        NSLog(@"ERROR: Failed to add signal to chat interface. %@", [AJNStatus descriptionForStatusCode:status]);
    }
    
    [posInterface activate];
    
    
    self.sixiObject = [[GCPositionObject alloc] initWithBusAttachment:self.busAttachment onServicePath:kServicePath];
    self.sixiObject.delegate = self;
    
    [self.busAttachment registerBusObject:self.sixiObject];
    
    self.signalHandler = [[GCPositionObjectSignalHandler alloc] init];
    self.signalHandler.delegate = self;
    [self.busAttachment registerSignalHandler:self.signalHandler];
    
    [self.busAttachment start];
    
    [self.busAttachment registerBusListener:self];
    
    [self.busAttachment connectWithArguments:@"null:"];
    
    [self.busAttachment addMatchRule:[self sessionlessSignalMatchRule]];

    // Do any additional setup after loading the view.
    
    self.playersImageView = [NSMutableDictionary dictionary];
    
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.locationView.backgroundColor = [UIColor clearColor];
    
    self.locationView.showTrace               = YES;
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

    [self.manager startIndoorLocation:self.location];
}

- (NSString *)sessionlessSignalMatchRule
{
    return @"sessionless='t'";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)didReceiveNewPositionMessage:(NSString *)message{
    NSLog(@"RICEVUTA POSIZIONE: %@", message);
    
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
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
    }

}

- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager
            didUpdatePosition:(ESTOrientedPoint *)position
                   inLocation:(ESTLocation *)location {
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
- (void)indoorLocationManager:(ESTIndoorLocationManager *)manager
didFailToUpdatePositionWithError:(NSError *)error {
    NSLog(@"errore posizione");

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