//
//  TDTweetCell.m
//  Twiddr
//
//  Created by Daiwei on 6/8/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTweetCell.h"
#import "TDTweet.h"

@implementation TDTweetCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

+ (CGFloat)heightForTweetText:(TDTweet *)tweet
{
    const CGFloat topMargin = 20.0f;
    const CGFloat bottomMargin = 20.0f;
    const CGFloat minHeight = 14.0f;

    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

    NSString *text;
    if (tweet.retweeted_status != nil) {
        text = tweet.retweeted_status[@"text"];
    } else {
        text = tweet.text;
    }
    CGRect boundingBox = [text boundingRectWithSize:CGSizeMake(280, CGFLOAT_MAX)
                                            options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                         attributes:@{NSFontAttributeName: font}
                                            context:nil];

    return ceil(MAX(minHeight, CGRectGetHeight(boundingBox) + topMargin + bottomMargin));
}

@end
