//
//  TDUser.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TDAccount, TDTweet;


@interface TDUser : NSManagedObject

#pragma mark - Custom property

@property (nonatomic, strong) UIImage *profileImage;


#pragma mark - Helper methods

+ (instancetype)userWithRawDictionary:(NSDictionary *)keyedValues;
- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues;
- (void)loadProfileImageWithCompletionBlock:(void (^)(UIImage *image))complete;
- (BOOL)isDownloadingProfileImage;
- (void)cancelProfileImageDownloadOperation;


#pragma mark - Core Data

@property (nonatomic, retain) NSNumber * contributors_enabled;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSNumber * default_profile;
@property (nonatomic, retain) NSNumber * default_profile_image;
@property (nonatomic, retain) NSString * description_tw;
@property (nonatomic, retain) NSDictionary * entities;
@property (nonatomic, retain) NSNumber * favourites_count;
@property (nonatomic, retain) NSNumber * follow_request_sent;
@property (nonatomic, retain) NSNumber * followers_count;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSNumber * friends_count;
@property (nonatomic, retain) NSNumber * geo_enabled;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSNumber * is_translation_enabled;
@property (nonatomic, retain) NSNumber * is_translator;
@property (nonatomic, retain) NSString * lang;
@property (nonatomic, retain) NSNumber * listed_count;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * muting;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id notifications;
@property (nonatomic, retain) id profile_background_color;
@property (nonatomic, retain) NSString * profile_background_image_url;
@property (nonatomic, retain) NSString * profile_background_image_url_https;
@property (nonatomic, retain) NSNumber * profile_background_tile;
@property (nonatomic, retain) NSString * profile_banner_url;
@property (nonatomic, retain) NSString * profile_image_url;
@property (nonatomic, retain) NSString * profile_image_url_https;
@property (nonatomic, retain) id profile_link_color;
@property (nonatomic, retain) id profile_sidebar_border_color;
@property (nonatomic, retain) id profile_sidebar_fill_color;
@property (nonatomic, retain) id profile_text_color;
@property (nonatomic, retain) NSNumber * profile_use_background_image;
@property (nonatomic, retain) NSNumber * protected;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSNumber * statuses_count;
@property (nonatomic, retain) NSString * time_zone;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * utc_offset;
@property (nonatomic, retain) NSNumber * verified;

@property (nonatomic, retain) TDAccount *account;
@property (nonatomic, retain) NSSet *statuses;

@end

@interface TDUser (CoreDataGeneratedAccessors)

- (void)addStatusesObject:(TDTweet *)value;
- (void)removeStatusesObject:(TDTweet *)value;
- (void)addStatuses:(NSSet *)values;
- (void)removeStatuses:(NSSet *)values;

@end
