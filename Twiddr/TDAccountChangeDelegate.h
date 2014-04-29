//
//  TDAccountSyncDelegate.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/26/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDAccountChangeDelegate

@optional

- (void)mergedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers
                                      newUsers:(NSArray *)newUsers
                                  deletedUsers:(NSArray *)deletedUsers
                                unchangedUsers:(NSArray *)unchangedUsers;

- (void)mergedTimelineFromApiWithNewTweets:(NSArray *)newTweets;

- (void)assignedOrphanTweetsToAuthorWithUnassginedTweets:(NSArray *)unassginedTweets
                                           affectedUsers:(NSArray *)affectedUsers;

@end
