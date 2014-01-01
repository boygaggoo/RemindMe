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
    DCReminder *newReminder;
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
        newReminder = [[DCReminder alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.picker.date = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
    self.repeatSwitch.on = (newReminder.repeatingInfo.repeats != DCRecurringInfoRepeatsNever);
    editingDate = NO;
    datePicked = NO;
    [self updateRepeatLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveNewReminder:(id)sender
{
    newReminder.name = self.reminderNameText.text;
    [self.delegate didAddNewReminder:newReminder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)dateChanged:(UIDatePicker *)sender
{
    if ( self.dateFormatter == nil )
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }

    self.dueLabel.text = [self.dateFormatter stringFromDate:sender.date];
    newReminder.nextDueDate = sender.date;
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
        newReminder.repeatingInfo.repeats = DCRecurringInfoRepeatsNever;
        [self updateRepeatLabel];
    }
}

- (void)updateRepeatLabel
{
    switch ( newReminder.repeatingInfo.repeats )
    {
        case DCRecurringInfoRepeatsNever:
            self.repeatDurationLabel.text = @"Never";
            self.repeatDurationLabel.textColor = [UIColor lightGrayColor];
            break;

        case DCRecurringInfoRepeatsDaily:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d day%s", newReminder.repeatingInfo.repeatIncrement, newReminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatDurationLabel.textColor = [UIColor blackColor];
            break;

        case DCRecurringInfoRepeatsWeekly:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d week%s", newReminder.repeatingInfo.repeatIncrement, newReminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatDurationLabel.textColor = [UIColor blackColor];
            break;

        case DCRecurringInfoRepeatsMonthly:
            self.repeatDurationLabel.text = [NSString stringWithFormat:@"Every %d month%s", newReminder.repeatingInfo.repeatIncrement, newReminder.repeatingInfo.repeatIncrement == 1 ? "" : "s" ];
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
    if ( indexPath.section == 0 && indexPath.row == 1 )
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
        if ( newReminder.repeatingInfo == nil )
            newReminder.repeatingInfo = [[DCRecurringInfo alloc] init];
        controller.recurringInfo = [newReminder.repeatingInfo mutableCopy];
        controller.delegate = self;
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
    newReminder.repeatingInfo = repeatInfo;
    [self updateRepeatLabel];
}

@end
