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
#import <STTwitter/NSError+STTwitter.h>
#import "Constants.h"
#import "TDTimelineGap.h"
#import "TDTweet.h"
#import "TDUser.h"


@implementation TDAccount

@synthesize twitterApi = _twitterApi;
@synthesize changeDelegates = _changeDelegates;


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


- (NSSet *)tweetsNoAuthorAssigned
{
    NSPredicate *nullAuthorTweetsPredicate = [NSPredicate predicateWithFormat:@"author <> NULL"];
    return [self.timeline_tweets filteredSetUsingPredicate:nullAuthorTweetsPredicate];
}


#pragma mark - Events

- (BOOL)registerSyncDelegate:(NSObject<TDAccountChangeDelegate> *)delegate
{
    if (_changeDelegates == nil) {
        _changeDelegates = [[NSMutableSet alloc] init];
    }
    
    if (![_changeDelegates containsObject:delegate]) {
        [_changeDelegates addObject:delegate];
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)deregisterSyncDelegate:(NSObject<TDAccountChangeDelegate> *)delegate
{
    if ([_changeDelegates containsObject:delegate]) {
        [_changeDelegates removeObject:delegate];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Sync

- (void)pullFollowingAndTimelineWithFinishBlock:(void(^)(NSError *error))finish
{
    __block int allFinished = 0;
    
    void(^allFinishBlock)() = ^void() {
        finish(nil);
    };
    
    [self performGetFriendsListWithFinishBlock:^(NSError *error, NSArray *users) {
        if (error) {
            // TODO: error handling
//            if ([[error domain] isEqualToString:kSTTwitterTwitterErrorDomain] &&
//                [error code] == STTwitterTwitterErrorRateLimitExceeded) {}
        } else {
            [self mergeFollowingWithFriendDictArray:users
                                        resultBlock:^(NSArray *updatedUsers,
                                                      NSArray *newUsers,
                                                      NSArray *deletedUsers,
                                                      NSArray *unchangedUsers)
            {
                allFinished |= 1 << 0;
                if (allFinished == 3) {
                    allFinishBlock();
                }
            }];
        }
    }];
    
    
    [self performGetStatusesHomeTimelineWithFinishBlock:^(NSError *error, NSArray *statuses) {
        NSLog(@"%lu", [statuses count]);
        if (error) {
            // TODO: error handling
//            if ([[error domain] isEqualToString:kSTTwitterTwitterErrorDomain] &&
//                [error code] == STTwitterTwitterErrorRateLimitExceeded) {}
        } else {
            [self mergeStatusesWithTweetsDictArray:statuses resultBlock:^(NSArray *newTweets) {
                allFinished |= 1 << 1;
                if (allFinished == 3) {
                    allFinishBlock();
                }
            }];
        }
    }];
}


- (void)assignOrphanTweetsToAuthorWithFinishBlock:(void(^)(NSArray *unassginedTweets, NSArray *affectedUsers))finish
{
    NSMutableArray *affectedUsers = [[NSMutableArray alloc] init];
    NSMutableSet *unassignedTweets = [NSMutableSet setWithSet:[self tweetsNoAuthorAssigned]];
    
    for (TDUser *user in self.following) {
        NSSet *targetSet = [unassignedTweets filteredSetUsingPredicate:
                            [NSPredicate predicateWithFormat:@"author_id_str == %@", user.id_str]];
        if ([targetSet count] > 0) {
            [user addStatuses:targetSet];
            [affectedUsers addObject:user];
            for (TDTweet *tweet in targetSet) {
                [unassignedTweets removeObject:tweet];
            }
        }
    }
    
    [TDSingletonCoreDataManager saveContext];
    
    for (NSObject<TDAccountChangeDelegate> *delegate in _changeDelegates) {
        if ([delegate respondsToSelector:@selector(assignedOrphanTweetsToAuthorWithUnassginedTweets:affectedUsers:)]) {
            [delegate assignedOrphanTweetsToAuthorWithUnassginedTweets:[unassignedTweets allObjects]
                                                         affectedUsers:(NSArray *)affectedUsers];
        }
    }
    
    finish([unassignedTweets allObjects], (NSArray *)affectedUsers);
}


#pragma mark - Twitter API Wrapper

- (void)performGetAccountSettingsWithFinishBlock:(void(^)(NSError *error, NSDictionary *settings))finish
{
    [_twitterApi getAccountSettingsWithSuccessBlock:^(NSDictionary *settings) {
        finish(nil, settings);
    } errorBlock:^(NSError *error) {
        finish(error, nil);
    }];
}


- (void)performGetFriendsListWithFinishBlock:(void(^)(NSError *error, NSArray *users))finish
{
    __block NSMutableArray *allFriends;
    
    __block void(^next)(NSString *cursor) = ^void(NSString *cursor) {
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
             
             if ([users count] > 0) {
                 next(nextCursor);
             } else {
                 next = nil;
                 finish(nil, allFriends);
             }
         } errorBlock:^(NSError *error) {
             finish(error, allFriends);
         }];
    };
    
    next(nil);
}


- (void)performGetStatusesHomeTimelineWithFinishBlock:(void(^)(NSError *error, NSArray *statuses))finish
{
    __block NSMutableArray *allStatuses;
    
    __block void(^next)(NSString *maxId) = ^void(NSString *maxId) {
        [_twitterApi getStatusesHomeTimelineWithCount:@"200"
                                              sinceID:self.newest_timeline_tweet_id_str
                                                maxID:maxId
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
             
             if (self.newest_timeline_tweet_id_str == nil) {
                 next = nil;
                 finish(nil, allStatuses);
             } else if ([statuses count] > 0) {
                 next([self idStrMinusOne:[statuses lastObject][@"id_str"]]);
             } else {
                 next = nil;
                 finish(nil, allStatuses);
             }
         } errorBlock:^(NSError *error) {
             finish(error, allStatuses);
         }];
    };
    
    next(nil);
}


