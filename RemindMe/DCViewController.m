//
//  DCViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCViewController.h"
#import "DCNewReminderViewController.h"
#import "DataModel.h"
#import "DCReminder.h"
#import "DCReminderTableViewCell.h"

@interface DCTableViewController () <NewReminderProtocol, DataModelProtocol> {
}

@property (nonatomic, strong) DataModel *data;
@property (weak, nonatomic) IBOutlet UIButton *noItemsButton;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation DCTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        _data = [[DataModel alloc] init];
        _data.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.title = @"Reminders";
    
    // Needs to be called after the data delegate has been set
    [self.data loadData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ( [self.data numItems] == 0 )
    {
        self.noItemsButton.hidden = NO;
    }
    else
    {
        self.noItemsButton.hidden = YES;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"newReminder"] )
    {
        DCNewReminderViewController *destination = segue.destinationViewController;
        destination.delegate = self;
    }
}

- (IBAction)createReminder:(id)sender
{
    [self performSegueWithIdentifier:@"newReminder" sender:self];
}

#pragma mark - DataModelProtocol

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index
{
    // Create section for due soon
    if ( reminder.dueSoon && [self.data numDueSoon] == 1 )
    {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Create section for future
    else if ( !reminder.dueSoon && [self.data numItems] - [self.data numDueSoon] == 1 )
    {
        if ( [self.data numDueSoon] == 0 )
            index = 0;
        else
            index = 1;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Insert a single row
    else
    {
        NSInteger section = 0;
        if ( !reminder.dueSoon && [self.data numDueSoon] > 0 )
        {
            section = 1;
            index -= [self.data numDueSoon];
        }
        [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:section] ] withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark - NewReminderProtocol

- (void)didAddNewReminder:(DCReminder *)newReminder
{
    [self.data addReminder:newReminder];
}

- (BOOL)dataModelIsReminderDueSoon:(DCReminder *)reminder
{
    if ( [reminder.nextDueDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*3]] < 0 )
    {
        return YES;
    }
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger total = [self.data numItems];
    NSInteger dueSoon = [self.data numDueSoon];
    NSInteger sections = 0;
    
    if ( dueSoon > 0 )
        sections++;
    if ( total - dueSoon > 0 )
        sections++;
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger total = [self.data numItems];
    NSInteger dueSoon = [self.data numDueSoon];

    if ( section == 0 )
    {
        if ( dueSoon > 0 )
        {
            return dueSoon;
        }
        return total;
    }
    else if ( section == 1 )
    {
        return total - dueSoon;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog( @"   ***   %s  %d:%d ***", __FUNCTION__, indexPath.section, indexPath.row );
    static NSString *CellIdentifier = @"ReminderItem";
    DCReminderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSInteger index = indexPath.row;
    
    if ( self.dateFormatter == nil )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }
    
    if ( indexPath.section == 1 )
        index += [self.data numDueSoon];
    
    DCReminder *reminder = [self.data reminderAtIndex:index];
    
    // Configure the cell...
    cell.textLabel.text = reminder.name;
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:reminder.nextDueDate];
    
    if ( reminder.dueSoon )
        cell.detailTextLabel.textColor = [UIColor redColor];
    else
        cell.detailTextLabel.textColor = [UIColor blackColor];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        if ( [self.data numDueSoon] > 0 )
            return @"Due soon";
    }
    return @"Future";
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete)
//    {
//        NSInteger oldNumDueSoon = [self.data numDueSoon];
//        NSInteger index = indexPath.row;
//        
//        if ( indexPath.section == 1 )
//            index += [self.data numDueSoon];
//        [self.data removeReminderAtIndex:index];
//        
//        // Remove section 0 if no more due soon
//        if ( oldNumDueSoon > 0 && [self.data numDueSoon] == 0  )
//        {
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        // Remove section 0 if no more reminders at all
//        else if ( [self.data numItems] == 0 )
//        {
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        // Remove section 1 if no more future dues
//        else if ( indexPath.section == 1 && [self.data numItems] - [self.data numDueSoon] == 0 )
//        {
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        else
//        {
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        }
//    }
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}


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

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

@end
