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
#import "TDTimelineGap.h"
#import "TDTweet.h"
#import "TDUser.h"


@implementation TDAccount

@synthesize twitterApi = _twitterApi;
@synthesize syncDelegates = _syncDelegates;


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


#pragma mark - Events

- (BOOL)registerSyncDelegate:(id<TDAccountSyncDelegate>)delegate
{
    if (_syncDelegates == nil) {
        _syncDelegates = [[NSMutableSet alloc] init];
    }
    
    if (![_syncDelegates containsObject:delegate]) {
        [_syncDelegates addObject:delegate];
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)deregisterSyncDelegate:(id<TDAccountSyncDelegate>)delegate
{
    if ([_syncDelegates containsObject:delegate]) {
        [_syncDelegates removeObject:delegate];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Twitter API

- (void)validateTwitterAccountAuthorizationWithFinishBlock:(void(^)(BOOL valid))finish
{
    [_twitterApi getAccountSettingsWithSuccessBlock:^(NSDictionary *settings) {
        finish(YES);
    } errorBlock:^(NSError *error) {
        finish(NO);
    }];
}


- (void)syncAccountWithFinishBlock:(void(^)(NSError *error))finish
{
    if (_twitterApi) {
        __block NSArray *gotTimeline;
        __block BOOL friendsSynced = NO;
        __block BOOL timelineDownloaded = NO;
        
        __block void(^allFinish)() = ^void() {
            [self saveStatusesWithTweetsDictArray:gotTimeline
                                      resultBlock:^(NSArray *newTweets,
                                                    NSArray *affectedUsers,
                                                    NSArray *unassignedTweets)
             {
                 NSDictionary *latestTweets = [gotTimeline firstObject];
                 if (latestTweets) {
                      self.newest_timeline_tweet_id_str = latestTweets[@"id_str"];
                      [TDSingletonCoreDataManager saveContext];
                 }
                 
                 for (NSObject<TDAccountSyncDelegate> *delegate in _syncDelegates) {
                     if ([delegate respondsToSelector:
                          @selector(syncedTimelineFromApiWithNewTweets:affectedUsers:unassignedTweets:)])
                     {
                         [delegate syncedTimelineFromApiWithNewTweets:newTweets
                                                        affectedUsers:affectedUsers
                                                     unassignedTweets:unassignedTweets];
                     }
                 }
                 
                 finish(nil);
             }];
        };
        
        // Following
        [self syncFollowingWithFinishBlock:^(NSArray *updatedUsers,
                                             NSArray *newUsers,
                                             NSArray *deletedUsers,
                                             NSArray *unchangedUsers)
        {
            friendsSynced = YES;
            if (timelineDownloaded) {
                allFinish();
            }
        }];
        
        // Timeline
        [self getTimelineSinceID:self.newest_timeline_tweet_id_str
                           maxID:nil
                       recursive:YES
                     finishBlock:^(NSError *error, NSArray *statuses)
         {
             NSLog(@"getTimelineSinceID %lu", [statuses count]);
             if (error == nil) {
                 gotTimeline = statuses;
                 timelineDownloaded = YES;
                 if (friendsSynced) {
                     allFinish();
                 }
             }
         }];
        
    } else {
        NSError *error = [NSError errorWithDomain:@"com.daiwei.Twiddr.TDAccount"
                                             code:100
                                         userInfo:@{@"description": @"twitterApi id has not initialized"}];
        finish(error);
    }
}


- (void)syncFollowingWithFinishBlock:(void(^)(NSArray *updatedUsers,
                                              NSArray *newUsers,
                                              NSArray *deletedUsers,
                                              NSArray *unchangedUsers))finish
{
    [self getFriendsWithFinishBlock:^(NSError *error, NSArray *friends) {
        if (error == nil) {
            [self saveFollowingWithFriendDictArray:friends resultBlock:^(NSArray *updatedUsers,
                                                                         NSArray *newUsers,
                                                                         NSArray *deletedUsers,
                                                                         NSArray *unchangedUsers)
            {
                for (NSObject<TDAccountSyncDelegate> *delegate in _syncDelegates) {
                    if ([delegate respondsToSelector:
                         @selector(syncedFollowingFromApiWithUpdatedUsers:newUsers:deletedUsers:unchangedUsers:)])
                    {
                        [delegate syncedFollowingFromApiWithUpdatedUsers:updatedUsers
                                                                newUsers:newUsers
                                                            deletedUsers:deletedUsers
                                                          unchangedUsers:unchangedUsers];
                    }
                }
                
                finish(updatedUsers, newUsers, deletedUsers, unchangedUsers);
            }];
        }
        // TODO: add error handling
    }];
}


- (void)syncTimelineWithFinishBlock:(void(^)(NSArray *newTweets,
                                             NSArray *affectedUsers,
                                             NSArray *unassignedTweets))finish
{
    [self getTimelineSinceID:self.newest_timeline_tweet_id_str
                       maxID:nil
                   recursive:YES
                 finishBlock:^(NSError *error, NSArray *statuses)
    {
        if (error == nil) {
            [self saveStatusesWithTweetsDictArray:statuses
                                      resultBlock:^(NSArray *newTweets,
                                                    NSArray *affectedUsers,
                                                    NSArray *unassignedTweets)
            {
                NSDictionary *latestTweets = [statuses firstObject];
                self.newest_timeline_tweet_id_str = latestTweets[@"id_str"];
                [TDSingletonCoreDataManager saveContext];
                
                for (NSObject<TDAccountSyncDelegate> *delegate in _syncDelegates) {
                    if ([delegate respondsToSelector:
                         @selector(syncedTimelineFromApiWithNewTweets:affectedUsers:unassignedTweets:)])
                    {
                        [delegate syncedTimelineFromApiWithNewTweets:newTweets
                                                       affectedUsers:affectedUsers
                                                    unassignedTweets:unassignedTweets];
                    }
                }
                
                finish(newTweets, affectedUsers, unassignedTweets);
            }];
        }
    }];
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
             
             if ([users count] < 196) {
                 finish(nil, allFriends);
             } else {
                 cursor = nextCursor;
                 weakNext();
             }
         } errorBlock:^(NSError *error) {
             NSLog(@"--- Error: %@", error);
             // TODO: specify rate limit error
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
             
             if ([statuses count] < 196) {
                 finish(nil, allStatuses);
             } else if (recursive && sinceID != nil) {
                 maxIdStr = [self idStrMinusOne:[statuses lastObject][@"id_str"]];
                 weakNext();
             } else {
                 finish(nil, allStatuses);
             }
         } errorBlock:^(NSError *error) {
             NSLog(@"--- Error: %@", error);
             // TODO: specify rate limit error
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


- (void)saveFollowingWithFriendDictArray:(NSArray *)friends resultBlock:(void(^)(NSArray *updatedUsers,
                                                                                 NSArray *newUsers,
                                                                                 NSArray *deletedUsers,
                                                                                 NSArray *unchangedUsers))result
{
    NSMutableArray *updatedUsers = [[NSMutableArray alloc] init];
    NSMutableArray *newUsers = [[NSMutableArray alloc] init];
    NSMutableArray *deletingUsers = [NSMutableArray arrayWithArray:[self.following allObjects]];
    // TODO: track changed users
//    NSMutableArray *unchangedUsers = nil;
    
    for (NSDictionary *friendDict in friends) {
        BOOL found = NO;
        for (TDUser *user in deletingUsers) {
            if ([[user id_str] isEqualToString:friendDict[@"id_str"]]) {
                [user setValuesForKeysWithRawDictionary:friendDict];
                [deletingUsers removeObject:user];
                [updatedUsers addObject:user];
                found = YES;
                break;
            }
        }
        
        // No user on local found
        if (!found) {
            TDUser *user = [TDUser userWithRawDictionary:friendDict];
            [self addFollowingObject:user];
            [newUsers addObject:user];
        }
    }
    
    // Remove users left in following array
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    for (TDUser *user in deletingUsers) {
        [context deleteObject:user];
    }
    
    [TDSingletonCoreDataManager saveContext];
    
    result((NSArray *)updatedUsers, (NSArray *)newUsers, (NSArray *)deletingUsers, nil);
}


- (void)saveStatusesWithTweetsDictArray:(NSArray *)tweets
                            resultBlock:(void(^)(NSArray *newTweets,
                                                 NSArray *affectedUsers,
                                                 NSArray *unassignedTweets))result
{
    NSMutableArray *newTweets = [[NSMutableArray alloc] init];
    NSMutableSet *affectedUsers = [[NSMutableSet alloc] init];
    NSMutableArray *unassignedTweets = [NSMutableArray arrayWithArray:tweets];
    
    for (NSDictionary *tweetDict in tweets) {
        BOOL attached = NO;
        for (TDUser *user in self.following) {
            if ([user.id_str isEqualToString:tweetDict[@"user"][@"id_str"]]) {
                TDTweet *tweet = [TDTweet tweetWithRawDictionary:tweetDict];
                [user addStatusesObject:tweet];
                [newTweets addObject:tweet];
                [affectedUsers addObject:user];
                attached = YES;
                break;
            }
        }
        
        if (!attached) {
            [unassignedTweets addObject:tweetDict];
        }
    }
    
    [TDSingletonCoreDataManager saveContext];
    
    result(newTweets, [affectedUsers allObjects], unassignedTweets);
}


#pragma mark - Core Data

@dynamic id_str;
@dynamic newest_timeline_tweet_id_str;
@dynamic screen_name;
@dynamic token;
@dynamic token_secret;

@dynamic following;
@dynamic timeline_tweets;
@dynamic timeline_gaps;

@end
