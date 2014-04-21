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
#import "TDAppDelegate.h"
#import "TDUser.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface TDAuthorsTableViewController ()

@end


@implementation TDAuthorsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self fetchCachedAuthors];
    
    self.authorImages = [[NSMutableDictionary alloc] init];
    self.authorTweets = [[NSMutableDictionary alloc] init];
    
    [self loadMoreAuthor:nil];
    [self loadTimeline];
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    TDUser *author = self.authors[indexPath.row];
    
    cell.textLabel.text = author.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", author.screen_name];
    if (self.authorImages[author.screen_name]) {
        cell.imageView.image = self.authorImages[author.screen_name];
    }
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showTweets"]) {
        TDTweetsTableViewController *tweetsViewController = [segue destinationViewController];
        tweetsViewController.managedObjectContext = self.managedObjectContext;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TDUser *author = self.authors[indexPath.row];
        
        tweetsViewController.author = author;
        tweetsViewController.account = self.account;
        tweetsViewController.tweets = self.authorTweets[author.screen_name];
    }
}


# pragma mark - Helpers

- (void)fetchCachedAuthors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"-- ERROR: %@", error);
    }
    
    self.authors = [NSMutableArray arrayWithArray:fetchedObject];
}



- (void)loadMoreAuthor:(NSString *)nextCursor
{
    [self.account.twitterApi getFriendsListForUserID:nil
                                        orScreenName:self.account.screenName
                                              cursor:nextCursor
                                               count:@"200"
                                          skipStatus:@(YES)
                                 includeUserEntities:@(NO)
                                        successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor)
    {
        if ([users count] != 0) {
            [self cacheAuthors:users];
            
            for (NSDictionary *user in users) {
                [self downloadImageFromUrlString:user[@"profile_image_url"] forScreenName:user[@"screen_name"]];
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


- (void)cacheAuthors:(NSArray *)authors
{
    NSMutableArray *newAuthors = [[NSMutableArray alloc] init];
    
    for (NSDictionary *author in authors)
    {
        TDUser *oldUser = [self findAuthorById:author[@"id_str"]];
        
        if (oldUser == nil) {
            TDUser *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                         inManagedObjectContext:self.managedObjectContext];
            [newUser setValuesForKeysWithDictionary:[self transformAuthorDictToUserDict:author]];
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            }
            
            [newAuthors addObject:newUser];
        } else {
            [oldUser setValuesForKeysWithDictionary:[self transformAuthorDictToUserDict:author]];
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            }
        }
    }
    
    [self.authors addObjectsFromArray:newAuthors];
    [[self tableView] reloadData];
}


- (void)downloadImageFromUrlString:(NSString *)urlString forScreenName:(NSString *)screenName
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadWithURL:[NSURL URLWithString:urlString]
                     options:0
                    progress:^(NSInteger receivedSize, NSInteger expectedSize) {}
                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
     {
         if (error) {
             NSLog(@"-- ERROR: %@", error);
         }
         if (image) {
             self.authorImages[screenName] = image;
             [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
         }
     }];
    
//    NSURLSession *session = [NSURLSession sharedSession];
//    
//    NSURLSessionDownloadTask *task =
//            [session downloadTaskWithURL:[NSURL URLWithString:urlString]
//                       completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
//    {
//        if (error) {
//            NSLog(@"-- ERROR: %@", error);
//        }
//        NSData *data = [NSData dataWithContentsOfURL:location];
//        UIImage *profileImage = [UIImage imageWithData:data];
//        self.authorImages[screenName] = profileImage;
//        
//        // Refresh table view cell images
//        if ([self.authorImages count] == [self.authors count]) {
//            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        }
//    }];
//    
//    [task resume];
}


- (NSDictionary *)transformAuthorDictToUserDict:(NSDictionary *)author
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    
    NSMutableDictionary *user = [NSMutableDictionary dictionaryWithDictionary:author];
    
    user[@"created_at"] = [formatter dateFromString:author[@"created_at"]];
    user[@"description_tw"] = author[@"description"];
    
    [user removeObjectForKey:@"description"];
    [user removeObjectForKey:@"id"];
    
    return user;
}


- (void)loadTimeline
{
    [self.account.twitterApi getStatusesHomeTimelineWithCount:@"200"
                                                      sinceID:nil
                                                        maxID:nil
                                                     trimUser:@(NO)
                                               excludeReplies:@(NO)
                                           contributorDetails:@(NO)
                                              includeEntities:@(YES)
                                                 successBlock:^(NSArray *statuses)
    {
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
}


- (TDUser *)findAuthorById:(NSString *)idStr
{
    TDUser *target;
    for (TDUser *user in self.authors) {
        if ([user.id_str isEqual:idStr]) {
            target = user;
            break;
        }
    }
    return target;
}


@end
