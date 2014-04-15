//
//  TDTwitterAuthViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDAccountTableViewController;
@class TDTwitterAccount;


@interface TDTwitterAuthViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) TDAccountTableViewController *accountTableViewController;
@property (strong, nonatomic) TDTwitterAccount *twitterAccount;
@property (strong, nonatomic) void (^callbackErrorBlock)(NSError *);

@property (strong, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)cancel:(id)sender;

@end
