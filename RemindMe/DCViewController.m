//
//  DCViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCViewController.h"
#import "DCNewReminderViewController.h"
#import "DCReminderDetailViewController.h"
#import "DataModel.h"
#import "DCReminder.h"
#import "DCNotificationScheduler.h"
#import "DCReminderTableViewCell.h"
#import "NSDate+Helpers.h"
#import <SWTableViewCell/SWTableViewCell.h>

typedef NS_ENUM(NSInteger, DCReminderDue) {
    DCReminderDueOverdue,
    DCReminderDueSoon,
    DCReminderDueFuture
};

@interface DCTableViewController () <NewReminderProtocol, ReminderDetailProtocol, DataModelProtocol, UIGestureRecognizerDelegate, SWTableViewCellDelegate> {
    NSInteger _totalItems;
    NSInteger _dueSoon;
    NSInteger _overDue;
    NSDate *_now;
    NSDate *_soon;
}

@property (nonatomic, strong) DataModel *data;
@property (weak, nonatomic) IBOutlet UIButton *noItemsButton;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, assign) NSUInteger dueSoonThreshold;
@property (nonatomic, strong) DCNotificationScheduler *scheduler;
@property (nonatomic, assign) BOOL showTime;
@end

@implementation DCTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        _data = [DataModel sharedInstance];
        _data.delegate = self;
        _dueSoonThreshold = 60*60*24*3;
        _scheduler = [DCNotificationScheduler sharedInstance];
        _showTime = YES;
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
    
    // Look for notifications that we should reload the table view. Sent when a reminder notification is triggered
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reminderDueNow)
                                                 name:@"RELOAD_DATA"
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)viewDidDisappear:(BOOL)animated
{
    for ( DCReminderTableViewCell *cell in [self.tableView visibleCells] )
    {
        [cell hideUtilityButtonsAnimated:YES];
    }
    [super viewDidDisappear:animated];
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
        destination.editingReminder = NO;
    }
    else if ( [segue.identifier isEqualToString:@"reminderDetail"] ) // Not currently used
    {
        DCReminderDetailViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.reminder = [self reminderAtIndexPath:[self.tableView indexPathForSelectedRow]];
        destination.data = self.data;
        destination.dateFormatter = self.dateFormatter;
    }
    else if ( [segue.identifier isEqualToString:@"editReminder"] )
    {
        DCNewReminderViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.editingReminder = YES;
        destination.reminder = [self reminderAtIndexPath:sender];
    }
}

- (void)reminderDueNow
{
    [self updateCounts];
    [self.tableView reloadData];
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

- (void)reminderCompletedAtIndexPath:(NSIndexPath *)indexPath
{
    DCReminder *reminder = [self reminderAtIndexPath:indexPath];
    if ( reminder.repeatingInfo.repeats == DCRecurringInfoRepeatsNever )
    {
        // Task doesn't repeat, just delete it
        [self deleteRow:indexPath];
    }
    else
    {
        reminder.nextDueDate = [reminder.repeatingInfo calculateNextDateFromLastDueDate:reminder.nextDueDate andLastCompletionDate:[NSDate date]];
        [self.data addCompletionDateForReminder:reminder date:[NSDate date]];
        [self.data updateReminder:reminder];
        [self.scheduler scheduleNotificationForReminder:reminder];
    }
}

- (NSIndexPath *)indexPathForIndex:(NSUInteger)index
{
    NSInteger section = 0;
    NSInteger row = index;

    
    if ( [self.tableView numberOfRowsInSection:0] < index+1 )
    {
        section++;
        row -= [self.tableView numberOfRowsInSection:0];
    }
    if ( [self.tableView numberOfRowsInSection:0] + [self.tableView numberOfRowsInSection:1] < index+1 )
    {
        section++;
        row -= [self.tableView numberOfRowsInSection:1];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

    return indexPath;
}

- (DCReminderDue)reminderDue:(DCReminder *)reminder
{
    if ( [reminder.nextDueDate dc_isDateBefore:_now] )
        return DCReminderDueOverdue;
    else if ( [reminder.nextDueDate dc_isDateAfter:_soon] )
        return DCReminderDueFuture;
    return DCReminderDueSoon;
}

- (DCReminderDue)sectionForIndex:(NSUInteger)index
{
    if ( index < _overDue )
        return DCReminderDueOverdue;

    if ( _overDue == 0 )
    {
        if ( index < _dueSoon )
            return DCReminderDueSoon;
        if ( _dueSoon == 0 )
            return DCReminderDueFuture;
    }

    if ( _dueSoon == 0 )
        return DCReminderDueFuture;

    if ( index < _overDue + _dueSoon )
        return DCReminderDueSoon;

    return DCReminderDueFuture;
}

- (NSString *)stringForDate:(NSDate *)date
{
    if ( self.dateFormatter == nil )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMMM d"];
    }
    
    if ( self.timeFormatter == nil )
    {
        self.timeFormatter = [[NSDateFormatter alloc] init];
        [self.timeFormatter setDateFormat:@"h:mm a"];
    }
    
    NSString *relativeString = [date dc_relativeDateString];
    if ( relativeString )
    {
        if ( self.showTime )
            return [relativeString stringByAppendingFormat:@", %@", [self.timeFormatter stringFromDate:date]];
        else
            return relativeString;
    }
    
    if ( self.showTime )
        return [NSString stringWithFormat:@"%@, %@", [self.dateFormatter stringFromDate:date], [self.timeFormatter stringFromDate:date]];
    else
        return [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate:date]];
}

