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
@property (weak, nonatomic) IBOutlet UILabel *repeatStringLabel;
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

    self.repeatStringLabel.backgroundColor = [UIColor clearColor];
    self.repeatStringLabel.textColor = [UIColor darkGrayColor];
    self.repeatStringLabel.textAlignment = NSTextAlignmentCenter;
    self.repeatStringLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    self.repeatStringLabel.numberOfLines = 0;
    self.repeatStringLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self populateFields];
    [self updateRepeatLabel];
    [super viewWillAppear:animated];
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
        NSInteger enableCount = 0;
        // Reminder might exist already from using URL scheme
        if ( self.reminder == nil )
        {
            self.reminder = [[DCReminder alloc] init];
            self.picker.date = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
            datePicked = NO;
        }
        else
        {
            if ( self.reminder.name )
            {
                enableCount++;
                self.reminderNameText.text = self.reminder.name;
            }
            
            if ( self.reminder.nextDueDate )
            {
                enableCount++;
                self.picker.date = self.reminder.nextDueDate;
                [self setDateLabel:self.reminder.nextDueDate];
                datePicked = YES;
            }
            else
            {
                self.picker.date = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
                datePicked = NO;
            }
        }
        
        self.navigationItem.title = @"New Reminder";

        if ( enableCount == 2 )
        {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        else
        {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
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
    self.repeatStringLabel.text = [self.reminder.repeatingInfo sentenceFormat];
    
    CGSize maximumLabelSize = CGSizeMake(self.repeatStringLabel.frame.size.width,9999);
    
    CGSize size = [self.repeatStringLabel.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes: @{ NSFontAttributeName: self.repeatStringLabel.font } context: nil].size;
    
    CGRect frame = self.repeatStringLabel.frame;
    frame.size.height = size.height;
    frame.origin.y = 0;
    self.repeatStringLabel.frame = frame;
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

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    return self.repeatStringLabel;
//}

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
