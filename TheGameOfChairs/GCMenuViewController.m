//
//  GCMenuViewController.m
//  TheGameOfChairs
//
//  Created by silvia promontorio on 28/02/15.
//  Copyright (c) 2015 AllSeen Alliance. All rights reserved.
//

#import "GCMenuViewController.h"
#import "Game.h"
#import "GCViewController.h"
#import "ESTLocation.h"
#import "ESTLocationBuilder.h"
#import "ESTIndoorLocationManager.h"
#import "ESTIndoorLocationView.h"

@interface GCMenuViewController ()<UIActionSheetDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *roleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *numberOfPlayersView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@end

@implementation GCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.roleView addTarget:self
                                action:@selector(roleChanged:)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.roleView addTarget:self
                      action:@selector(roleChanged:)
            forControlEvents:UIControlEventValueChanged];
    
    self.numberOfPlayersView.enabled = NO;
    self.numberOfPlayersView.selectedSegmentIndex = 0;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // Do any additional setup after loading the view.
}

-(void)roleChanged: (id)obj{
    if(self.roleView.selectedSegmentIndex==0){
        self.numberOfPlayersView.enabled = NO;
    }
    else{
        self.numberOfPlayersView.enabled = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    NSDictionary *location = [[NSUserDefaults standardUserDefaults] objectForKey:@"location"];
    if(!location){
        self.startButton.enabled = NO;
    }
    else{
        self.startButton.enabled = YES;
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)presentActionSheet{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"New location"
                                                             delegate: self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Map your room", @"Load from JSON", nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==0){
        [self presentLocationSetupController];
    }
    else if(buttonIndex == 1){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Load from JSON" message:@"Copy your JSON data here" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *textField = [alertView textFieldAtIndex:0];
    ESTLocation *location = [ESTLocationBuilder parseFromJSON:textField.text];
    if(location)
    {
        NSDictionary *rawLocation = [location toDictionary];
        [[NSUserDefaults standardUserDefaults] setObject:rawLocation forKey:@"location"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.startButton.enabled = YES;
    }
    else {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Invalid JSON" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [errorView show];
    }
    
}

-(void)presentLocationSetupController{
    
    __weak GCMenuViewController *weakSelf = self;
    UIViewController *nextVC = [ESTIndoorLocationManager locationSetupControllerWithCompletion:^(ESTLocation *location, NSError *error) {
        
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (location)
            {
                NSDictionary *rawLocation = [location toDictionary];
                [[NSUserDefaults standardUserDefaults] setObject:rawLocation forKey:@"location"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self.startButton.enabled = YES;
            }
        }];
    }];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nextVC];
    [self presentViewController:navController animated:YES completion:nil];
    
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    Game *game = [Game new];
    game.numberOfPlayers = self.numberOfPlayersView.selectedSegmentIndex+2;
    game.isHost = self.roleView.selectedSegmentIndex == 1;
    
    GCViewController *controller = [segue destinationViewController];
    controller.game = game;
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
