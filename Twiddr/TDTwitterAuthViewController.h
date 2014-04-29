//
//  TDTwitterAuthViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAccountChangeDelegate.h"

@class TDAccountTableViewController;
@class TDAccount;
@class STTwitterAPI;


@interface TDTwitterAuthViewController : UIViewController <UIWebViewDelegate>


@property (weak, nonatomic) TDAccountTableViewController *accountTableViewController;
@property (strong, nonatomic) TDAccount *account;


#pragma mark - UI

@property (strong, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)cancel:(id)sender;

@end
