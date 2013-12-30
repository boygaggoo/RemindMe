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
    self.dailyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
    self.dailyRepeatStepper.value = self.recurringInfo.repeatIncrement;

    // Reset repeatIncrement in case the original value was outside the allowed range
    self.recurringInfo.repeatIncrement = self.dailyRepeatStepper.value;
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
            self.dailyRepeatLabel.text = text;
            break;

        case DCRecurringInfoRepeatsMonthly:
            text = [NSString stringWithFormat:@"Repeat every %d month%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.dailyRepeatLabel.text = text;
            break;
            
        case DCRecurringInfoRepeatsYearly:
            text = [NSString stringWithFormat:@"Repeat every %d year%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement== 1 ? "" : "s" ];
            self.dailyRepeatLabel.text = text;
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
}

@end
