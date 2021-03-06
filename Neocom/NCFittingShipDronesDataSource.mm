//
//  NCFittingShipDronesDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipDronesDataSource.h"
#import "NCFittingShipViewController.h"
#import "NCFittingShipDroneCell.h"
#import "NCTableViewCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "UIActionSheet+Block.h"
#import "NCFittingShipDronesTableHeaderView.h"
#import "UIView+Nib.h"
#import "NSString+Neocom.h"
#import "NCFittingAmountCell.h"

#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmount NSLocalizedString(@"Set Amount", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonShowInfo NSLocalizedString(@"Show Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)

@interface NCFittingShipDronesDataSourceRow : NSObject {
	eufe::DronesList _drones;
}
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, readonly) eufe::DronesList& drones;
@end

@interface NCFittingShipDronesDataSourcePickerRow : NSObject
@property (nonatomic, strong) NCFittingShipDronesDataSourceRow* associatedRow;
@end

@implementation NCFittingShipDronesDataSourceRow

@end

@implementation NCFittingShipDronesDataSourcePickerRow

@end

@interface NCFittingShipDronesDataSource()<UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NCDBInvType* activeAmountType;
@property (nonatomic, assign) NSInteger maximumAmount;
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, strong, readwrite) NCFittingShipDronesTableHeaderView* tableHeaderView;
@property (nonatomic, strong) NCFittingShipDroneCell* offscreenCell;

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath;
- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipDronesDataSource
@synthesize tableHeaderView = _tableHeaderView;

- (void) reload {
	if (self.tableView.dataSource == self) {
		[self.tableView reloadData];
	}

	__block float totalDB = 0;
	__block float usedDB = 0;
	__block float totalBandwidth = 0;
	__block float usedBandwidth = 0;
	__block int maxActiveDrones = 0;
	__block int activeDrones = 0;
	
	__block NSMutableArray* rows = nil;
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														NSMutableDictionary* dronesDic = [NSMutableDictionary new];
														eufe::DronesList drones;

														@synchronized(self.controller) {
															if (!self.controller.fit.pilot)
																return;

															eufe::Ship* ship = self.controller.fit.pilot->getShip();
															drones = ship->getDrones();
															
															totalDB = ship->getTotalDroneBay();
															usedDB = ship->getDroneBayUsed();
															
															totalBandwidth = ship->getTotalDroneBandwidth();
															usedBandwidth = ship->getDroneBandwidthUsed();
															
															maxActiveDrones = ship->getMaxActiveDrones();
															activeDrones = ship->getActiveDrones();
														}
														
														for (auto drone: drones) {
															NSInteger typeID = drone->getTypeID();
															NCFittingShipDronesDataSourceRow* row = dronesDic[@(typeID)];
															if (!row) {
																row = [NCFittingShipDronesDataSourceRow new];
																row.type = [self.controller typeWithItem:drone];
																dronesDic[@(typeID)] = row;
															}
															row.drones.push_back(drone);
														}

														rows = [[[dronesDic allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"type.typeName" ascending:YES]]] mutableCopy];
														if (self.activeAmountType) {
															NSInteger i = 1;
															for (NCFittingShipDronesDataSourceRow* row in rows) {
																if (row.type.typeID == self.activeAmountType.typeID) {
																	NCFittingShipDronesDataSourcePickerRow* pickerRow = [NCFittingShipDronesDataSourcePickerRow new];
																	pickerRow.associatedRow = row;
																	[rows insertObject:pickerRow atIndex:i];
																	break;
																}
																i++;
															}
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.rows = rows;
												
												if (self.tableView.dataSource == self) {
													[self.tableView reloadData];
												}
												
												self.tableHeaderView.droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
												self.tableHeaderView.droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
												self.tableHeaderView.droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
												self.tableHeaderView.droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
												self.tableHeaderView.dronesCountLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
												if (activeDrones > maxActiveDrones)
													self.tableHeaderView.dronesCountLabel.textColor = [UIColor redColor];
												else
													self.tableHeaderView.dronesCountLabel.textColor = [UIColor whiteColor];

											}
										}];
}


