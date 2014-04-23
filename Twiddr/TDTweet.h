//
//  TDTweet.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TDUser;

@interface TDTweet : NSManagedObject

@property (nonatomic, retain) id contributors;
@property (nonatomic, retain) NSString * coordinates;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) id entities;
@property (nonatomic, retain) NSNumber * favorited;
@property (nonatomic, retain) NSString * geo;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * in_reply_to_screen_name;
@property (nonatomic, retain) NSString * in_reply_to_status_id_str;
@property (nonatomic, retain) NSString * in_reply_to_user_id_str;
@property (nonatomic, retain) NSString * place;
@property (nonatomic, retain) NSNumber * possibly_sensitive;
@property (nonatomic, retain) NSNumber * retweet_count;
@property (nonatomic, retain) NSNumber * retweeted;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * truncated;
@property (nonatomic, retain) TDUser *author;

@end
