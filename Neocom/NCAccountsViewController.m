//
//  NCAccountsViewController.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccountsViewController.h"
#import "NCAccountsManager.h"
#import "NCStorage.h"
#import "NCAccountCharacterCell.h"
#import "NCAccountCorporationCell.h"
#import "UIImageView+URL.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "EVEDBInvType.h"

@interface NCAccountsViewControllerDataAccount : NSObject<NSCoding>
@property (nonatomic, strong) NCAccount* account;
@property (nonatomic, strong) EVEAccountStatus* accountStatus;
@property (nonatomic, strong) EVEAccountBalance* accountBalance;
@property (nonatomic, strong) NSString* currentSkill;
@end

@implementation NCAccountsViewControllerDataAccount

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NCStorage* storage = [NCStorage sharedStorage];
		
		NSURL* url = [aDecoder decodeObjectForKey:@"account"];
		if ([url isKindOfClass:[NSURL class]]) {
			[storage.managedObjectContext performBlockAndWait:^{
					self.account = (NCAccount*) [storage.managedObjectContext existingObjectWithID:[storage.persistentStoreCoordinator managedObjectIDForURIRepresentation:url] error:nil];
			}];
			if (!self.account)
				return nil;
			
			self.accountStatus = [aDecoder decodeObjectForKey:@"accountStatus"];
			if (![self.accountStatus isKindOfClass:[EVEAccountStatus class]])
				self.accountStatus = nil;
			
			self.accountBalance = [aDecoder decodeObjectForKey:@"accountBalance"];
			if (![self.accountBalance isKindOfClass:[EVEAccountBalance class]])
				self.accountBalance = nil;
			
			self.currentSkill = [aDecoder decodeObjectForKey:@"currentSkill"];
		}
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	if (self.account)
		[aCoder encodeObject:[self.account.objectID URIRepresentation] forKey:@"account"];
	if (self.accountStatus)
		[aCoder encodeObject:self.accountStatus forKey:@"accountStatus"];
	if (self.accountBalance)
		[aCoder encodeObject:self.accountBalance forKey:@"accountBalance"];
	if (self.currentSkill)
		[aCoder encodeObject:self.currentSkill forKey:@"currentSkill"];
}

- (NSString*) description {
	return [self.account description];
}

@end

@interface NCAccountsViewControllerData : NSObject<NSCoding>
@property (nonatomic, strong) NSMutableArray* accounts;
@property (nonatomic, strong) NSMutableArray* apiKeys;
@end



@implementation NCAccountsViewControllerData

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NCStorage* storage = [NCStorage sharedStorage];
        
        self.accounts = [[aDecoder decodeObjectForKey:@"accounts"] mutableCopy];
        [storage.managedObjectContext performBlockAndWait:^{
            self.apiKeys = [NSMutableArray arrayWithArray:[NCAPIKey allAPIKeys]];
        }];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    if (self.accounts)
        [aCoder encodeObject:self.accounts forKey:@"accounts"];
}

@end


@interface NCAccountsViewController ()

@end