- (DCReminder *)reminderAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath == nil )
        return nil;

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
    
    return [self.data reminderAtIndex:index];
}

- (void)deleteRow:(NSIndexPath *)indexPath
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
    
    DCReminder *reminder = [self reminderAtIndexPath:indexPath];
    [self.scheduler clearNotificationForReminder:reminder];
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
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Remove section 1
    else if ( (indexPath.section == 1) &&
             (( _overDue > 0 && ((_dueSoon == 1) || ((_dueSoon == 0) && (_totalItems - _overDue == 1)))) ||
              ( (_overDue == 0) && (_totalItems - _dueSoon == 1))) )
    {
        if ( _overDue > 0 && _dueSoon > 0)
            _dueSoon--;
        _totalItems--;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Remove section 2
    else if ( indexPath.section == 2 && _totalItems - _overDue - _dueSoon == 1)
    {
        _totalItems--;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationTop];
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
            if ( _overDue > 0 )
            {
                if ( _dueSoon > 0 )
                    _dueSoon--;
            }
        }
        _totalItems--;
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if ( _totalItems == 0 )
    {
        self.noItemsButton.hidden = NO;
    }
}

#pragma mark - DataModelProtocol

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index
{
    [self updateCounts];
    
    // Create section for over due
    if ( _overDue == 1 && [reminder.nextDueDate dc_isDateBefore:_now] )
    {
        index = 0;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationTop];
    }
    // Create section for due soon
    else if ( _dueSoon == 1 && [reminder.nextDueDate dc_isDateAfter:_now andBefore:_soon] )
    {
        index = 0;
        if ( _overDue > 0 )
            index++;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationTop];
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



