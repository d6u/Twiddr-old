//
//  TDAccount.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/24/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TDAccountChangeDelegate.h"

@class STTwitterAPI, TDTimelineGap, TDTweet, TDUser;


@interface TDAccount : NSManagedObject

@property (strong, nonatomic) STTwitterAPI *twitterApi;
@property (nonatomic, strong) NSMutableSet *changeDelegates;


#pragma mark - Interfaces

+ (NSArray *)allAccounts;
+ (instancetype)accountWithRawDictionary:(NSDictionary *)keyedValues;
- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues;
- (void)initTwitterApi;
- (void)initTwitterApiWithToken:(NSString *)token TokenSecret:(NSString *)tokenSecret;
- (NSSet *)tweetsNoAuthorAssigned;


#pragma mark - Events

- (BOOL)registerSyncDelegate:(NSObject<TDAccountChangeDelegate> *)delegate;
- (BOOL)deregisterSyncDelegate:(NSObject<TDAccountChangeDelegate> *)delegate;


#pragma mark - Twitter API

/**
 *  Keywords explaination
 *
 *  perform: simple wrapper for twitterApi
 *  pull: fetch and merge (download, sync, resolve conflict)
 *  compare: return difference between provided and local copies
 */

- (void)performGetAccountSettingsWithFinishBlock:(void(^)(NSError *error, NSDictionary *settings))finish;
- (void)pullFollowingAndTimelineWithFinishBlock:(void(^)(NSError *error))finish;


#pragma mark - Core Data

@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * newest_timeline_tweet_id_str;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * token_secret;

@property (nonatomic, retain) NSSet *following;
@property (nonatomic, retain) NSSet *timeline_tweets;
@property (nonatomic, retain) NSSet *timeline_gaps;

@end

@interface TDAccount (CoreDataGeneratedAccessors)

- (void)addFollowingObject:(TDUser *)value;
- (void)removeFollowingObject:(TDUser *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

- (void)addTimeline_tweetsObject:(TDTweet *)value;
- (void)removeTimeline_tweetsObject:(TDTweet *)value;
- (void)addTimeline_tweets:(NSSet *)values;
- (void)removeTimeline_tweets:(NSSet *)values;

- (void)addTimeline_gapsObject:(TDTimelineGap *)value;
- (void)removeTimeline_gapsObject:(TDTimelineGap *)value;
- (void)addTimeline_gaps:(NSSet *)values;
- (void)removeTimeline_gaps:(NSSet *)values;

@end
