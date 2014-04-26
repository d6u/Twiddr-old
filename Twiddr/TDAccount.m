//
//  TDAccount.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/24/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAccount.h"
#import "TDUser.h"
#import "TDSingletonCoreDataManager.h"
#import <STTwitter/STTwitter.h>
#import "Constants.h"


@implementation TDAccount

@synthesize twitterApi = _twitterApi;

#pragma mark - Interfaces

+ (NSArray *)allAccounts
{
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Account"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *accounts = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"-- ERROR: %@", error);
    }
    
    return accounts;
}


+ (instancetype)accountWithRawDictionary:(NSDictionary *)keyedValues
{
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    TDAccount *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account"
                                                       inManagedObjectContext:context];
    [account setValuesForKeysWithRawDictionary:keyedValues];
    return account;
}


- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues
{
    [self setValuesForKeysWithDictionary:keyedValues];
}


- (void)initTwitterApi
{
    _twitterApi = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWAPIKey
                                                consumerSecret:TWAPISecret
                                                    oauthToken:self.token
                                              oauthTokenSecret:self.token_secret];
}


- (void)initTwitterApiWithToken:(NSString *)token TokenSecret:(NSString *)tokenSecret
{
    _twitterApi = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWAPIKey
                                                consumerSecret:TWAPISecret
                                                    oauthToken:token
                                              oauthTokenSecret:tokenSecret];
}


- (void)validateTwitterAccountAuthorizationWithFinishBlock:(void(^)(BOOL valid))finish
{
    [_twitterApi getAccountSettingsWithSuccessBlock:^(NSDictionary *settings) {
        finish(YES);
    } errorBlock:^(NSError *error) {
        finish(NO);
    }];
}


#pragma mark - Core Data

@dynamic id_str;
@dynamic screen_name;
@dynamic token;
@dynamic token_secret;
@dynamic newest_timeline_tweet_id_str;
@dynamic following;

@end
