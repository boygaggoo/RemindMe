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

@interface DCNewReminderViewController () <UITextFieldDelegate> {
    BOOL editingDate;
    DCReminderInfoLabelCell *dateCell;
    UIDatePicker *picker;
    DCReminder *newReminder;
    BOOL datePicked;
}

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
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
    NSLog( @"   ***   %s  - %@ ***", __FUNCTION__, self.nameTextField.text );
    newReminder.name = self.nameTextField.text;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ( editingDate )
        return 3;
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == 0 )
    {
        static NSString *CellIdentifier = @"infoTextCell";
        DCReminderInfoTextCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        cell.cellLabel.text = @"Name";
        cell.valueTextField.placeholder = @"Reminder Name";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        self.nameTextField = cell.valueTextField;
        cell.valueTextField.delegate = self;
        return cell;
    }
    
    if ( indexPath.row == 1 )
    {
        static NSString *CellIdentifier = @"infoLabelCell";
        DCReminderInfoLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        cell.cellLabel.text = @"Date";
        cell.valueLabel.text = @"Select Date";
        dateCell = cell;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }
    
    if ( indexPath.row == 2 && editingDate )
    {
        static NSString *CellIdentifier = @"DatePickerCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        picker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
        picker.datePickerMode = UIDatePickerModeDate;
        picker.date = [NSDate dateWithTimeIntervalSinceNow:60*60*24];
        [picker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];

        [cell addSubview:picker];
        [self dateChanged];
        datePicked = YES;
        
        if ( ![self.nameTextField.text isEqualToString:@""] )
        {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    NSLog( @" row: %d, section: %d", indexPath.row, indexPath.section );
    return nil;
}

- (void)dateChanged
{
    if ( self.dateFormatter == nil )
    {
        NSLog( @"Creating date formatter" );
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MMM dd, yyyy"];
    }
    
    dateCell.valueLabel.text = [self.dateFormatter stringFromDate:picker.date];
    newReminder.nextDueDate = picker.date;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingDate && indexPath.row == 2 )
    {
        return 216;
    }
    else
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 1 )
    {
        return @"Reminder Information";
    }
    else
    {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog( @"   ***   %s   ***", __FUNCTION__ );
    if ( !editingDate && indexPath.row == 1 )
    {
        NSLog( @"   ***   adding row   ***" );
        [self.view endEditing:YES];
        editingDate = YES;
        [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    else if ( editingDate && indexPath.row == 1 )
    {
        editingDate = NO;
        [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
