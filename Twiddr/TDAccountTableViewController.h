//
//  TDMasterViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAccountChangeDelegate.h"


@interface TDAccountTableViewController : UITableViewController

@property (nonatomic) BOOL firstLoadSinceAppLaunch;

- (IBAction)addAccount:(id)sender;

@end
