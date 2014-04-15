//
//  TDTwitterAccount.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTwitterAccount.h"
#import <STTwitter/STTwitter.h>


@implementation TDTwitterAccount


+ (instancetype)accountWithTwitter:(STTwitterAPI *)twitter
{
    TDTwitterAccount *account = [[TDTwitterAccount alloc] init];
    account.twitterApi = twitter;
    return account;
}


@end
