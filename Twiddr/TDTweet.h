//
//  TDTweet.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/20/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TDTweet : NSManagedObject

@property (nonatomic, strong) id contributors;
@property (nonatomic, strong) NSString * coordinates;
@property (nonatomic, strong) NSDate * created_at;
@property (nonatomic, strong) id entities;
@property (nonatomic, strong) NSNumber * favorited;
@property (nonatomic, strong) NSString * geo;
@property (nonatomic, strong) NSNumber * id;
@property (nonatomic, strong) NSString * id_str;
@property (nonatomic, strong) NSString * in_reply_to_screen_name;
@property (nonatomic, strong) NSNumber * in_reply_to_status_id;
@property (nonatomic, strong) NSString * in_reply_to_status_id_str;
@property (nonatomic, strong) NSNumber * in_reply_to_user_id;
@property (nonatomic, strong) NSString * in_reply_to_user_id_str;
@property (nonatomic, strong) NSString * place;
@property (nonatomic, strong) NSNumber * possibly_sensitive;
@property (nonatomic, strong) NSNumber * retweet_count;
@property (nonatomic, strong) NSNumber * retweeted;
@property (nonatomic, strong) NSString * source;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) NSNumber * truncated;

@end
