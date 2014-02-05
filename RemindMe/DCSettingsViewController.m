//
//  DCSettingsViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 1/26/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "DCSettingsViewController.h"
#import <MessageUI/MessageUI.h>

#define reviewURL @"itms-apps://itunes.apple.com/app/id807510842"

@interface DCSettingsViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dueSoonThresholdLabel;
@property (weak, nonatomic) IBOutlet UITextField *dueSoonThresholdTextField;
@property (weak, nonatomic) IBOutlet UISwitch *showBadgeIconSwitch;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

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
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"RemindMe Version %@", version];
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

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 1 && indexPath.row == 0 )
    {
        return 0;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
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
    else if ( indexPath.section == 1 && indexPath.row == 1 )
    {
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
        NSString *model = [[UIDevice currentDevice] model];
        NSString *systemName = [[UIDevice currentDevice] systemName];
        NSString *ios = [[UIDevice currentDevice] systemVersion];

        NSString *body = [NSString stringWithFormat:@"\n\n\n---\nRemindMe %@ (%@)\n%@\n%@ %@\n", version, build, model, systemName, ios ];
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
        if ( mailCompose == nil )
        {
            NSLog( @"mailCompose is nil!" );
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else
        {
            mailCompose.mailComposeDelegate = self;
            [mailCompose setSubject:@"RemindMe Feedback"];
            [mailCompose setToRecipients:@[@"remindme@dancohn.net"]];
            [mailCompose setMessageBody:body isHTML:NO];
            [self presentViewController:mailCompose animated:YES completion:nil];
        }
    }
    else if ( indexPath.section == 1 && indexPath.row == 2 )
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ( error )
    {
        NSLog( @"Error sending email: %@", error );
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
