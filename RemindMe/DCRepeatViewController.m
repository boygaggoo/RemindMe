//
//  DCRepeatViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 12/17/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCRepeatViewController.h"

@interface DCRepeatViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatControl;
@property (weak, nonatomic) UIView *currentMainView;

// Daily controls
@property (weak, nonatomic) IBOutlet UIView *dailyMainView;
@property (weak, nonatomic) IBOutlet UIStepper *dailyRepeatStepper;
@property (weak, nonatomic) IBOutlet UILabel *dailyRepeatLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *dailyStartFromControl;

// Weekly controls
@property (weak, nonatomic) IBOutlet UIView *weeklyMainView;
@property (weak, nonatomic) IBOutlet UIStepper *weeklyRepeatStepper;
@property (weak, nonatomic) IBOutlet UILabel *weeklyRepeatLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *weeklyStartFromControl;

// Monthly controls
@property (weak, nonatomic) IBOutlet UIView *monthlyMainView;
@property (weak, nonatomic) IBOutlet UIStepper *monthlyRepeatStepper;
@property (weak, nonatomic) IBOutlet UILabel *monthlyRepeatLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *monthlyStartFromControl;


@end

@implementation DCRepeatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.repeatControl.selectedSegmentIndex = self.recurringInfo.repeats;

    switch (self.recurringInfo.repeats)
    {
        case DCRecurringInfoRepeatsDaily:

            // Put correct view into place
            self.dailyMainView.frame = CGRectMake(0, 124, 320, 444);
            self.weeklyMainView.frame = CGRectMake(320, 124, 320, 444);
            self.monthlyMainView.frame = CGRectMake(320, 124, 320, 444);

            self.currentMainView = self.dailyMainView;

            // Set values
            self.dailyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.dailyRepeatStepper.value = self.recurringInfo.repeatIncrement;

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.dailyRepeatStepper.value;

            break;

        case DCRecurringInfoRepeatsWeekly:

            // Put correct view into place
            self.weeklyMainView.frame = CGRectMake(0, 124, 320, 444);
            self.dailyMainView.frame = CGRectMake(320, 124, 320, 444);
            self.monthlyMainView.frame = CGRectMake(320, 124, 320, 444);

            self.currentMainView = self.weeklyMainView;

            // Set values
            self.weeklyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.weeklyRepeatStepper.value = self.recurringInfo.repeatIncrement;

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.weeklyRepeatStepper.value;

            break;

        case DCRecurringInfoRepeatsMonthly:

            // Put correct view into place
            self.monthlyMainView.frame = CGRectMake(0, 124, 320, 444);
            self.dailyMainView.frame = CGRectMake(320, 124, 320, 444);
            self.weeklyMainView.frame = CGRectMake(320, 124, 320, 444);

            self.currentMainView = self.monthlyMainView;

            // Set values
            self.monthlyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.monthlyRepeatStepper.value = self.recurringInfo.repeatIncrement;

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.monthlyRepeatStepper.value;

            break;

        case DCRecurringInfoRepeatsYearly:
            break;

        default:
            break;
    }


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateRepeatLabel
{
    NSString *text;
    switch (self.recurringInfo.repeats)
    {
        case DCRecurringInfoRepeatsDaily:
            text = [NSString stringWithFormat:@"Repeat every %d day%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.dailyRepeatLabel.text = text;
            break;

        case DCRecurringInfoRepeatsWeekly:
            text = [NSString stringWithFormat:@"Repeat every %d week%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.weeklyRepeatLabel.text = text;
            break;

        case DCRecurringInfoRepeatsMonthly:
            text = [NSString stringWithFormat:@"Repeat every %d month%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.monthlyRepeatLabel.text = text;
            break;
            
        case DCRecurringInfoRepeatsYearly:
            break;

        default:
            break;
    }
}

- (IBAction)stepperChanged:(UIStepper *)sender
{
    self.recurringInfo.repeatIncrement = (int)floor(sender.value);
    [self updateRepeatLabel];
}

- (IBAction)repeatControlChanged:(UISegmentedControl *)sender
{
    self.recurringInfo.repeats = sender.selectedSegmentIndex;
    [self updateRepeatLabel];

    UIView *newMainView = nil;
    switch ( self.recurringInfo.repeats )
    {
        case DCRecurringInfoRepeatsDaily:
            newMainView = self.dailyMainView;
            break;

        case DCRecurringInfoRepeatsWeekly:
            newMainView = self.weeklyMainView;
            break;

        case DCRecurringInfoRepeatsMonthly:
            newMainView = self.monthlyMainView;
            break;

        case DCRecurringInfoRepeatsYearly:
            break;

        default:
            break;
    }

    int multiplier = 1;

    if ( newMainView.tag < self.currentMainView.tag )
    {
        multiplier = -1;
    }

    newMainView.frame = CGRectMake(320 * multiplier, 124, 320, 444);

    [UIView animateWithDuration:0.2 animations:^{
        newMainView.frame = CGRectMake(0, 124, 320, 444);
        self.currentMainView.frame = CGRectMake(320 * multiplier * -1, 124, 320, 444);
    } completion:^(BOOL finished) {
        self.currentMainView = newMainView;
    }];

}

@end
