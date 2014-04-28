//
//  TDUser.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDUser.h"
#import "TDAccount.h"
#import "TDTweet.h"
#import <SDWebImage/SDWebImageManager.h>
#import "TDSingletonCoreDataManager.h"


@interface TDUser () {
    id<SDWebImageOperation> _profileImageDownloadOperation;
}
@end


@implementation TDUser

@synthesize profileImage = _profileImage;


+ (instancetype)userWithRawDictionary:(NSDictionary *)keyedValues
{
    NSManagedObjectContext *context = [TDSingletonCoreDataManager getManagedObjectContext];
    TDUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                 inManagedObjectContext:context];
    [user setValuesForKeysWithRawDictionary:keyedValues];
    return user;
}


#pragma mark - Interfaces

- (void)setValuesForKeysWithRawDictionary:(NSDictionary *)keyedValues
{
    static NSDateFormatter *formatter;
    
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    }
    
    NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithDictionary:keyedValues];
    
    userDict[@"created_at"] = [formatter dateFromString:keyedValues[@"created_at"]];
    userDict[@"description_tw"] = keyedValues[@"description"];
    
    [userDict removeObjectForKey:@"description"];
    [userDict removeObjectForKey:@"id"];
    
    [self setValuesForKeysWithDictionary:userDict];
}


- (BOOL)isDownloadingProfileImage
{
    return _profileImageDownloadOperation != nil;
}


- (void)loadProfileImageWithCompletionBlock:(void (^)(UIImage *image))complete
{
    if (self.profile_image_url != nil) {
        _profileImageDownloadOperation = [self downloadImageFromUrlString:self.profile_image_url withCompleteBlock:complete];
    } else {
        NSLog(@"-- ERROR: profile_image_url is nil");
    }
}


- (void)cancelProfileImageDownloadOperation
{
    [_profileImageDownloadOperation cancel];
    _profileImageDownloadOperation = nil;
}


#pragma mark - Getters

- (UIImage *)profileImage
{
    return _profileImage;
}


#pragma mark - Helper

- (id <SDWebImageOperation>)downloadImageFromUrlString:(NSString *)urlString
                                     withCompleteBlock:(void (^)(UIImage *image))complete
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    return [manager downloadWithURL:[NSURL URLWithString:urlString]
                            options:0
                           progress:^(NSInteger receivedSize, NSInteger expectedSize) {}
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
            {
                if (error) {
                    NSLog(@"-- ERROR: %@", error);
                }
                if (image) {
                    _profileImage = image;
                    _profileImageDownloadOperation = nil;
                }
                if (complete) {
                    complete(image);
                }
            }];
}


#pragma mark - Core Data

@dynamic contributors_enabled;
@dynamic created_at;
@dynamic default_profile;
@dynamic default_profile_image;
@dynamic description_tw;
@dynamic entities;
@dynamic favourites_count;
@dynamic follow_request_sent;
@dynamic followers_count;
@dynamic following;
@dynamic friends_count;
@dynamic geo_enabled;
@dynamic id_str;
@dynamic is_translation_enabled;
@dynamic is_translator;
@dynamic lang;
@dynamic listed_count;
@dynamic location;
@dynamic muting;
@dynamic name;
@dynamic notifications;
@dynamic profile_background_color;
@dynamic profile_background_image_url;
@dynamic profile_background_image_url_https;
@dynamic profile_background_tile;
@dynamic profile_banner_url;
@dynamic profile_image_url;
@dynamic profile_image_url_https;
@dynamic profile_link_color;
@dynamic profile_sidebar_border_color;
@dynamic profile_sidebar_fill_color;
@dynamic profile_text_color;
@dynamic profile_use_background_image;
@dynamic protected;
@dynamic screen_name;
@dynamic statuses_count;
@dynamic time_zone;
@dynamic url;
@dynamic utc_offset;
@dynamic verified;

@dynamic account;
@dynamic statuses;

@end
