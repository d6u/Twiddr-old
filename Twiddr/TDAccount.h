//
//  TDAccount.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TDUser;

@interface TDAccount : NSManagedObject

@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSSet *following;
@end

@interface TDAccount (CoreDataGeneratedAccessors)

- (void)addFollowingObject:(TDUser *)value;
- (void)removeFollowingObject:(TDUser *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

@end