@implementation NCAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCSelectAccount"]) {
		NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
		NCAccountsViewControllerData* data = self.data;
		NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
		[NCAccount setCurrentAccount:account.account];
	}
	else if ([segue.identifier isEqualToString:@"Logout"]) {
		[NCAccount setCurrentAccount:nil];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return [NCAccount currentAccount] != nil ? 1 : 0;
	}
	else if (section == 1) {
		NCAccountsViewControllerData* data = self.data;
		return data.accounts.count;
	}
	else
		return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
		return [tableView dequeueReusableCellWithIdentifier:@"LogoutCell" forIndexPath:indexPath];
	else if (indexPath.section == 2)
		return [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	NCAccountsViewControllerData* data = self.data;
	NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
	
	if (account.account.accountType == NCAccountTypeCharacter) {
		static NSString *CellIdentifier = @"NCAccountCharacterCell";
		NCAccountCharacterCell *cell = (NCAccountCharacterCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		cell.characterImageView.image = nil;
		cell.corporationImageView.image = nil;
		cell.allianceImageView.image = nil;
		
		[cell.characterImageView setImageWithContentsOfURL:[EVEImage characterPortraitURLWithCharacterID:account.account.characterID size:EVEImageSizeRetina64 error:nil]];
		EVECharacterInfo* characterInfo = account.account.characterInfo;
		EVECharacterSheet* characterSheet = account.account.characterSheet;
		
		if (characterInfo) {
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:characterInfo.corporationID size:EVEImageSizeRetina32 error:nil]];
			if (characterInfo.allianceID)
				[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:characterInfo.allianceID size:EVEImageSizeRetina32 error:nil]];
			
			if (characterSheet) {
				cell.skillsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@/%@ SP (%@ skills)", nil),
										 [NSString shortStringWithFloat:characterInfo.skillPoints unit:nil],
										 [NSString shortStringWithFloat:characterSheet.cloneSkillPoints unit:nil],
										 [NSNumberFormatter neocomLocalizedStringFromNumber:@(characterSheet.skills.count)]];
				cell.skillsLabel.textColor = characterInfo.skillPoints > characterSheet.cloneSkillPoints ? [UIColor redColor] : [UIColor greenColor];
			}
			else {
				cell.skillsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ SP", nil), [NSString shortStringWithFloat:characterInfo.skillPoints unit:nil]];
				cell.skillsLabel.textColor = [UIColor lightGrayColor];
			}
		}
		else
			cell.skillsLabel.text = nil;
		
		cell.characterNameLabel.text = characterInfo.characterName ? characterInfo.characterName : NSLocalizedString(@"Unknown Error", nil);
		cell.corporationNameLabel.text = characterInfo.corporation;
		cell.allianceNameLabel.text = characterInfo.alliance;
		
		cell.locationLabel.text = characterInfo.lastKnownLocation;
		cell.shipLabel.text = characterInfo.shipTypeName;
		
		cell.balanceLabel.text = [NSString shortStringWithFloat:characterSheet.balance unit:NSLocalizedString(@"ISK", nil)];
		
		if (account.account.skillQueue) {
			NSString *text;
			UIColor *color = nil;
			EVESkillQueue* skillQueue = account.account.skillQueue;
			if (skillQueue.skillQueue.count > 0) {
				NSTimeInterval timeLeft = [skillQueue timeLeft];
				if (timeLeft > 3600 * 24)
					color = [UIColor greenColor];
				else
					color = [UIColor yellowColor];
				text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%d skills in queue)", nil), [NSString stringWithTimeLeft:timeLeft], skillQueue.skillQueue.count];
			}
			else {
				text = NSLocalizedString(@"Training queue is inactive", nil);
				color = [UIColor redColor];
			}
			cell.skillQueueLabel.text = text;
			cell.skillQueueLabel.textColor = color;
			cell.currentSkillLabel.text = account.currentSkill;
		}
		else {
			cell.skillQueueLabel.text = nil;
			cell.currentSkillLabel.text = nil;
		}
		
		
		if (account.accountStatus) {
			UIColor *color;
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
			[dateFormatter setDateFormat:@"yyyy.MM.dd"];
			int days = [account.accountStatus.paidUntil timeIntervalSinceNow] / (60 * 60 * 24);
			if (days < 0)
				days = 0;
			if (days > 7)
				color = [UIColor greenColor];
			else if (days == 0)
				color = [UIColor redColor];
			else
				color = [UIColor yellowColor];
			cell.subscriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Paid until %@ (%d days remaining)", nil), [dateFormatter stringFromDate:account.accountStatus.paidUntil], days];
			cell.subscriptionLabel.textColor = color;
			//cell.subscriptionLabel.highlightedTextColor = color;
		}
		else {
			cell.subscriptionLabel.text = nil;
		}
		
		NSString* string = [NSString stringWithFormat:NSLocalizedString(@"API Key %d with Access Mask %d", nil), account.account.apiKey.keyID, account.account.apiKey.apiKeyInfo.key.accessMask];
		[cell.apiKeyButton setTitle:string forState:UIControlStateNormal];
		return cell;
	}
	else {
		static NSString *CellIdentifier = @"NCAccountCorporationCell";
		NCAccountCorporationCell *cell = (NCAccountCorporationCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		cell.corporationImageView.image = nil;
		cell.allianceImageView.image = nil;
		
		EVECorporationSheet* corporationSheet = account.account.corporationSheet;
		
		if (corporationSheet) {
			cell.corporationNameLabel.text = [NSString stringWithFormat:@"%@ [%@]", corporationSheet.corporationName, corporationSheet.ticker];
			[cell.corporationImageView setImageWithContentsOfURL:[EVEImage corporationLogoURLWithCorporationID:corporationSheet.corporationID size:EVEImageSizeRetina128 error:nil]];
			if (corporationSheet.allianceID)
				[cell.allianceImageView setImageWithContentsOfURL:[EVEImage allianceLogoURLWithAllianceID:corporationSheet.allianceID size:EVEImageSizeRetina32 error:nil]];
		}
		else
			cell.corporationNameLabel.text = NSLocalizedString(@"Unknown Error", nil);

		
		cell.allianceNameLabel.text = corporationSheet.allianceName;
		
		cell.ceoNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"CEO: %@", nil), corporationSheet.ceoName];
		cell.membersLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ / %@ members", nil),
								  [NSNumberFormatter neocomLocalizedStringFromInteger:corporationSheet.memberCount],
								  [NSNumberFormatter neocomLocalizedStringFromInteger:corporationSheet.memberLimit]];
		
		if (account.accountBalance) {
			float balance = 0.0;
			for (EVEAccountBalanceItem* item in account.accountBalance.accounts)
				balance += item.balance;
			
			cell.balanceLabel.text = [NSString shortStringWithFloat:balance unit:NSLocalizedString(@"ISK", nil)];
		}
		else
			cell.balanceLabel.text = nil;
		
		NSString* string = [NSString stringWithFormat:NSLocalizedString(@"API Key %d with Access Mask %d", nil), account.account.apiKey.keyID, account.account.apiKey.apiKeyInfo.key.accessMask];
		[cell.apiKeyButton setTitle:string forState:UIControlStateNormal];
		return cell;
	}
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 1;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCAccountsViewControllerData* data = self.data;
		NCAccountsViewControllerDataAccount* account = data.accounts[indexPath.row];
		[[NCAccountsManager defaultManager] removeAccount:account.account];
		[data.accounts removeObjectAtIndex:indexPath.row];
		
		NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
		updatedData.accounts = data.accounts;
		updatedData.apiKeys = data.apiKeys;
		[self didUpdateData:updatedData];
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NCAccountsViewControllerData* data = self.data;
	NCAccountsViewControllerDataAccount* account = data.accounts[fromIndexPath.row];
	[data.accounts removeObjectAtIndex:fromIndexPath.row];
	[data.accounts insertObject:account atIndex:toIndexPath.row];
	
	NCStorage* storage = [NCStorage sharedStorage];
	
	[storage.managedObjectContext performBlockAndWait:^{
		int32_t order = 0;
		for (NCAccountsViewControllerDataAccount* account in data.accounts)
			account.account.order = order++;
		
		[storage saveContext];
	}];

	NCAccountsViewControllerData* updatedData = [NCAccountsViewControllerData new];
	updatedData.accounts = data.accounts;
	updatedData.apiKeys = data.apiKeys;
	[self didUpdateData:updatedData];
	
	[[NCAccountsManager defaultManager] reload];
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.section != 1)
		return sourceIndexPath;
	else
		return proposedDestinationIndexPath;
}


//- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
//	return section == 0 ? UITableViewAutomaticDimension : 44;
//}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
		UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
		cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
		[cell setNeedsLayout];
		[cell layoutIfNeeded];
		return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
	}
	else
		return 44;
}

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return NSStringFromClass(self.class);
}

- (void) reloadDataWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy {
	__block NSError* error = nil;
	NCAccountsViewControllerData* data = [NCAccountsViewControllerData new];
    data.accounts = [NSMutableArray new];
	[[self taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {
											 NCAccountsManager* accountsManager = [NCAccountsManager defaultManager];
											 
											 float p = 0;
											 float dp = 1.0 / (accountsManager.accounts.count + accountsManager.apiKeys.count);
											 NSMutableDictionary* accountStatuses = [NSMutableDictionary new];
											 
											 for (NCAPIKey* apiKey in accountsManager.apiKeys) {
												 if (task.isCancelled)
													 return;

												 NSError* error = nil;
												 EVEAccountStatus* accountStatus = [EVEAccountStatus accountStatusWithKeyID:apiKey.keyID vCode:apiKey.vCode cachePolicy:cachePolicy error:&error progressHandler:nil];
												 if (accountStatus)
													 accountStatuses[@([apiKey hash])] = accountStatus;
												 task.progress = p += dp;
											 }
											 
											 for (NCAccount* account in accountsManager.accounts) {
												 if (task.isCancelled)
													 return;
												 
												 [account reloadWithCachePolicy:cachePolicy error:&error progressHandler:^(CGFloat progress, BOOL *stop) {
													 if (task.isCancelled)
														 *stop = YES;
												 }];
												 
												 if (task.isCancelled)
													 return;
												 
                                                 NCAccountsViewControllerDataAccount* dataAccount = [NCAccountsViewControllerDataAccount new];
                                                 dataAccount.account = account;
                                                 dataAccount.accountStatus = accountStatuses[@([account.apiKey hash])];
												 BOOL corporate = account.accountType == NCAccountTypeCorporate;
												 if (corporate)
													 dataAccount.accountBalance = [EVEAccountBalance accountBalanceWithKeyID:account.apiKey.keyID vCode:account.apiKey.vCode cachePolicy:cachePolicy characterID:account.characterID corporate:corporate error:nil progressHandler:nil];
                                                 [data.accounts addObject:dataAccount];
												 task.progress = p += dp;
												 
												 if (account.skillQueue.skillQueue.count > 0) {
													 EVESkillQueueItem* item = account.skillQueue.skillQueue[0];
													 EVEDBInvType* type = [EVEDBInvType invTypeWithTypeID:item.typeID error:nil];
													 dataAccount.currentSkill = [NSString stringWithFormat:NSLocalizedString(@"> %@ Level %d", nil), type.typeName, item.level];
												 }
											 }
                                             NCStorage* storage = [NCStorage sharedStorage];
                                             [storage.managedObjectContext performBlockAndWait:^{
                                                 data.apiKeys = [[NSMutableArray alloc] initWithArray:[NCAPIKey allAPIKeys]];
                                             }];
										 }
							 completionHandler:^(NCTask *task) {
								 if (!task.isCancelled) {
//									 if (error) {
//										 [self didFailLoadDataWithError:error];
//									 }
//									 else {
                                         [self didFinishLoadData:data withCacheDate:[NSDate date] expireDate:[NSDate dateWithTimeIntervalSinceNow:[self defaultCacheExpireTime]]];
//									 }
								 }
							 }];
}

- (BOOL) shouldReloadData {
	BOOL shouldReloadData = [super shouldReloadData];
	if (!shouldReloadData) {
		for (NCAccount* account in [[NCAccountsManager defaultManager] accounts]) {
			BOOL exist = NO;
			for (NCAccountsViewControllerDataAccount* accountData in [self.cacheRecord.data.data accounts]) {
				if ([accountData.account isEqual:account]) {
					exist = YES;
					break;
				}
			}
			if (!exist) {
				shouldReloadData = YES;
				break;
			}
		}
	}
	return shouldReloadData;
}

@end
