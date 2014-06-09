//
//  TDTweetCell.h
//  Twiddr
//
//  Created by Daiwei on 6/8/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDTweet;

@interface TDTweetCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *tweetText;

+ (CGFloat)heightForTweetText:(TDTweet *)tweet;

@end
