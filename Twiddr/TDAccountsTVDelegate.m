//
//  TDAccountsTVDelegate.m
//  Twiddr
//
//  Created by Daiwei on 6/15/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAccountsTVDelegate.h"
#import "TDSingletonCoreDataManager.h"
#import "TDAccount.h"

@interface TDAccountsTVDelegate () <NSFetchedResultsControllerDelegate, TDAccountChangeDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) void(^configCell)(TDAccount *, UITableViewCell *); // reusable config cell, not implemented yet

@end

@implementation TDAccountsTVDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
//    if (error == nil) {
//        NSArray *accounts = _fetchedResultsController.fetchedObjects;
//
//        for (TDAccount *account in accounts) {
//            [account registerSyncDelegate:self];
//        }
//
//        for (TDAccount *account in accounts) {
//            [account initTwitterApi];
//            [account performGetAccountSettingsWithFinishBlock:^(NSError *error, NSDictionary *settings) {
//                if (error) {
//                    // TODO: invalidate account
//                }
//            }];
//            [account pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
//                [account assignOrphanTweetsToAuthorWithFinishBlock:nil];
//            }];
//        }
//    } else {
//        NSLog(@"--- Error: %@", error);
//    }
}

#pragma mark - API

- (void)fetchAccountsFollowingAndTimeline:(void(^)())allFinish
{
    __block NSUInteger refreshFinished = 0;
    NSArray *accounts = _fetchedResultsController.fetchedObjects;
    for (int i = 0; i < [accounts count]; i++) {
        [accounts[i] pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
            [accounts[i] assignOrphanTweetsToAuthorWithFinishBlock:
             ^(NSArray *unassginedTweets, NSArray *affectedUsers) {
                 refreshFinished |= (1 << i);
                 if (refreshFinished == (pow(2, [accounts count]) - 1)) {
                     allFinish();
                 }
             }];
        }];
    }
}

- (TDAccount *)accountAtIndexPath:(NSIndexPath *)indexPath
{
    return [_fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSUInteger)countFetchedObject
{
    return [_fetchedResultsController.fetchedObjects count];
}

#pragma mark - Helpers

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [self entryListFetchRequest];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:[TDSingletonCoreDataManager getManagedObjectContext]
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

- (NSFetchRequest *)entryListFetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"screen_name" ascending:YES]];
    return fetchRequest;
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TDAccount *account = [_fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = [NSString stringWithFormat:@"@%@", account.screen_name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[account.timeline_tweets count]];

    return cell;
}

@end