- (NCFittingShipDronesTableHeaderView*) tableHeaderView {
	if (!_tableHeaderView) {
		_tableHeaderView = [NCFittingShipDronesTableHeaderView viewWithNibName:@"NCFittingShipDronesTableHeaderView" bundle:nil];
		_tableHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
	}
	return _tableHeaderView;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= self.rows.count) {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
		return cell;
	}
	else {
		NCFittingShipDronesDataSourceRow* row = self.rows[indexPath.row];
		if ([row isKindOfClass:[NCFittingShipDronesDataSourcePickerRow class]]) {
			NCFittingAmountCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingAmountCell"];
			return cell;
		}
		else {
			NCFittingShipDroneCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipDroneCell"];
			[self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
			return cell;
		}
	}
}


#pragma mark -
#pragma mark Table view delegate

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	if ([cell isKindOfClass:[NCFittingAmountCell class]]) {
		NCFittingShipDronesDataSourcePickerRow* pickerRow = self.rows[indexPath.row];
		NCFittingAmountCell* amountCell = (NCFittingAmountCell*) cell;
		amountCell.pickerView.dataSource = self;
		amountCell.pickerView.delegate = self;
		[amountCell.pickerView reloadAllComponents];
		[amountCell.pickerView selectRow:pickerRow.associatedRow.drones.size() - 1 inComponent:0 animated:NO];
	}
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row >= self.rows.count) {
		return 41;
	}
	else {
		NCFittingShipDronesDataSourceRow* row = self.rows[indexPath.row];
		if ([row isKindOfClass:[NCFittingShipDronesDataSourcePickerRow class]]) {
			return 162;
		}
		else {
			if (!self.offscreenCell)
				self.offscreenCell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipDroneCell"];
			[self tableView:tableView configureCell:self.offscreenCell forRowAtIndexPath:indexPath];
			self.offscreenCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.offscreenCell.bounds));
			[self.offscreenCell layoutIfNeeded];
			return [self.offscreenCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5;
		}
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger i = 0;
	for (NCFittingShipDronesDataSourcePickerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingShipDronesDataSourcePickerRow class]]) {
			self.activeAmountType = nil;
			NSMutableArray* rows = [self.rows mutableCopy];
			[rows removeObjectAtIndex:i];
			self.rows = rows;
			[tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
			if (indexPath.row == i - 1) {
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
				return;
			}
			else if (indexPath.row > i)
				indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
			break;
		}
		i++;
	}
	
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= self.rows.count) {
		self.controller.typePickerViewController.title = NSLocalizedString(@"Drones", nil);
		
		[self.controller.typePickerViewController presentWithCategory:[NCDBEufeItemCategory categoryWithSlot:NCDBEufeItemSlotDrone size:0 race:nil]
													   inViewController:self.controller
															   fromRect:cell.bounds
																 inView:cell
															   animated:YES
													  completionHandler:^(NCDBInvType *type) {
														  eufe::TypeID typeID = type.typeID;
														  eufe::Ship* ship = self.controller.fit.pilot->getShip();
														  
														  const eufe::DronesList& drones = ship->getDrones();
														  eufe::Drone* sameDrone = NULL;
														  eufe::DronesList::const_iterator i, end = drones.end();
														  for (i = drones.begin(); i != end; i++) {
															  if ((*i)->getTypeID() == typeID) {
																  sameDrone = *i;
																  break;
															  }
														  }
														  eufe::Drone* drone = ship->addDrone(type.typeID);
														  
														  if (sameDrone)
															  drone->setTarget(sameDrone->getTarget());
														  else {
															  int dronesLeft = ship->getMaxActiveDrones() - 1;
															  for (;dronesLeft > 0; dronesLeft--)
																  ship->addDrone(new eufe::Drone(*drone));
														  }
														  
														  [self.controller reload];
														  [self.controller dismissAnimated];
													  }];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return self.maximumAmount;
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [NSString stringWithFormat:@"%ld", (long)(row + 1)];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)rowIndex inComponent:(NSInteger)component {
	int amount = (int) (rowIndex + 1);
	NSInteger i = 0;
	for (NCFittingShipDronesDataSourcePickerRow* row in self.rows) {
		if ([row isKindOfClass:[NCFittingShipDronesDataSourcePickerRow class]]) {
			eufe::Ship* ship = self.controller.fit.pilot->getShip();
			eufe::TypeID typeID = row.associatedRow.drones.front()->getTypeID();

			if (row.associatedRow.drones.size() > amount) {
				int n = (int) row.associatedRow.drones.size() - amount;
				for (auto drone: row.associatedRow.drones) {
					if (n <= 0)
						break;
					ship->removeDrone(drone);
					n--;
				}
			}
			else {
				int n = amount - (int) row.associatedRow.drones.size();
				eufe::Drone* drone = row.associatedRow.drones.front();
				for (int i = 0; i < n; i++) {
					eufe::Drone* newDrone = ship->addDrone(drone->getTypeID());
					newDrone->setActive(drone->isActive());
					newDrone->setTarget(drone->getTarget());
				}
			}
			row.associatedRow.drones.clear();
			for (auto drone: ship->getDrones()) {
				if (drone->getTypeID() == typeID)
					row.associatedRow.drones.push_back(drone);
			}
			[NSObject cancelPreviousPerformRequestsWithTarget:self.controller selector:@selector(reload) object:nil];
			[self.controller performSelector:@selector(reload) withObject:nil afterDelay:0.25];
		}
		i++;
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingShipDronesDataSourceRow* row = self.rows[indexPath.row];
	
	eufe::Ship* ship = self.controller.fit.pilot->getShip();
	eufe::Drone* drone = row.drones.front();
	
	void (^remove)(eufe::DronesList) = ^(eufe::DronesList drones){
		for (auto drone: drones)
			ship->removeDrone(drone);
		NSMutableArray* rows = [self.rows mutableCopy];
		[rows removeObjectAtIndex:indexPath.row];
		self.rows = rows;
		[self.controller reload];
	};
	
	void (^activate)(eufe::DronesList) = ^(eufe::DronesList drones){
		for (auto drone: drones)
			drone->setActive(true);
		[self.controller reload];
	};
	
	void (^deactivate)(eufe::DronesList) = ^(eufe::DronesList drones){
		for (auto drone: drones)
			drone->setActive(false);
		[self.controller reload];
	};
	
	void (^setTarget)(eufe::DronesList) = ^(eufe::DronesList drones){
		NSMutableArray* array = [NSMutableArray new];
		for (auto drone: drones)
			[array addObject:[NSValue valueWithPointer:drone]];
		[self.controller performSegueWithIdentifier:@"NCFittingTargetsViewController"
											 sender:@{@"sender": cell, @"object": array}];
	};
	
	void (^clearTarget)(eufe::DronesList) = ^(eufe::DronesList drones){
		for (auto drone: drones)
			drone->clearTarget();
		[self.controller reload];
	};
	
	void (^setAmount)(eufe::DronesList) = ^(eufe::DronesList drones) {
		self.activeAmountType = row.type;
		NSMutableArray* rows = [self.rows mutableCopy];
		NCFittingShipDronesDataSourcePickerRow* pickerRow = [NCFittingShipDronesDataSourcePickerRow new];
		pickerRow.associatedRow = row;
		
		float volume = drone->getAttribute(eufe::VOLUME_ATTRIBUTE_ID)->getValue();
		int droneBay = ship->getTotalDroneBay() / volume;
		int maxActive = ship->getMaxActiveDrones();
		self.maximumAmount = std::min(std::max(droneBay, maxActive), 50);

		
		[rows insertObject:pickerRow atIndex:indexPath.row + 1];
		self.rows = rows;
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	};
	
	void (^showInfo)(eufe::DronesList) = ^(eufe::DronesList drones) {
		[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
											 sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:drone]}];
	};
	
	void (^affectingSkills)(eufe::DronesList) = ^(eufe::DronesList drones){
		[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
											 sender:@{@"sender": cell, @"object": [NSValue valueWithPointer:drone]}];
	};
	
	
	NSMutableArray* buttons = [NSMutableArray new];
	NSMutableArray* actions = [NSMutableArray new];
	
	[actions addObject:remove];
	
	[buttons addObject:ActionButtonShowInfo];
	[actions addObject:showInfo];
	if (drone->isActive()) {
		[buttons addObject:ActionButtonDeactivate];
		[actions addObject:deactivate];
	}
	else {
		[buttons addObject:ActionButtonActivate];
		[actions addObject:activate];
	}
	
	[buttons addObject:ActionButtonAmount];
	[actions addObject:setAmount];
	
	[buttons addObject:ActionButtonAffectingSkills];
	[actions addObject:affectingSkills];
	
	if (self.controller.fits.count > 1) {
		[buttons addObject:ActionButtonSetTarget];
		[actions addObject:setTarget];
		if (drone->getTarget() != NULL) {
			[buttons addObject:ActionButtonClearTarget];
			[actions addObject:clearTarget];
		}
	}
	
	[[UIActionSheet actionSheetWithStyle:UIActionSheetStyleBlackTranslucent
								   title:nil
					   cancelButtonTitle:NSLocalizedString(@"Cancel", )
				  destructiveButtonTitle:ActionButtonDelete
					   otherButtonTitles:buttons
						 completionBlock:^(UIActionSheet *actionSheet, NSInteger selectedButtonIndex) {
							 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
							 if (selectedButtonIndex != actionSheet.cancelButtonIndex) {
								 void (^block)(eufe::DronesList) = actions[selectedButtonIndex];
								 block(row.drones);
							 }
						 } cancelBlock:nil] showFromRect:cell.bounds inView:cell animated:YES];
	
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.row >= self.rows.count) {
		NCTableViewCell* cell = (NCTableViewCell*) tableViewCell;
		cell.iconView.image = [UIImage imageNamed:@"drone.png"];
		cell.titleLabel.text = NSLocalizedString(@"Add Drone", nil);
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
	}
	else {
		NCFittingShipDronesDataSourceRow* row = self.rows[indexPath.row];
		if (![row isKindOfClass:[NCFittingShipDronesDataSourcePickerRow class]]) {
			@synchronized(self.controller) {
				
				eufe::Drone* drone = row.drones.front();
				
				int optimal = (int) drone->getMaxRange();
				int falloff = (int) drone->getFalloff();
				float trackingSpeed = drone->getTrackingSpeed();
				
				NCFittingShipDroneCell* cell = (NCFittingShipDroneCell*) tableViewCell;
				
				cell.typeNameLabel.text = [NSString stringWithFormat:@"%@ (x%d)", row.type.typeName, (int) row.drones.size()];
				cell.typeImageView.image = row.type.icon ? row.type.icon.image.image : [[[NCDBEveIcon defaultTypeIcon] image] image];
				
				if (optimal > 0) {
					NSString *s = [NSString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
					if (falloff > 0)
						s = [s stringByAppendingFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
					if (trackingSpeed > 0)
						s = [s stringByAppendingFormat:NSLocalizedString(@" (%@ rad/sec)", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(trackingSpeed)]];
					cell.optimalLabel.text = s;
				}
				else
					cell.optimalLabel.text = nil;
				
				if (drone->isActive())
					cell.stateImageView.image = [UIImage imageNamed:@"active.png"];
				else
					cell.stateImageView.image = [UIImage imageNamed:@"offline.png"];
				
				cell.targetImageView.image = drone->getTarget() != NULL ? [[[NCDBEveIcon eveIconWithIconFile:@"04_12"] image] image] : nil;
			}
		}
	}
}

@end
