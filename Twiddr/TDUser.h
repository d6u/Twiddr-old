//
//  User.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/20/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <SDWebImage/SDWebImageOperation.h>


@interface TDUser : NSManagedObject

@property (nonatomic, strong) id profile_sidebar_fill_color;
@property (nonatomic, strong) id profile_sidebar_border_color;
@property (nonatomic, strong) NSNumber * profile_background_tile;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * profile_image_url;
@property (nonatomic, strong) NSDate * created_at;
@property (nonatomic, strong) NSString * location;
@property (nonatomic, strong) NSNumber * follow_request_sent;
@property (nonatomic, strong) id profile_link_color;
@property (nonatomic, strong) NSNumber * is_translator;
@property (nonatomic, strong) NSString * id_str;
@property (nonatomic, strong) id entities;
@property (nonatomic, strong) NSNumber * default_profile;
@property (nonatomic, strong) NSNumber * contributors_enabled;
@property (nonatomic, strong) NSNumber * favourites_count;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * profile_image_url_https;
@property (nonatomic, strong) NSNumber * utc_offset;
@property (nonatomic, strong) NSNumber * profile_use_background_image;
@property (nonatomic, strong) NSNumber * listed_count;
@property (nonatomic, strong) id profile_text_color;
@property (nonatomic, strong) NSString * lang;
@property (nonatomic, strong) NSNumber * followers_count;
@property (nonatomic, strong) NSNumber * protected;
@property (nonatomic, strong) id notifications;
@property (nonatomic, strong) NSString * profile_background_image_url_https;
@property (nonatomic, strong) id profile_background_color;
@property (nonatomic, strong) NSNumber * verified;
@property (nonatomic, strong) NSNumber * geo_enabled;
@property (nonatomic, strong) NSString * time_zone;
@property (nonatomic, strong) NSString * description_tw;
@property (nonatomic, strong) NSNumber * default_profile_image;
@property (nonatomic, strong) NSString * profile_background_image_url;
@property (nonatomic, strong) NSNumber * statuses_count;
@property (nonatomic, strong) NSNumber * friends_count;
@property (nonatomic, strong) NSNumber * following;
@property (nonatomic, strong) NSNumber * show_all_inline_media;
@property (nonatomic, strong) NSString * screen_name;
@property (nonatomic, strong) NSString *profile_banner_url;
@property (nonatomic, strong) NSNumber *is_translation_enabled;


@property (nonatomic, strong) UIImage *profileImage;

@property (nonatomic, strong) id<SDWebImageOperation> profileImageDownloadOperation;

- (void)loadProfileImageWithCompletionBlock:(void (^)(UIImage *image))complete;
- (BOOL)isDownloadingProfileImage;

@end
