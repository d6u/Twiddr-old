//
//  TDAppDelegate.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/15/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAppDelegate.h"
#import "TDAccountTableViewController.h"
#import "TDSingletonCoreDataManager.h"


@implementation TDAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Assign ManagedObjectContext to first view controller
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    TDAccountTableViewController *controller = (TDAccountTableViewController *)navigationController.topViewController;
    controller.managedObjectContext = [TDSingletonCoreDataManager getManagedObjectContext];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [TDSingletonCoreDataManager saveContext];
}


@end
