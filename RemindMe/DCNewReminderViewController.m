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

@interface DCNewReminderViewController () <UITextFieldDelegate, UITextViewDelegate, NewRepeatInfoProtocol> {
    BOOL editingDate;
    DCReminderInfoLabelCell *dateCell;
    BOOL datePicked;
    BOOL editingNote;
}

//@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIDatePicker *picker;
@property (weak, nonatomic) IBOutlet UISwitch *repeatSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
@property (weak, nonatomic) IBOutlet UILabel *dueLabel;
@property (weak, nonatomic) IBOutlet UITextField *reminderNameText;

@property (strong, nonatomic) UILabel *repeatStringLabel;
@property (strong, nonatomic) UILabel *muteStringLabel;

@property (weak, nonatomic) IBOutlet UILabel *noteSummaryLabel;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
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

    self.repeatStringLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    self.muteStringLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    
    [self applyAppearanceToFooterLabel:self.repeatStringLabel];
    [self applyAppearanceToFooterLabel:self.muteStringLabel];

    self.muteStringLabel.text = @"Muting will disable the reminder.";
    [self resizeLabel:self.muteStringLabel];
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

- (void)applyAppearanceToFooterLabel:(UILabel *)label
{
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
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
        self.muteSwitch.on = self.reminder.muted;
        self.noteSummaryLabel.text = self.reminder.notes;
        self.noteTextView.text = self.reminder.notes;
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
    editingNote = NO;
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
        [self.dateFormatter setDateFormat:@"MMM d, yyyy, h:mm a"];
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

- (IBAction)muteSwitchChanged:(UISwitch *)sender
{
    if ( sender.on )
    {
        self.reminder.muted = YES;
    }
    else
    {
        self.reminder.muted = NO;
    }
}


- (void)resizeLabel:(UILabel *)label
{
    CGSize maximumLabelSize = CGSizeMake(label.frame.size.width, 9999);
    
    CGSize size = [label.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes: @{ NSFontAttributeName: label.font } context: nil].size;
    
    CGRect frame = label.frame;
    frame.size.height = size.height;
    label.frame = frame;
}

- (void)updateRepeatLabel
{
    self.repeatStringLabel.text = [self.reminder.repeatingInfo sentenceFormat];
    
    [self resizeLabel:self.repeatStringLabel];
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
    
    self.reminder.name = newText;

    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    self.noteSummaryLabel.text = newText;
    self.reminder.notes = newText;
    
    return YES;
}

#pragma mark - UITableViewDelegate

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

    if ( indexPath.section == 1 )
    {
#ifdef DCSupportMute
        if ( !self.editingReminder )
#endif
        {
            return 0;
        }
    }

    if ( indexPath.section == 2 && indexPath.row == 1 )
    {
        if ( !editingNote )
        {
            return 0;
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
    else if (indexPath.section == 2 && indexPath.row == 0 )
    {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];

        if ( editingNote )
        {
            editingNote = NO;

            [UIView animateWithDuration:.4 animations:^{
                [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
                [tableView reloadData];
            } completion:^(BOOL finished) {
                self.noteSummaryLabel.hidden = NO;
            }];
        }
        else
        {
            editingNote = YES;

            
            [UIView animateWithDuration:.4 animations:^{
                [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationFade];
                [tableView reloadData];
            } completion:^(BOOL finished) {
                [self.noteTextView becomeFirstResponder];
                self.noteSummaryLabel.hidden = YES;
            }];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        return self.repeatStringLabel;
    }

#ifdef DCSupportMute
    if ( section == 1 )
    {
        if ( self.editingReminder )
        {
            return self.muteStringLabel;
        }
    }
#endif

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        return self.repeatStringLabel.frame.size.height;
    }

#ifdef DCSupportMute
    if ( section == 1 )
    {
        if ( self.editingReminder )
        {
            return self.muteStringLabel.frame.size.height;
        }
    }
#endif
    
    return [super tableView:tableView heightForFooterInSection:section];
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