#pragma mark - Helpers

- (NSString *)idStrMinusOne:(NSString *)idStr
{
    unsigned long long idNum = [idStr longLongValue];
    idNum--;
    return [NSString stringWithFormat:@"%llu", idNum];
}


- (void)mergeFollowingWithFriendDictArray:(NSArray *)friends
                              resultBlock:(void(^)(NSArray *updatedUsers,
                                                   NSArray *newUsers,
                                                   NSArray *deletedUsers,
                                                   NSArray *unchangedUsers))result
{
    NSMutableArray *updatedUsers = [[NSMutableArray alloc] init];
    NSMutableArray *newUsers = [[NSMutableArray alloc] init];
    NSMutableArray *deletingUsers = [NSMutableArray arrayWithArray:[self.following allObjects]];
    // TODO: track changed users
    NSMutableArray *unchangedUsers = nil;
    
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
    
    for (NSObject<TDAccountChangeDelegate> *delegate in _changeDelegates) {
        if ([delegate respondsToSelector:
             @selector(mergedFollowingFromApiWithUpdatedUsers:newUsers:deletedUsers:unchangedUsers:)])
        {
            [delegate mergedFollowingFromApiWithUpdatedUsers:updatedUsers
                                                    newUsers:newUsers
                                                deletedUsers:deletingUsers
                                              unchangedUsers:unchangedUsers];
        }
    }
    
    result((NSArray *)updatedUsers, (NSArray *)newUsers, (NSArray *)deletingUsers, (NSArray *)unchangedUsers);
}


- (void)mergeStatusesWithTweetsDictArray:(NSArray *)tweets resultBlock:(void(^)(NSArray *newTweets))result
{
    NSMutableSet *newTweets = [[NSMutableSet alloc] init];
    
    for (NSDictionary *tweetDict in tweets) {
        TDTweet *tweet = [TDTweet tweetWithRawDictionary:tweetDict];
        [newTweets addObject:tweet];
    }
    
    [self addTimeline_tweets:newTweets];
    NSString *newest_timeline_tweet_id_str = [tweets firstObject][@"id_str"];
    if (newest_timeline_tweet_id_str) {
        self.newest_timeline_tweet_id_str = newest_timeline_tweet_id_str;
    }
    [TDSingletonCoreDataManager saveContext];
    
    for (NSObject<TDAccountChangeDelegate> *delegate in _changeDelegates) {
        if ([delegate respondsToSelector:@selector(mergedTimelineFromApiWithNewTweets:)]) {
            [delegate mergedTimelineFromApiWithNewTweets:[newTweets allObjects]];
        }
    }
    
    result([newTweets allObjects]);
}


- (void)assignStatusesToFollowing
{
//    NSArray *ophenTweets = [TDTweet tweetsNotAssignedToAuthor];
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
