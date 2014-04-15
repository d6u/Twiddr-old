//
//  TDAuthorsTableViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAuthorsTableViewController.h"
#import "TDTwitterAccount.h"
#import <STTwitter/STTwitter.h>
#import "TDTweetsTableViewController.h"


@interface TDAuthorsTableViewController ()

@end


@implementation TDAuthorsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.authors = [[NSMutableArray alloc] init];
    self.authorImages = [[NSMutableDictionary alloc] init];
    self.authorTweets = [[NSMutableDictionary alloc] init];
    
    // Update timeline
    [self.account.twitterApi getStatusesHomeTimelineWithCount:@"200"
                                                      sinceID:nil
                                                        maxID:nil
                                                     trimUser:@(NO)
                                               excludeReplies:@(NO)
                                           contributorDetails:@(NO)
                                              includeEntities:@(YES)
                                                 successBlock:^(NSArray *statuses) {
        for (NSDictionary *tweet in statuses) {
            NSString *screenName = tweet[@"user"][@"screen_name"];
            if (!self.authorTweets[screenName]) {
                NSMutableArray *tweets = [NSMutableArray arrayWithObject:tweet];
                self.authorTweets[screenName] = tweets;
            } else {
                [self.authorTweets[screenName] addObject:tweet];
            }
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"--- Error: %@", error);
    }];
    
    [self loadMoreAuthor:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.authors count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSDictionary *author = self.authors[indexPath.row];
    
    cell.textLabel.text = author[@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", author[@"screen_name"]];
    if (self.authorImages[author[@"screen_name"]]) {
        cell.imageView.image = self.authorImages[author[@"screen_name"]];
    }
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showTweets"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TDTweetsTableViewController *tweetsViewController = [segue destinationViewController];
        tweetsViewController.account = self.account;
        NSDictionary *author = self.authors[indexPath.row];
        tweetsViewController.author = author;
        tweetsViewController.tweets = self.authorTweets[author[@"screen_name"]];
    }
}


# pragma mark - Helpers

- (void)loadMoreAuthor:(NSString *)nextCursor
{
    [self.account.twitterApi getFriendsListForUserID:nil
                                        orScreenName:self.account.screenName
                                              cursor:nextCursor
                                               count:@"200"
                                          skipStatus:@(YES)
                                 includeUserEntities:@(NO)
                                        successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor) {
        if ([users count] != 0) {
            [self.authors addObjectsFromArray:users];
            
            NSURLSession *session = [NSURLSession sharedSession];
            
            for (NSDictionary *user in users) {
                NSString *screenName = user[@"screen_name"];
                
                NSURL *url = [NSURL URLWithString:user[@"profile_image_url"]];
                
                NSURLSessionDownloadTask *task =
                [session downloadTaskWithURL:url
                           completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    if (error) {
                       NSLog(@"-- ERROR: %@", error);
                    }
                    NSData *data = [NSData dataWithContentsOfURL:location];
                    UIImage *profileImage = [UIImage imageWithData:data];
                    self.authorImages[screenName] = profileImage;
                    
                    // Refresh table view cell images
                    if ([self.authorImages count] == [self.authors count]) {
                        [self.tableView performSelectorOnMainThread:@selector(reloadData)
                                                         withObject:nil
                                                      waitUntilDone:NO];
                    }
                }];
                
                [task resume];
            }
        }
        if ([users count] == 200) {
            [self loadMoreAuthor:nextCursor];
        }
        if ([users count] < 200) {
            [self.tableView reloadData];
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"--- Error: %@", error);
    }];
}


- (void)downloadImageFromUrl:(NSString *)urlString successBlock:(void (^)(UIImage *image))successBlock
{
    
}


@end
