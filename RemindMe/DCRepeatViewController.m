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
@property (weak, nonatomic) IBOutlet UIStepper *repeatStepper;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *startFromControl;

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

    self.repeatStepper.minimumValue = 1;
    self.repeatControl.selectedSegmentIndex = self.recurringInfo.repeats;
    self.startFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
    self.repeatStepper.value = self.recurringInfo.repeatIncrement;

    // Reset repeatIncrement in case the original value was outside the allowed range
    self.recurringInfo.repeatIncrement = self.repeatStepper.value;
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
            self.repeatLabel.text = text;
            break;

        case DCRecurringInfoRepeatsWeekly:
            text = [NSString stringWithFormat:@"Repeat every %d week%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatLabel.text = text;
            break;

        case DCRecurringInfoRepeatsMonthly:
            text = [NSString stringWithFormat:@"Repeat every %d month%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement == 1 ? "" : "s" ];
            self.repeatLabel.text = text;
            break;
            
        case DCRecurringInfoRepeatsYearly:
            text = [NSString stringWithFormat:@"Repeat every %d year%s", self.recurringInfo.repeatIncrement, self.recurringInfo.repeatIncrement== 1 ? "" : "s" ];
            self.repeatLabel.text = text;
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
