//
//  DCSettingsViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 1/26/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "DCSettingsViewController.h"

@interface DCSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *dueSoonThresholdLabel;
@property (weak, nonatomic) IBOutlet UITextField *dueSoonThresholdTextField;
@property (weak, nonatomic) IBOutlet UISwitch *showBadgeIconSwitch;

@end

@implementation DCSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.title = @"Settings";
    self.dueSoonThresholdLabel.hidden = NO;
    self.dueSoonThresholdTextField.hidden = YES;
    self.dueSoonThresholdLabel.text = [NSString stringWithFormat:@"%lu", (long)[[NSUserDefaults standardUserDefaults] integerForKey:kDCDueSoonThreshold]];
    self.showBadgeIconSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kDCShowIconBadge];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doneWithNumberPad
{
    self.dueSoonThresholdLabel.text = self.dueSoonThresholdTextField.text;
    self.dueSoonThresholdLabel.hidden = NO;
    self.dueSoonThresholdTextField.hidden = YES;
    [self.dueSoonThresholdTextField resignFirstResponder];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[self.dueSoonThresholdLabel.text integerValue]] forKey:kDCDueSoonThreshold];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RELOAD_DATA"object:nil];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cancelNumberPad
{
    self.dueSoonThresholdLabel.hidden = NO;
    self.dueSoonThresholdTextField.hidden = YES;
    [self.dueSoonThresholdTextField resignFirstResponder];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 0 && indexPath.row == 0 )
    {
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
        numberToolbar.barStyle = UIBarStyleDefault;
        numberToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelNumberPad)],
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                               nil];
        [numberToolbar sizeToFit];
        self.dueSoonThresholdTextField.inputAccessoryView = numberToolbar;

        
        self.dueSoonThresholdLabel.hidden = YES;
        self.dueSoonThresholdTextField.hidden = NO;
        self.dueSoonThresholdTextField.text = @"";
        [self.dueSoonThresholdTextField becomeFirstResponder];
        
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (IBAction)showBadgeSwitchChanged:(UISwitch *)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ( sender.on )
    {
        [defaults setBool:YES forKey:kDCShowIconBadge];
    }
    else
    {
        [defaults setBool:NO forKey:kDCShowIconBadge];
    }
    
    [defaults synchronize];
}

@end
