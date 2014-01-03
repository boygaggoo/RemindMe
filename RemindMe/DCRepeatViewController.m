//
//  DCRepeatViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 12/17/13.
//  Copyright (c) 2013 Dan Cohn. All rights reserved.
//

#import "DCRepeatViewController.h"
#import "MultiSelectSegmentedControl.h"

@interface DCRepeatViewController () <MultiSelectSegmentedControlDelegate>

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
@property (weak, nonatomic) IBOutlet UILabel *weeklyStartFromLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *weeklyStartFromControl;
@property (weak, nonatomic) IBOutlet MultiSelectSegmentedControl *weeklyDayPicker;

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
    self.weeklyDayPicker.delegate = self;
}

- (void)viewDidLayoutSubviews
{
    // Put the current view into the correct location
    self.currentMainView.frame = CGRectMake(0, 124, 320, 444);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSMutableIndexSet *selectedDays = [[NSMutableIndexSet alloc] init];

    if ( self.recurringInfo.repeats == DCRecurringInfoRepeatsNever )
    {
        self.recurringInfo.repeats = DCRecurringInfoRepeatsDaily;
    }

    self.repeatControl.selectedSegmentIndex = self.recurringInfo.repeats;

    self.dailyMainView.frame = CGRectMake(320, 124, 320, 444);
    self.weeklyMainView.frame = CGRectMake(320, 124, 320, 444);
    self.monthlyMainView.frame = CGRectMake(320, 124, 320, 444);

    switch (self.recurringInfo.repeats)
    {
        case DCRecurringInfoRepeatsDaily:

            // Set the current view so we can put it into place later in viewDidLayoutSubviews
            self.currentMainView = self.dailyMainView;

            // Set values
            self.dailyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.dailyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.repeatControl.selectedSegmentIndex = 0;

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.dailyRepeatStepper.value;

            break;

        case DCRecurringInfoRepeatsWeekly:

            // Set the current view so we can put it into place later in viewDidLayoutSubviews
            self.currentMainView = self.weeklyMainView;

            // Set values
            self.weeklyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.weeklyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.repeatControl.selectedSegmentIndex = 1;
            [self.weeklyDayPicker selectAllSegments:NO];
            for ( NSNumber *day in self.recurringInfo.daysToRepeat )
            {
                [selectedDays addIndex:[day integerValue]];
            }
            self.weeklyDayPicker.selectedSegmentIndexes = selectedDays;
            [self updateStartFromControls];

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.weeklyRepeatStepper.value;

            break;

        case DCRecurringInfoRepeatsMonthly:

            // Set the current view so we can put it into place later in viewDidLayoutSubviews
            self.currentMainView = self.monthlyMainView;

            // Set values
            self.monthlyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.monthlyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.repeatControl.selectedSegmentIndex = 2;

            // Reset repeatIncrement in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.monthlyRepeatStepper.value;
            
            break;
            
        case DCRecurringInfoRepeatsYearly:
            break;
            
        default:
            break;
    }

    [self updateRepeatLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveRepeatInfo:(id)sender
{
    [self.delegate didSaveRepeatInfo:self.recurringInfo];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
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
    // Update all the UI controls on the view we're about to show
    UIView *newMainView = nil;
    switch ( sender.selectedSegmentIndex )
    {
        case 0:
            newMainView = self.dailyMainView;
            self.dailyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.dailyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.recurringInfo.repeats = DCRecurringInfoRepeatsDaily;
            break;

        case 1:
            newMainView = self.weeklyMainView;
            self.weeklyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.weeklyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.recurringInfo.repeats = DCRecurringInfoRepeatsWeekly;
            break;

        case 2:
            newMainView = self.monthlyMainView;
            self.monthlyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.monthlyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.recurringInfo.repeats = DCRecurringInfoRepeatsMonthly;
            break;

        default:
            break;
    }

    [self updateRepeatLabel];

    // Animage new view into place
    int multiplier = 1;

    if ( newMainView.tag < self.currentMainView.tag )
    {
        multiplier = -1;
    }

    newMainView.frame = CGRectMake(320 * multiplier, 124, 320, 444);
    newMainView.hidden = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        newMainView.frame = CGRectMake(0, 124, 320, 444);
        self.currentMainView.frame = CGRectMake(320 * multiplier * -1, 124, 320, 444);
    } completion:^(BOOL finished) {
        self.currentMainView.hidden = YES;
        self.currentMainView = newMainView;
    }];

}

- (IBAction)startFromChanged:(UISegmentedControl *)sender
{
    self.recurringInfo.repeatFromLastCompletion = sender.selectedSegmentIndex == 0 ? YES : NO;
}

- (void)updateStartFromControls
{
    if ( self.weeklyDayPicker.selectedSegmentIndexes.count == 0 )
    {
        self.weeklyStartFromControl.enabled = YES;
        self.weeklyStartFromLabel.textColor = [UIColor blackColor];
    }
    else
    {
        self.weeklyStartFromControl.enabled = NO;
        self.weeklyStartFromLabel.textColor = [UIColor lightGrayColor];
    }
}

#pragma mark - #pragma mark -

- (void)multiSelect:(MultiSelectSegmentedControl *)multiSelecSegmendedControl didChangeValue:(BOOL)value atIndex:(NSUInteger)index
{
    if ( value )
    {
        if ( self.recurringInfo.daysToRepeat == nil )
            self.recurringInfo.daysToRepeat = [[NSMutableArray alloc] init];
        [self.recurringInfo.daysToRepeat addObject:[NSNumber numberWithInteger:index]];
    }
    else
    {
        [self.recurringInfo.daysToRepeat removeObject:[NSNumber numberWithInteger:index]];
    }
    
    [self updateStartFromControls];
}

@end
