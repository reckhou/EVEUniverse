//
//  NCFittingAPIFlagsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAPIFlagsViewController.h"
#import "NCTableViewCell.h"
#import "UIColor+Neocom.h"

@interface NCFittingAPIFlagsViewController ()

@end

@implementation NCFittingAPIFlagsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.refreshControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedValue = [sender object];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	cell.titleLabel.text = self.titles[indexPath.row];
	cell.iconView.image = self.icons[indexPath.row];

	NSNumber* value = self.values[indexPath.row];
	if (self.selectedValue && [self.selectedValue integerValue] == [value integerValue])
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
	else
		cell.accessoryView = nil;
	cell.object = value;
	return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor appearanceTableViewCellBackgroundColor];
}

#pragma mark - NCTableViewController

- (NSString*) recordID {
	return nil;
}

@end
