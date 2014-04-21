//
//  User.m
//  Twiddr
//
//  Created by Daiwei Lu on 4/20/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDUser.h"
#import <SDWebImage/SDWebImageManager.h>


@interface TDUser () {
    id<SDWebImageOperation> _profileImageDownloadOperation;
}

@end


@implementation TDUser

@dynamic profile_sidebar_fill_color;
@dynamic profile_sidebar_border_color;
@dynamic profile_background_tile;
@dynamic name;
@dynamic profile_image_url;
@dynamic created_at;
@dynamic location;
@dynamic follow_request_sent;
@dynamic profile_link_color;
@dynamic is_translator;
@dynamic id_str;
@dynamic entities;
@dynamic default_profile;
@dynamic contributors_enabled;
@dynamic favourites_count;
@dynamic url;
@dynamic profile_image_url_https;
@dynamic utc_offset;
@dynamic profile_use_background_image;
@dynamic listed_count;
@dynamic profile_text_color;
@dynamic lang;
@dynamic followers_count;
@dynamic protected;
@dynamic notifications;
@dynamic profile_background_image_url_https;
@dynamic profile_background_color;
@dynamic verified;
@dynamic geo_enabled;
@dynamic time_zone;
@dynamic description_tw;
@dynamic default_profile_image;
@dynamic profile_background_image_url;
@dynamic statuses_count;
@dynamic friends_count;
@dynamic following;
@dynamic show_all_inline_media;
@dynamic screen_name;
@dynamic profile_banner_url;
@dynamic is_translation_enabled;


@synthesize profileImage = _profileImage;


#pragma mark - Interfaces

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


@end
