//
//  TDMasterViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDTwitterAccount;


@interface TDAccountTableViewController : UITableViewController <UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *twitterAccounts;

- (IBAction)addAccount:(id)sender;

@end
