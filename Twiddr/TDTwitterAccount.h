//
//  TDTwitterAccount.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STTwitterAPI;


@interface TDTwitterAccount : NSObject

@property (strong, nonatomic) STTwitterAPI *twitterApi;
@property (strong, nonatomic) NSDictionary *accountSetting;
@property (strong, nonatomic) NSString *screenName;

+ (instancetype)accountWithTwitter:(STTwitterAPI *)twitter;

@end
