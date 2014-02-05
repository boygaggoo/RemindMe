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
    
#define _DCDueFuture _totalItems - _overDue - _dueSoon
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
    
    [self setDefaults];
    
    // Help hide padding above top of grouped sections when trying to hide the section
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
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

- (void)setDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ( [defaults objectForKey:kDCDueSoonThreshold] == nil )
    {
        [defaults setObject:[NSNumber numberWithInt:3] forKey:kDCDueSoonThreshold];
    }
    
    if ( [defaults objectForKey:kDCShowIconBadge] == nil )
    {
        [defaults setBool:YES forKey:kDCShowIconBadge];
    }
    
    [defaults synchronize];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"newReminder"] )
    {
        DCNewReminderViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.editingReminder = NO;
        // Set up the reminder object in case we created one from a URL scheme
        if ( self.reminderFromURL != nil )
        {
            destination.reminder = self.reminderFromURL;
            self.reminderFromURL = nil;
        }
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else if ( [segue.identifier isEqualToString:@"reminderDetail"] ) // Not currently used
    {
        DCReminderDetailViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.reminder = [self reminderAtIndexPath:[self.tableView indexPathForSelectedRow]];
        destination.data = self.data;
        destination.dateFormatter = self.dateFormatter;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else if ( [segue.identifier isEqualToString:@"editReminder"] )
    {
        DCNewReminderViewController *destination = segue.destinationViewController;
        destination.delegate = self;
        destination.editingReminder = YES;
        destination.reminder = [self reminderAtIndexPath:sender];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.navigationItem.title style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)reminderDueNow
{
    [self updateCounts];
    [self.tableView reloadData];
}

- (void)updateCounts
{
    self.dueSoonThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:kDCDueSoonThreshold];
    self.dueSoonThreshold *= (60 * 60 * 24);

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
    
    if ( index >= _overDue )
    {
        section++;
        row -= _overDue;
    }
    
    if ( index >= _overDue + _dueSoon )
    {
        section++;
        row -= _dueSoon;
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
        index += _overDue;
    }

    if ( indexPath.section == 2 )
    {
        index += _overDue + _dueSoon;
    }
    
    return [self.data reminderAtIndex:index];
}

- (void)deleteRow:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;

    if ( indexPath.section == 0 )
    {
        _overDue--;
    }
    else if ( indexPath.section == 1 )
    {
        index += _overDue;
        _dueSoon--;
    }
    else if ( indexPath.section == 2 )
    {
        index += _overDue + _dueSoon;
    }
    
    _totalItems--;
    
    // Remove reminder from data model and notification list
    DCReminder *reminder = [self reminderAtIndexPath:indexPath];
    [self.scheduler clearNotificationForReminder:reminder];
    [self.data removeReminderAtIndex:index];
    
    // Remove row from table view
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    
    // Remove section header if no more tasks in section
    if ( [self tableView:self.tableView numberOfRowsInSection:indexPath.section] == 0 )
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
    }
  
    // Enable the button to add a new task if none exist now
    if ( _totalItems == 0 )
    {
        self.noItemsButton.hidden = NO;
    }
}

#pragma mark - DataModelProtocol

- (void)dataModelInsertedObject:(DCReminder *)reminder atIndex:(NSUInteger)index
{
    [self updateCounts];
    
    NSIndexPath *newIndexPath = [self indexPathForIndex:index];
    [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationLeft];
}



- (void)dataModelMovedObject:(DCReminder *)reminder from:(NSUInteger)from toIndex:(NSUInteger)to
{
    NSIndexPath *originalIndexPath = [self indexPathForIndex:from];


    // Remove old task from counts
    if ( originalIndexPath.section == 0 )
        _overDue--;
    else if ( originalIndexPath.section == 1 )
        _dueSoon--;

    DCReminderDue nowDue = [self reminderDue:reminder];
    
    switch ( nowDue )
    {
        case DCReminderDueOverdue:
            _overDue++;
            break;
        case DCReminderDueSoon:
            _dueSoon++;
        default:
            break;
    }
    
    NSIndexPath *newIndexPath = [self indexPathForIndex:to];


    // Delete row of old task, insert row for new position
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[ originalIndexPath ] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView endUpdates];
    
    // Remove section header if no more tasks in section
    if ( [self tableView:self.tableView numberOfRowsInSection:originalIndexPath.section] == 0 )
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:originalIndexPath.section] withRowAnimation:UITableViewRowAnimationRight];
    }
    
    // Update badge count
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kDCShowIconBadge] )
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = _overDue;
    }
    else
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        return _overDue;
    }
    else if ( section == 1 )
    {
        return _dueSoon;
    }
    else if ( section == 2 )
    {
        return _DCDueFuture;
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
    if ( indexPath.section == 0 )
        cell.detailTextLabel.textColor = [UIColor redColor];
    // If due soon
    else if ( indexPath.section == 1 )
        cell.detailTextLabel.textColor = [UIColor blueColor];
    // If future
    else
        cell.detailTextLabel.textColor = [UIColor blackColor];
    
    // Configure swipe options
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.1f green:0.7f blue:0.2f alpha:1.0f] title:@"Complete"];
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
        return @"Due";
    }
    if ( section == 1 )
    {
        return @"Due soon";
    }
    return @"Future";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"editReminder" sender:indexPath];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ( [self tableView:tableView numberOfRowsInSection:section] == 0 )
    {
        return 0;
    }

    return 33;
}

- (UIView *)sectionFiller
{
    static UILabel *emptyLabel = nil;
    if (!emptyLabel) {
        emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        emptyLabel.backgroundColor = [UIColor blueColor];
    }
    return emptyLabel;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ( section == 0 && _overDue == 0 )
        return [self sectionFiller];
    if ( section == 1 && _dueSoon == 0 )
        return [self sectionFiller];
    if ( section == 2 && _DCDueFuture == 0 )
        return [self sectionFiller];

    return nil;
}

@end
