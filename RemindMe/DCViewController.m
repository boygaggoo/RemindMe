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
#import "NSDate+Helpers.h"

@interface DCTableViewController () <NewReminderProtocol, DataModelProtocol> {
    NSInteger _totalItems;
    NSInteger _dueSoon;
    NSInteger _overDue;
    NSDate *_now;
    NSDate *_soon;
}

@property (nonatomic, strong) DataModel *data;
@property (weak, nonatomic) IBOutlet UIButton *noItemsButton;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) NSUInteger dueSoonThreshold;
@end

@implementation DCTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        _data = [[DataModel alloc] init];
        _data.delegate = self;
        _dueSoonThreshold = 60*60*24*3;
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
    [self updateCounts];

    if ( _totalItems == 0 )
    {
        self.noItemsButton.hidden = NO;
    }
    else
    {
        self.noItemsButton.hidden = YES;
    }
    
    [super viewWillAppear:animated];
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

- (void)updateCounts
{
    // Get information from the datastore about the number of tasks due soon and over due
    _now = [NSDate date];
    _soon = [NSDate dateWithTimeIntervalSinceNow:self.dueSoonThreshold];
    
    _totalItems = [self.data numItems];
    _dueSoon = [self.data numDueAfter:_now andBefore:_soon];
    _overDue = [self.data numDueBefore:_now];
}

- (IBAction)createReminder:(id)sender
{
    [self performSegueWithIdentifier:@"newReminder" sender:self];
}

#pragma mark - DataModelProtocol

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index
{
    [self updateCounts];
    
    // Create section for over due
    if ( _overDue == 1 && [reminder.nextDueDate dc_isDateBefore:_now] )
    {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Create section for due soon
    else if ( _dueSoon == 1 && [reminder.nextDueDate dc_isDateAfter:_now andBefore:_soon] )
    {
        index = 0;
        if ( _overDue > 0 )
            index++;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Create section for future
    else if ( _totalItems - _dueSoon - _overDue == 1 && [reminder.nextDueDate dc_isDateAfter:_soon] )
    {
        index = 0;
        if ( _overDue > 0 )
            index++;
        if ( _dueSoon > 0 )
            index++;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Insert a single row
    else
    {
        NSInteger section = 0;
        // Add to overdue section
        if ( [reminder.nextDueDate dc_isDateBefore:_now] )
        {
            // index and section are correct
        }
        // Add to due soon section
        else if ( [reminder.nextDueDate dc_isDateAfter:_now andBefore:_soon] )
        {
            if ( _overDue > 0 )
            {
                section++;
                index -= _overDue;
            }
        }
        // Add to future section
        else
        {
            if ( _overDue > 0 )
            {
                section++;
                index -= _overDue;
            }
            if ( _dueSoon > 0 )
            {
                section++;
                index -= _dueSoon;
            }
        }
        [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:section] ] withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark - NewReminderProtocol

- (void)didAddNewReminder:(DCReminder *)newReminder
{
    [self.data addReminder:newReminder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 0;
    
    if ( _overDue > 0 )
        sections++;
    if ( _dueSoon > 0 )
        sections++;
    if ( _totalItems - _dueSoon - _overDue > 0 )
        sections++;
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        if ( _overDue > 0 )
        {
            return _overDue;
        }
        if ( _dueSoon > 0 )
        {
            return _dueSoon;
        }
        return _totalItems;
    }
    else if ( section == 1 )
    {
        if ( _dueSoon > 0 )
        {
            return _dueSoon;
        }
        return _totalItems - _dueSoon - _overDue;
    }
    else if ( section == 2 )
    {
        return _totalItems - _dueSoon - _overDue;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ReminderItem";
    DCReminderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSInteger index = indexPath.row;
    
    if ( self.dateFormatter == nil )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }
    
    if ( indexPath.section == 1 )
    {
        index += _overDue;
    }
    else if ( indexPath.section == 2 )
    {
        index += _overDue + _dueSoon;
    }
    
    DCReminder *reminder = [self.data reminderAtIndex:index];
    
    // Configure the cell...
    cell.textLabel.text = reminder.name;
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:reminder.nextDueDate];
    
    // If overdue
    if ( indexPath.section == 0 && _overDue )
        cell.detailTextLabel.textColor = [UIColor redColor];
    // If due soon
    else if ( (indexPath.section == 0 && _overDue == 0) || (indexPath.section == 1 && _overDue > 0 ) )
        cell.detailTextLabel.textColor = [UIColor blueColor];
    // If future
    else
        cell.detailTextLabel.textColor = [UIColor blackColor];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        if ( _overDue > 0 )
            return @"Overdue";
        if ( _dueSoon > 0 )
            return @"Due soon";
    }
    if ( section == 1 )
    {
        if ( _overDue == 0 )
            return @"Future";
        if ( _dueSoon > 0 )
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
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSInteger index = indexPath.row;
        
        if ( indexPath.section == 1 )
        {
            if ( _overDue == 0 )
                index += _dueSoon;
            else
                index += _overDue;
        }

        if ( indexPath.section == 2 )
            index += _overDue + _dueSoon;
        
        [self.data removeReminderAtIndex:index];
        
        // Remove section 0
        if ( indexPath.section == 0 &&
            ((_overDue == 1 || (_overDue == 0 && _dueSoon == 1)) || (_totalItems == 1)) )
        {
            if ( _overDue > 0 )
                _overDue--;
            else if ( _dueSoon > 0 )
                _dueSoon--;
            _totalItems--;
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
        }
        // Remove section 1
        else if ( (indexPath.section == 1) &&
                 (( _overDue > 0 && ((_dueSoon == 1) || ((_dueSoon == 0) && (_totalItems - _overDue == 1)))) ||
                 ( (_overDue == 0) && (_totalItems - _dueSoon == 1))) )
        {
            if ( _overDue > 0 && _dueSoon > 0)
                _dueSoon--;
            _totalItems--;
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
        }
        // Remove section 2
        else if ( indexPath.section == 2 && _totalItems - _overDue - _dueSoon == 1)
        {
            _totalItems--;
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationTop];
        }
        else
        {
            if ( indexPath.section == 0 )
            {
                if ( _overDue > 0 )
                    _overDue--;
                else if ( _dueSoon > 0 )
                    _dueSoon--;
            }
            else if ( indexPath.section == 1 )
            {
                if ( _overDue == 0 )
                {
                    if ( _dueSoon > 0 )
                        _dueSoon--;
                }
            }
            _totalItems--;
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
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
