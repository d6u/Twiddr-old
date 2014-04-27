//
//  TDAccount.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/24/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TDAccountSyncDelegate.h"

@class TDUser;
@class STTwitterAPI;


@interface TDAccount : NSManagedObject

@property (strong, nonatomic) STTwitterAPI *twitterApi;
@property (nonatomic, strong) NSMutableSet *syncDelegates;

#pragma mark - Interfaces

+ (NSArray *)allAccounts;
+ (instancetype)accountWithRawDictionary:(NSDictionary *)keyedValues;
- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues;
- (void)initTwitterApi;
- (void)initTwitterApiWithToken:(NSString *)token TokenSecret:(NSString *)tokenSecret;


#pragma mark - Events

- (BOOL)registerSyncDelegate:(id<TDAccountSyncDelegate>)delegate;
- (BOOL)deregisterSyncDelegate:(id<TDAccountSyncDelegate>)delegate;


#pragma mark - Twitter API

- (void)validateTwitterAccountAuthorizationWithFinishBlock:(void(^)(BOOL valid))finish;
- (void)syncAccountWithFinishBlock:(void(^)(NSError *error))finish;
- (void)syncFollowingWithFinishBlock:(void(^)(NSArray *updatedUsers,
                                              NSArray *newUsers,
                                              NSArray *deletedUsers,
                                              NSArray *unchangedUsers))finish;
- (void)syncTimelineWithFinishBlock:(void(^)(NSArray *newTweets,
                                             NSArray *affectedUsers,
                                             NSArray *unassignedTweets))finish;


#pragma mark - Core Data

@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * token_secret;
@property (nonatomic, retain) NSString * newest_timeline_tweet_id_str;
@property (nonatomic, retain) NSSet *following;

@end

@interface TDAccount (CoreDataGeneratedAccessors)

- (void)addFollowingObject:(TDUser *)value;
- (void)removeFollowingObject:(TDUser *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

@end
