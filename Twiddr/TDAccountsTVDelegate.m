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

@interface TDAccountsTVDelegate () <NSFetchedResultsControllerDelegate, TDAccountChangeDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) void(^cellConfigBlock)(TDAccount *, UITableViewCell *); // reusable config cell, not implemented yet
@property (nonatomic, strong) NSIndexPath *deletingIndexPath;

@end

@implementation TDAccountsTVDelegate

- (instancetype)initWithTableView:(UITableView *)tableView cellConfigBlock:(void(^)(TDAccount *, UITableViewCell*))cellConfigBlock
{
    self = [super init];
    if (self) {
        tableView.dataSource = self;
        tableView.delegate = self;
        _tableView = tableView;
        _cellConfigBlock = cellConfigBlock;
        [self setup];
    }
    return self;
}

- (void)setup
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error == nil) {
        NSArray *accounts = _fetchedResultsController.fetchedObjects;

        for (TDAccount *account in accounts) {
            [account registerSyncDelegate:self];
        }

        for (TDAccount *account in accounts) {
            [account initTwitterApi];
            [account performGetAccountSettingsWithFinishBlock:^(NSError *error, NSDictionary *settings) {
                if (error) {
                    // TODO: invalidate account
                }
            }];
            [account pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
                [account assignOrphanTweetsToAuthorWithFinishBlock:nil];
            }];
        }
    } else {
        NSLog(@"--- Error: %@", error);
    }
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

#pragma mark - Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = _fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TDAccount *account = [_fetchedResultsController objectAtIndexPath:indexPath];
    _cellConfigBlock(account, cell);
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TDAccount *account = [self.fetchedResultsController objectAtIndexPath:indexPath];
        _deletingIndexPath = indexPath;
        NSString *message = [NSString stringWithFormat:@"Do you want to remove account @%@", account.screen_name];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Remove?"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Remove", nil];
        [alert show];
    }
}

#pragma mark - Table View Delegate

- (NSString *)tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        TDAccount *account = [self.fetchedResultsController objectAtIndexPath:_deletingIndexPath];
        [[TDSingletonCoreDataManager getManagedObjectContext] deleteObject:account];
        [TDSingletonCoreDataManager saveContext];
    }
    _tableView.editing = NO;
    _deletingIndexPath = nil;
}

@end
