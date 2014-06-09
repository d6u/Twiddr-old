//
//  TDTweet.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTweet.h"
#import "TDAccount.h"
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
    static NSDateFormatter *formatter;

    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    }

    NSMutableDictionary *tweetDict = [[NSMutableDictionary alloc] init];

    static NSSet *recongnizedProperties;
    recongnizedProperties = [NSSet setWithObjects:@"author_id_str",
                                                  @"contributors",
                                                  @"created_at",
                                                  @"entities",
                                                  @"extended_entities",
                                                  @"favorite_count",
                                                  @"favorited",
                                                  @"geo",
                                                  @"id_str",
                                                  @"in_reply_to_screen_name",
                                                  @"in_reply_to_status_id_str",
                                                  @"in_reply_to_user_id_str",
                                                  @"lang",
                                                  @"place",
                                                  @"possibly_sensitive",
                                                  @"quoted_status_id_str",
                                                  @"read",
                                                  @"retweet_count",
                                                  @"retweeted_status",
                                                  @"source",
                                                  @"text",
                                                  @"truncated", nil];

    for (NSString *key in keyedValues) {
        if ([recongnizedProperties containsObject:key]) {
            tweetDict[key] = [keyedValues objectForKey:key];
        }
    }

    tweetDict[@"created_at"] = [formatter dateFromString:keyedValues[@"created_at"]];
    tweetDict[@"author_id_str"] = keyedValues[@"user"][@"id_str"];

//    [tweetDict removeObjectForKey:@"id"];
//    [tweetDict removeObjectForKey:@"user"];
//    [tweetDict removeObjectForKey:@"in_reply_to_status_id"];
//    [tweetDict removeObjectForKey:@"in_reply_to_user_id"];
//    [tweetDict removeObjectForKey:@"retweeted_status"];
//    [tweetDict removeObjectForKey:@"quoted_status_id"];

    [self setValuesForKeysWithDictionary:tweetDict];
}


#pragma mark - Core Data

@dynamic author_id_str;
@dynamic contributors;
@dynamic coordinates;
@dynamic created_at;
@dynamic entities;
@dynamic extended_entities;
@dynamic favorite_count;
@dynamic favorited;
@dynamic geo;
@dynamic id_str;
@dynamic in_reply_to_screen_name;
@dynamic in_reply_to_status_id_str;
@dynamic in_reply_to_user_id_str;
@dynamic lang;
@dynamic place;
@dynamic possibly_sensitive;
@dynamic quoted_status_id_str;
@dynamic read;
@dynamic retweet_count;
@dynamic retweeted;
@dynamic retweeted_status;
@dynamic source;
@dynamic text;
@dynamic truncated;

@dynamic author;
@dynamic timeline_account;

@end
