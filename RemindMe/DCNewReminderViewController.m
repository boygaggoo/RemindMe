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

@interface DCNewReminderViewController () <UITextFieldDelegate> {
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
    editingDate = NO;
    datePicked = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveNewReminder:(id)sender
{
    NSLog( @"   ***   %s  - %@ ***", __FUNCTION__, self.reminderNameText.text );
    newReminder.name = self.reminderNameText.text;
    [self.delegate didAddNewReminder:newReminder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
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

- (IBAction)dateChanged:(UIDatePicker *)sender
{
    if ( self.dateFormatter == nil )
    {
        NSLog( @"Creating date formatter" );
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }

    self.dueLabel.text = [self.dateFormatter stringFromDate:sender.date];
    newReminder.nextDueDate = sender.date;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 0 && indexPath.row == 2 )
    {
        if ( !editingDate )
        {
            return 0;
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier isEqualToString:@"createRepeatInfo"] )
    {
        UISwitch *s = (UISwitch *)sender;
        if ( !s.on )
        {
            return NO;
        }
    }
    
    return YES;
}

@end
