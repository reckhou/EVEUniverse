//
//  NCLoadout.m
//  Neocom
//
//  Created by Shimanski Artem on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLoadout.h"
#import "NCLoadoutData.h"
#import "NCStorage.h"
#import "NCDatabase.h"

#define NCCategoryIDShip 6

@implementation NCStorage(NCLoadout)

- (NSArray*) loadouts {
	__block NSArray *fetchedObjects = nil;
	[self.managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSError *error = nil;
		fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	}];
	return fetchedObjects;
}

- (NSArray*) shipLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryShip]];
}

- (NSArray*) posLoadouts {
	return [[self loadouts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category == %d", NCLoadoutCategoryPOS]];
}


@end

@implementation NCLoadout
@synthesize type = _type;

@dynamic name;
@dynamic typeID;
@dynamic url;
@dynamic data;

- (NCDBInvType*) type {
	if (!_type) {
		_type = [NCDBInvType invTypeWithTypeID:self.typeID];
	}
	return _type;
}

- (void) setTypeID:(int32_t)typeID {
	[self willChangeValueForKey:@"typeID"];
	[self setPrimitiveValue:@(typeID) forKey:@"typeID"];
	_type = nil;
	[self didChangeValueForKey:@"typeID"];
}

- (NCLoadoutCategory) category {
	return self.type.group.category.categoryID == NCCategoryIDShip ? NCLoadoutCategoryShip : NCLoadoutCategoryPOS;
}

@end