- (void)dataModelMovedObject:(DCReminder *)reminder from:(NSUInteger)from toIndex:(NSUInteger)to
{
//    NSIndexPath *originalIndexPath = [self indexPathForIndex:from];
    DCReminderDue originalSection = [self sectionForIndex:from];
    DCReminderDue newSection = [self reminderDue:reminder];
//    NSInteger section = originalIndexPath.section;
//    NSInteger row = to;
//    NSIndexPath *newIndexPath;
    

    // Remove old task from counts
    switch (originalSection)
    {
        case DCReminderDueOverdue:
            _overDue--;
            break;
        case DCReminderDueSoon:
            _dueSoon--;
            break;
        case DCReminderDueFuture:
            break;
    }
    
    // Add updated task to counts
    switch (newSection)
    {
        case DCReminderDueOverdue:
            _overDue++;
            break;
        case DCReminderDueSoon:
            _dueSoon++;
            break;
        case DCReminderDueFuture:
            break;
    }


    // Too complicated to figure out which individual rows to update for now. Just update everything!
    [self.tableView reloadData];
    
    // Update badge count
    [UIApplication sharedApplication].applicationIconBadgeNumber = _overDue;

    
//    // Figure out index path for updated task
//    switch ( newSection )
//    {
//        case DCReminderDueOverdue:
//            section = 0;
//            row = to;
//            break;
//        case DCReminderDueSoon:
//            if ( _overDue > 0 )
//            {
//                section++;
//                row -= _overDue;
//            }
//            break;
//        case DCReminderDueFuture:
//            if ( _overDue > 0 )
//            {
//                section++;
//                row -= _overDue;
//            }
//            if ( _dueSoon > 0 )
//            {
//                section++;
//                row -= _dueSoon;
//            }
//            break;
//    }
//    
//    // Finally create the new index path
//    newIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
//
//    // Start with easy move if sections are equal
//    if ( newIndexPath.section == originalIndexPath.section && newIndexPath.row != originalIndexPath.row )
//    {
//        [self.tableView moveRowAtIndexPath:originalIndexPath toIndexPath:newIndexPath];
//    }
//    // Move task to new section
//    else
//    {
//        
//        [self.tableView beginUpdates];
//        
//        // Delete old section if necessary
//        if ( (originalSection == DCReminderDueOverdue && _overDue == 0) ||
//            (originalSection == DCReminderDueSoon && _dueSoon == 0) ||
//            (originalSection == DCReminderDueFuture && (_totalItems - _overDue - _dueSoon == 0)) )
//        {
//            NSLog( @"Going to delete section %d", originalIndexPath.section );
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:originalIndexPath.section] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        // Delete single row
//        else
//        {
//            NSLog( @"Going to delete row %d-%d", originalIndexPath.section, originalIndexPath.row );
//            [self.tableView deleteRowsAtIndexPaths:@[originalIndexPath] withRowAnimation:UITableViewRowAnimationTop];
//        }
//
//        // Add new section
//        if ( (newSection == DCReminderDueOverdue && _overDue == 1) ||
//            (newSection == DCReminderDueSoon && _dueSoon == 1) ||
//            (newSection == DCReminderDueFuture && (_totalItems - _overDue - _dueSoon == 1)) )
//        {
//            NSLog( @"Going to add section %d", newIndexPath.section );
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        // Add single row
//        else
//        {
//            NSLog( @"Going to add row %d-%d", newIndexPath.section, newIndexPath.row );
//            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
//        }
//        
//        [self.tableView endUpdates];
//    }
//
//
//    [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    [cell hideUtilityButtonsAnimated:YES];

    if ( index == 0 )
    {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self deleteRow:indexPath];
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    if ( index == 0 )
    {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self reminderCompletedAtIndexPath:indexPath];
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    return YES;
}

#pragma mark - NewReminderProtocol

- (void)didAddNewReminder:(DCReminder *)newReminder
{
    newReminder.nextDueDate = [NSDate dc_dateWithoutSecondsFromDate:newReminder.nextDueDate];
    [self.data addReminder:newReminder];
    [self.scheduler scheduleNotificationForReminder:newReminder];
}

- (void)didSaveReminder:(DCReminder *)reminder
{
    reminder.nextDueDate = [NSDate dc_dateWithoutSecondsFromDate:reminder.nextDueDate];
    [self.data updateReminder:reminder];
    [self.scheduler scheduleNotificationForReminder:reminder];
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
        if ( _overDue > 0 && _dueSoon > 0 )
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
    

    if ( indexPath.section == 1 )
    {
        if ( _overDue == 0 )
            index += _dueSoon;
        else
            index += _overDue;
    }
    else if ( indexPath.section == 2 )
    {
        index += _overDue + _dueSoon;
    }
    
    DCReminder *reminder = [self.data reminderAtIndex:index];
    
    // Configure the cell...
    cell.textLabel.text = reminder.name;
    cell.detailTextLabel.text = [self stringForDate:reminder.nextDueDate];
    
    // If overdue
    if ( indexPath.section == 0 && _overDue )
        cell.detailTextLabel.textColor = [UIColor redColor];
    // If due soon
    else if ( (indexPath.section == 0 && _overDue == 0) || (indexPath.section == 1 && _overDue > 0 ) )
        cell.detailTextLabel.textColor = [UIColor blueColor];
    // If future
    else
        cell.detailTextLabel.textColor = [UIColor blackColor];
    
    // Configure swipe options
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.0f green:0.8f blue:0.0f alpha:1.0f] title:@"Complete"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:@"Delete"];
    
    cell.leftUtilityButtons = leftUtilityButtons;
    cell.rightUtilityButtons = rightUtilityButtons;
    
    cell.containingTableView = tableView;
    [cell setCellHeight:cell.frame.size.height];

    cell.delegate = self;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        if ( _overDue > 0 )
            return @"Due";
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"editReminder" sender:indexPath];
}

@end
