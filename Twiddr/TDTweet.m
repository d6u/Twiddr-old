//
//  TDTweet.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTweet.h"
#import "TDUser.h"
#import "TDSingletonCoreDataManager.h"


@implementation TDTweet

+ (instancetype)tweetWithRawDictionary:(NSDictionary *)keyedValues
{
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    TDTweet *tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet"
                                                   inManagedObjectContext:context];
    [tweet setValuesForKeysWithRawDictionary:keyedValues];
    return tweet;
}


- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    
    NSMutableDictionary *tweetDict = [NSMutableDictionary dictionaryWithDictionary:keyedValues];
    
    tweetDict[@"created_at"] = [formatter dateFromString:keyedValues[@"created_at"]];
    
    [tweetDict removeObjectForKey:@"id"];
    [tweetDict removeObjectForKey:@"user"];
    [tweetDict removeObjectForKey:@"in_reply_to_status_id"];
    [tweetDict removeObjectForKey:@"in_reply_to_user_id"];
    [tweetDict removeObjectForKey:@"retweeted_status"];
    
    [self setValuesForKeysWithDictionary:tweetDict];
}


#pragma mark - Core Data

@dynamic contributors;
@dynamic coordinates;
@dynamic created_at;
@dynamic entities;
@dynamic favorited;
@dynamic geo;
@dynamic id_str;
@dynamic in_reply_to_screen_name;
@dynamic in_reply_to_status_id_str;
@dynamic in_reply_to_user_id_str;
@dynamic place;
@dynamic possibly_sensitive;
@dynamic retweet_count;
@dynamic retweeted;
@dynamic source;
@dynamic text;
@dynamic truncated;
@dynamic lang;
@dynamic favorite_count;
@dynamic read;
@dynamic author;

@end
