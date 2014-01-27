//
//  DCNewReminderViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 11/9/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCNewReminderViewController.h"
#import "DCReminderInfoTextCell.h"
#import "DCReminderInfoLabelCell.h"
#import "DCReminderInfoSwitchCell.h"
#import "DCRepeatViewController.h"
#import "DCRecurringInfo.h"

@interface DCNewReminderViewController () <UITextFieldDelegate, NewRepeatInfoProtocol> {
    BOOL editingDate;
    DCReminderInfoLabelCell *dateCell;
    BOOL datePicked;
}

//@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIDatePicker *picker;
@property (weak, nonatomic) IBOutlet UISwitch *repeatSwitch;
@property (weak, nonatomic) IBOutlet UILabel *dueLabel;
@property (weak, nonatomic) IBOutlet UITextField *reminderNameText;
@property (weak, nonatomic) IBOutlet UILabel *repeatDurationLabel;
@end

@implementation DCNewReminderViewController

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self populateFields];
    [self updateRepeatLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)populateFields
{
    if ( self.editingReminder )
    {
        if ( self.reminder == nil )
        {
            NSLog( @"Error: No reminder object specified to edit!" );
            return;
        }
        
        self.navigationItem.title = @"Edit Reminder";
        self.picker.date = self.reminder.nextDueDate;
        [self setDateLabel:self.reminder.nextDueDate];
        self.reminderNameText.text = self.reminder.name;
        datePicked = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.reminder = [[DCReminder alloc] init];
        self.navigationItem.title = @"New Reminder";
        self.picker.date = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
        datePicked = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    self.repeatSwitch.on = (self.reminder.repeatingInfo.repeats != DCRecurringInfoRepeatsNever);
    editingDate = NO;
}

- (IBAction)saveNewReminder:(id)sender
{
    self.reminder.name = self.reminderNameText.text;
    if ( self.editingReminder )
        [self.delegate didSaveReminder:self.reminder];
    else
        [self.delegate didAddNewReminder:self.reminder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setDateLabel:(NSDate *)date
{
    if ( self.dateFormatter == nil )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }
    
    self.dueLabel.text = [self.dateFormatter stringFromDate:date];
}

- (IBAction)dateChanged:(UIDatePicker *)sender
{
    [self setDateLabel:sender.date];
    self.reminder.nextDueDate = sender.date;
    datePicked = true;

    if ( ![self.reminderNameText.text isEqualToString:@""] )
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (IBAction)repeatSwitchChanged:(UISwitch *)sender
{
    if ( sender.on == NO )
    {
        self.reminder.repeatingInfo.repeats = DCRecurringInfoRepeatsNever;
        [self updateRepeatLabel];
    }
}

- (void)updateRepeatLabel
{
    switch ( self.reminder.repeatingInfo.repeats )
    {
        case DCRecurringInfoRepeatsNever:
            self.repeatDurationLabel.text = @"Never";
            self.repeatDurationLabel.textColor = [UIColor lightGrayColor];
            break;

        case DCRecurringInfoRepeatsDaily:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d day%s", self.reminder.repeatingInfo.repeatIncrement, self.reminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatDurationLabel.textColor = [UIColor blackColor];
            break;

        case DCRecurringInfoRepeatsWeekly:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d week%s", self.reminder.repeatingInfo.repeatIncrement, self.reminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatDurationLabel.textColor = [UIColor blackColor];
            break;

        case DCRecurringInfoRepeatsMonthly:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d month%s", self.reminder.repeatingInfo.repeatIncrement, self.reminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatDurationLabel.textColor = [UIColor blackColor];
            break;

        default:
            self.repeatDurationLabel.text = @"fix me";
            self.repeatDurationLabel.textColor = [UIColor lightGrayColor];
            break;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if ( datePicked && ![newText isEqualToString:@""] )
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    return YES;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 0 && indexPath.row == 2 )
    {
        if ( !editingDate )
        {
            return 0;
        }
        else
        {
            [self dateChanged:self.picker];
        }
    }

    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 0 && indexPath.row == 0 )
    {
        [self.reminderNameText becomeFirstResponder];
    }
    else if ( indexPath.section == 0 && indexPath.row == 1 )
    {
        editingDate = !editingDate;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];

        [UIView animateWithDuration:.4 animations:^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
        }];
    }
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ( [segue.identifier isEqualToString:@"createRepeatInfo"] || [segue.identifier isEqualToString:@"createRepeatInfo2"] )
    {
        DCRepeatViewController *controller = segue.destinationViewController;
        if ( self.reminder.repeatingInfo == nil )
            self.reminder.repeatingInfo = [[DCRecurringInfo alloc] init];
        controller.recurringInfo = [self.reminder.repeatingInfo mutableCopy];
        controller.delegate = self;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier isEqualToString:@"createRepeatInfo"] )
    {
        if ( self.repeatSwitch.on == NO )
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark - NewRepeatInfoProtocol

- (void)didSaveRepeatInfo:(DCRecurringInfo *)repeatInfo
{
    self.repeatSwitch.on = YES;
    self.reminder.repeatingInfo = repeatInfo;
    [self updateRepeatLabel];
}

@end
