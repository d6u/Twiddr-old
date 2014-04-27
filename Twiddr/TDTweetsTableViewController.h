//
//  TDTweetsTableViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAccountSyncDelegate.h"

@class TDAccount;
@class TDUser;


@interface TDTweetsTableViewController : UITableViewController <TDAccountSyncDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) TDAccount *account;
@property (strong, nonatomic) TDUser *author;
@property (strong, nonatomic) NSMutableArray *tweets;

@end
