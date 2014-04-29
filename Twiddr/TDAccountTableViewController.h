//
//  TDMasterViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAccountChangeDelegate.h"


@interface TDAccountTableViewController : UITableViewController <UITableViewDelegate, TDAccountChangeDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL firstLoadSinceAppLaunch;

@property (strong, nonatomic) NSMutableArray *accounts;

- (IBAction)addAccount:(id)sender;

@end
