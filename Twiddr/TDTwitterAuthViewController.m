//
//  TDTwitterAuthViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTwitterAuthViewController.h"
#import "TDAccountTableViewController.h"
#import <STTwitter/STTwitter.h>
#import "Constants.h"
#import "TDTwitterAccount.h"
#import <SSKeychain/SSKeychain.h>


@interface TDTwitterAuthViewController ()

@end


@implementation TDTwitterAuthViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.callbackErrorBlock = ^void(NSError *error) {
        NSLog(@"-- error: %@", error);
    };
    self.webView.delegate = self;
}


- (void)viewDidAppear:(BOOL)animated
{
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWAPIKey consumerSecret:TWAPISecret];
    self.twitterAccount = [TDTwitterAccount accountWithTwitter:twitter];
    
    void (^postTokenRequestBlock)(NSURL *, NSString *) = ^void(NSURL *url, NSString *oauthToken) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    };
    
    [self.twitterAccount.twitterApi postTokenRequest:postTokenRequestBlock
                                          forceLogin:@(YES)
                                          screenName:nil
                                       oauthCallback:TWAPICallback
                                          errorBlock:self.callbackErrorBlock];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Web View delegate

- (BOOL)           webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] hasPrefix:TWAPICallback])
    {
        NSDictionary *d = [self parametersDictionaryFromQueryString:[request.URL query]];
        
        void (^successBlock)(NSString *, NSString *, NSString *, NSString *) =
        ^void(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
            [self saveTwitterAccountScreenName:screenName OauthToken:oauthToken tokenSecret:oauthTokenSecret];
        };
        
        [self.twitterAccount.twitterApi postAccessTokenRequestWithPIN:d[@"oauth_verifier"]
                                                         successBlock:successBlock
                                                           errorBlock:self.callbackErrorBlock];
        return NO;
    }
    else {
        return YES;
    }
}


#pragma mark - IBActions

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Helpers

- (void)saveTwitterAccountScreenName:(NSString *)screenName OauthToken:(NSString *)oauthToken tokenSecret:(NSString *)oauthTokenSecret
{
    // Save token to keychain
    [SSKeychain setPassword:oauthToken forService:@"TwiddrOauthTokenService" account:screenName];
    [SSKeychain setPassword:oauthTokenSecret forService:@"TwiddrTokenSecretService" account:screenName];
    
    // Save account info to TDAccount view controller, and dismiss current view
    [self.twitterAccount.twitterApi getAccountSettingsWithSuccessBlock:^(NSDictionary *settings) {
        self.twitterAccount.accountSetting = settings;
        self.twitterAccount.screenName = settings[@"screen_name"];
        [self.accountTableViewController.twitterAccounts addObject:self.twitterAccount];
        [self dismissViewControllerAnimated:YES completion:nil];
    } errorBlock:self.callbackErrorBlock];
}


- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    for(NSString *s in queryComponents) {
        NSArray *pair = [s componentsSeparatedByString:@"="];
        if([pair count] != 2) continue;
        NSString *key = pair[0];
        NSString *value = pair[1];
        md[key] = value;
    }
    return md;
}


@end
