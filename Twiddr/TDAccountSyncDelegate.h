//
//  TDAccountSyncDelegate.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/26/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDAccountSyncDelegate

@optional

- (void)syncedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers
                                      newUsers:(NSArray *)newUsers
                                  deletedUsers:(NSArray *)deletedUsers
                                unchangedUsers:(NSArray *)unchangedUsers;

- (void)syncedTimelineFromApiWithNewTweets:(NSArray *)newTweets
                             affectedUsers:(NSArray *)affectedUsers
                          unassignedTweets:(NSArray *)unassignedTweets;

- (void)syncedTimelineFromApiWhenRatedExceededWithNewTweets:(NSArray *)newTweets
                                              affectedUsers:(NSArray *)affectedUsers
                                            lowerBoundaryId:(NSString *)lowerBoundaryId
                                            upperBoundaryId:(NSString *)upperBoundaryId;

@end
