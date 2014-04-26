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
#import "TDTweet.h"


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


- (void)getFollowingAndTimelineWithFollowingFinishBlock:(void (^)(NSArray *following))followingFinish
                                    timelineFinishBlock:(void (^)(NSArray *tweets))timelineFinish
                                         allFinishBlock:(void (^)(NSError *error, NSArray *following))allFinish
{
    if (_twitterApi) {
        __block NSArray *unsavedStatuses;
        __block BOOL friendsSynced = NO;
        __block BOOL timelineSynced = NO;
        
        // Load Friends List
        [self getFriendsWithFinishBlock:^(NSError *error, NSArray *friends) {
            if (error != nil) {
                [self syncFollowingWithFriendDictArray:friends];
                followingFinish([self.following allObjects]);
            }
            friendsSynced = YES;
            if (timelineSynced) {
                allFinish(nil, [self.following allObjects]);
            }
        }];
        
        // Load Timeline
        [self getTimelineSinceID:self.newest_timeline_tweet_id_str
                           maxID:nil
                       recursive:YES
                     finishBlock:^(NSError *error, NSArray *statuses)
        {
            if (error != nil) {
                unsavedStatuses = [self syncStatusesWithTweetsDictArray:statuses];
                timelineFinish(statuses);
            }
            timelineSynced = YES;
            if (friendsSynced) {
                NSArray *finalUnsavedStatuses = [self syncStatusesWithTweetsDictArray:unsavedStatuses];
                if ([finalUnsavedStatuses count] > 0) {
                    NSLog(@"--- ERROR: there are still statuses unsaved: %@", finalUnsavedStatuses);
                }
                allFinish(nil, [self.following allObjects]);
            }
        }];
    } else {
        NSError *error = [NSError errorWithDomain:@"com.daiwei.Twiddr.TDAccount"
                                             code:100
                                         userInfo:@{@"description": @"twitterApi id has not initialized"}];
        allFinish(error, nil);
    }
}
         

#pragma mark - Helpers

- (void)getFriendsWithFinishBlock:(void(^)(NSError *error, NSArray *friends))finish
{
    __block NSMutableArray *allFriends;
    __block NSString *cursor;
    
    __block __weak void(^weakNext)();
    void(^next)();
    
    next = ^void() {
        [_twitterApi getFriendsListForUserID:self.id_str
                                orScreenName:nil
                                      cursor:cursor
                                       count:@"200"
                                  skipStatus:@(YES)
                         includeUserEntities:@(YES)
                                successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor)
         {
             if (allFriends == nil) {
                 allFriends = [[NSMutableArray alloc] init];
             }
             
             [allFriends addObjectsFromArray:users];
             
             if ([users count] < 200) {
                 finish(nil, allFriends);
             } else {
                 cursor = nextCursor;
                 weakNext();
             }
         } errorBlock:^(NSError *error) {
             NSLog(@"--- Error: %@", error);
             finish(error, allFriends);
         }];
    };
    
    next();
}


- (void)getTimelineSinceID:(NSString *)sinceID
                     maxID:(NSString *)maxID
                 recursive:(BOOL)recursive
               finishBlock:(void(^)(NSError *error, NSArray *statuses))finish
{
    __block NSMutableArray *allStatuses;
    __block NSString *maxIdStr = maxID;
    
    __block __weak void(^weakNext)();
    void(^next)();
    
    weakNext = next = ^void() {
        [_twitterApi getStatusesHomeTimelineWithCount:@"200"
                                              sinceID:sinceID
                                                maxID:maxID
                                             trimUser:@(NO)
                                       excludeReplies:@(NO)
                                   contributorDetails:@(NO)
                                      includeEntities:@(YES)
                                         successBlock:^(NSArray *statuses)
         {
             if (allStatuses == nil) {
                 allStatuses = [[NSMutableArray alloc] init];
             }
             
             [allStatuses addObjectsFromArray:statuses];
             
             if ([statuses count] < 200) {
                 finish(nil, allStatuses);
             } else if (recursive && sinceID != nil) {
                 maxIdStr = [self idStrMinusOne:[statuses lastObject][@"id_str"]];
                 weakNext();
             }
         } errorBlock:^(NSError *error) {
             NSLog(@"--- Error: %@", error);
             finish(error, allStatuses);
         }];
    };
    
    next();
}


- (NSString *)idStrMinusOne:(NSString *)idStr
{
    unsigned long long idNum = [idStr longLongValue];
    idNum--;
    return [NSString stringWithFormat:@"%llu", idNum];
}


- (void)syncFollowingWithFriendDictArray:(NSArray *)friends
{
    NSMutableArray *following = [NSMutableArray arrayWithArray:[self.following allObjects]];
    
    for (NSDictionary *friendDict in friends) {
        for (TDUser *user in following) {
            if ([user.id_str isEqualToString:friendDict[@"id_str"]]) {
                [user setValuesForKeysWithRawDictionary:friendDict];
                [following removeObject:user];
                break;
            }
        }
        
        // No user on local found
        TDUser *user = [TDUser userWithRawDictionary:friendDict];
        [self addFollowingObject:user];
    }
    
    // Remove users left in following array
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    for (TDUser *user in following) {
        [context deleteObject:user];
    }
    
    [TDSingletonCoreDataManager saveContext];
}


- (NSArray *)syncStatusesWithTweetsDictArray:(NSArray *)tweets
{
    NSMutableArray *unsavedTweetDict = [[NSMutableArray alloc] init];
    
    for (NSDictionary *tweetDict in tweets) {
        for (TDUser *user in self.following) {
            if ([user.id_str isEqualToString:tweetDict[@"user"][@"id_str"]]) {
                TDTweet *tweet = [TDTweet tweetWithRawDictionary:tweetDict];
                [user addStatusesObject:tweet];
                break;
            }
        }
        
        [unsavedTweetDict addObject:tweetDict];
    }
    
    return (NSArray *)unsavedTweetDict;
}


#pragma mark - Core Data

@dynamic id_str;
@dynamic screen_name;
@dynamic token;
@dynamic token_secret;
@dynamic newest_timeline_tweet_id_str;
@dynamic following;

@end
