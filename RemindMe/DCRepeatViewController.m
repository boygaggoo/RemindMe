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
@property (weak, nonatomic) UIView *currentMonthSubView;

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
@property (weak, nonatomic) IBOutlet UIView *weeklyRepeatFromView;

// Monthly controls
@property (weak, nonatomic) IBOutlet UIView *monthlyMainView;
@property (weak, nonatomic) IBOutlet UIStepper *monthlyRepeatStepper;
@property (weak, nonatomic) IBOutlet UILabel *monthlyRepeatLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *monthlyStartFromControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *monthlyDayOrWeekControl;
@property (weak, nonatomic) IBOutlet UILabel *monthlyDayOfMonthLabel;
@property (weak, nonatomic) IBOutlet UIStepper *monthlyDayOfMonthStepper;
@property (weak, nonatomic) IBOutlet UIStepper *monthlyWeekOfMonthStepper;
@property (weak, nonatomic) IBOutlet UISegmentedControl *monthlyDayPicker;
@property (weak, nonatomic) IBOutlet UILabel *monthlyWeekOfMonthLabel;

@property (weak, nonatomic) IBOutlet UIView *monthlyMainDailyView;
@property (weak, nonatomic) IBOutlet UIView *monthlyMainWeeklyView;
@property (weak, nonatomic) IBOutlet UIView *monthlyMainRegularMonthlyView;



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
    
    if ( self.recurringInfo.daysToRepeat.count == 0 )
    {
        // Set tag to 0 so we don't move it
        self.weeklyRepeatFromView.tag = 0;
    }
    else
    {
        // Set tag to 5 so layoutSubviews will know to move the view off screen
        self.weeklyRepeatFromView.tag = 5;
    }
}

- (void)viewDidLayoutSubviews
{
    // Put the current view into the correct location
    CGRect frame = self.currentMainView.frame;
    frame.origin.x = 0;
    self.currentMainView.frame = frame;

    // Put the correct monthly subview into place
    frame = self.currentMonthSubView.frame;
    frame.origin.x = 0;
    self.currentMonthSubView.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( self.recurringInfo.repeats == DCRecurringInfoRepeatsNever )
    {
        self.recurringInfo.repeats = DCRecurringInfoRepeatsDaily;
    }

    self.repeatControl.selectedSegmentIndex = self.recurringInfo.repeats;
    
    
    CGRect frame = self.dailyMainView.frame;
    frame.origin.x = 320;
    self.dailyMainView.frame = frame;
    
    frame = self.weeklyMainView.frame;
    frame.origin.x = 320;
    self.weeklyMainView.frame = frame;
    
    frame = self.monthlyMainView.frame;
    frame.origin.x = 320;
    self.monthlyMainView.frame = frame;
    

    switch ( self.recurringInfo.monthlyRepeatType )
    {
        case DCRecurringInfoMonthlyTypeDayOfMonth:
            self.currentMonthSubView = self.monthlyMainDailyView;
            self.monthlyDayOrWeekControl.selectedSegmentIndex = 0;
            break;
            
        case DCRecurringInfoMonthlyTypeWeekOfMonth:
            self.currentMonthSubView = self.monthlyMainWeeklyView;
            self.monthlyDayOrWeekControl.selectedSegmentIndex = 1;
            break;
            
        case DCRecurringInfoMonthlyTypeRegular:
            self.currentMonthSubView = self.monthlyMainRegularMonthlyView;
            self.monthlyDayOrWeekControl.selectedSegmentIndex = 2;
            break;
    }
    

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
            [self updateMultiSelectControl:self.weeklyDayPicker];

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
            self.monthlyDayPicker.selectedSegmentIndex = self.recurringInfo.monthlyWeekDay;
            
            // Reset repeatIncrement and dayOfMonth in case the original value was outside the allowed range
            self.recurringInfo.repeatIncrement = self.monthlyRepeatStepper.value;
            
            break;
            
        case DCRecurringInfoRepeatsYearly:
            break;
            
        default:
            break;
    }
    
    self.monthlyDayOfMonthStepper.value = self.recurringInfo.dayOfMonth;
    self.recurringInfo.dayOfMonth = self.monthlyDayOfMonthStepper.value;
    self.monthlyWeekOfMonthStepper.value = self.recurringInfo.nthWeekOfMonth;
    self.recurringInfo.nthWeekOfMonth = self.monthlyWeekOfMonthStepper.value;

    [self updateRepeatLabel];
    [self updateDayOfMonthLabel];
    [self updateWeekOfMonthLabel];

//    [self viewDidLayoutSubviewss];
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

- (void)updateMultiSelectControl:(MultiSelectSegmentedControl *)control
{
    NSMutableIndexSet *selectedDays = [[NSMutableIndexSet alloc] init];

    [control selectAllSegments:NO];
    for ( NSNumber *day in self.recurringInfo.daysToRepeat )
    {
        [selectedDays addIndex:[day integerValue]];
    }
    control.selectedSegmentIndexes = selectedDays;

    [self updateStartFromControls:control];
}

- (void)updateDayOfMonthLabel
{
    NSString *text = [NSString stringWithFormat:@"Day of month: %d", self.recurringInfo.dayOfMonth];
    self.monthlyDayOfMonthLabel.text = text;
}

- (void)updateWeekOfMonthLabel
{
    NSString *number = nil;
    if ( self.recurringInfo.nthWeekOfMonth == 1 )
        number = @"First";
    else if ( self.recurringInfo.nthWeekOfMonth == 2 )
        number = @"Second";
    else if ( self.recurringInfo.nthWeekOfMonth == 3 )
        number = @"Third";
    else if ( self.recurringInfo.nthWeekOfMonth == 4 )
        number = @"Fourth";
    else if ( self.recurringInfo.nthWeekOfMonth == 5 )
        number = @"Fifth";
    else
    {
        number = @"Fifth";
        NSLog( @"Error: Trying to set week of month to %d", self.recurringInfo.nthWeekOfMonth );
        self.recurringInfo.nthWeekOfMonth = 5;
    }
    
    NSString *weekday = nil;
    switch ( self.recurringInfo.monthlyWeekDay )
    {
        case DCRecurringInfoWeekDaysSunday:
            weekday = @"Sunday";
            break;
        case DCRecurringInfoWeekDaysMonday:
            weekday = @"Monday";
            break;
        case DCRecurringInfoWeekDaysTuesday:
            weekday = @"Tuesday";
            break;
        case DCRecurringInfoWeekDaysWednesday:
            weekday = @"Wednesday";
            break;
        case DCRecurringInfoWeekDaysThursday:
            weekday = @"Thursday";
            break;
        case DCRecurringInfoWeekDaysFriday:
            weekday = @"Friday";
            break;
        case DCRecurringInfoWeekDaysSaturday:
            weekday = @"Saturday";
            break;
    }
    
    NSString *text = [NSString stringWithFormat:@"%@ %@\nof the month", number, weekday];
    self.monthlyWeekOfMonthLabel.text = text;
}

- (IBAction)stepperChanged:(UIStepper *)sender
{
    self.recurringInfo.repeatIncrement = (int)floor(sender.value);
    [self updateRepeatLabel];
}

- (IBAction)dayOfMonthStepperChanged:(UIStepper *)sender
{
    self.recurringInfo.dayOfMonth = (int)floor(sender.value);
    [self updateDayOfMonthLabel];
}

- (IBAction)weekOfMonthStepperChanged:(UIStepper *)sender
{
    self.recurringInfo.nthWeekOfMonth = (int)floor(sender.value);
    [self updateWeekOfMonthLabel];
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
            [self updateMultiSelectControl:self.weeklyDayPicker];
            break;

        case 2:
            newMainView = self.monthlyMainView;
            self.monthlyRepeatStepper.value = self.recurringInfo.repeatIncrement;
            self.monthlyStartFromControl.selectedSegmentIndex = self.recurringInfo.repeatFromLastCompletion ? 0 : 1;
            self.recurringInfo.repeats = DCRecurringInfoRepeatsMonthly;
            self.monthlyDayPicker.selectedSegmentIndex = self.recurringInfo.monthlyWeekDay;
            break;

        default:
            break;
    }

    [self updateRepeatLabel];

    // Animate new view into place
    int multiplier = 1;

    if ( newMainView.tag < self.currentMainView.tag )
    {
        multiplier = -1;
    }

    CGRect frame = newMainView.frame;
    frame.origin.x = 320 * multiplier;
    newMainView.frame = frame;
    newMainView.hidden = NO;
    
    frame.origin.x = 0;
    CGRect hiddenFrame = self.currentMainView.frame;
    hiddenFrame.origin.x = 320 * multiplier * -1;
    
    [UIView animateWithDuration:0.2 animations:^{
        newMainView.frame = frame;
        self.currentMainView.frame = hiddenFrame;
    } completion:^(BOOL finished) {
        self.currentMainView.hidden = YES;
        self.currentMainView = newMainView;
    }];

}

- (IBAction)dayWeekControlChanged:(UISegmentedControl *)sender
{
    UIView *newSubView = nil;
    int multiplier = 1;

    switch ( sender.selectedSegmentIndex )
    {
        case 0: // Pick day
            newSubView = self.monthlyMainDailyView;
            self.recurringInfo.monthlyRepeatType = DCRecurringInfoMonthlyTypeDayOfMonth;
            [self updateDayOfMonthLabel];
            break;
        case 1: // Pick Week
            newSubView = self.monthlyMainWeeklyView;
            self.recurringInfo.monthlyRepeatType = DCRecurringInfoMonthlyTypeWeekOfMonth;
            break;
        case 2: // Plain old monthly
            newSubView = self.monthlyMainRegularMonthlyView;
            self.recurringInfo.monthlyRepeatType = DCRecurringInfoMonthlyTypeRegular;
            break;
    }
    
    if ( newSubView.tag < self.currentMonthSubView.tag )
    {
        multiplier = -1;
    }
    
    // Animate sub view into place
    CGRect frame = newSubView.frame;
    frame.origin.x = 320 * multiplier;
    newSubView.frame = frame;
    newSubView.hidden = NO;
    
    frame.origin.x = 0;
    CGRect hiddenFrame = self.currentMonthSubView.frame;
    hiddenFrame.origin.x = 320 * multiplier * -1;
    [UIView animateWithDuration:0.2 animations:^{
        newSubView.frame = frame;
        self.currentMonthSubView.frame = hiddenFrame;
    } completion:^(BOOL finished) {
        self.currentMonthSubView.hidden = YES;
        self.currentMonthSubView = newSubView;
    }];
}

- (IBAction)dayOfWeekSelected:(UISegmentedControl *)sender
{
    self.recurringInfo.monthlyWeekDay = sender.selectedSegmentIndex;
    [self updateWeekOfMonthLabel];
}

- (IBAction)startFromChanged:(UISegmentedControl *)sender
{
    self.recurringInfo.repeatFromLastCompletion = sender.selectedSegmentIndex == 0 ? YES : NO;
}

- (void)updateStartFromControls:(MultiSelectSegmentedControl *)control
{
    if ( control == self.weeklyDayPicker )
    {
        if ( self.weeklyDayPicker.selectedSegmentIndexes.count == 0 )
        {
            [self enableWeeklyRepeatFromControl:YES];
        }
        else
        {
            [self enableWeeklyRepeatFromControl:NO];
        }
    }
}

- (void)enableWeeklyRepeatFromControl:(BOOL)enabled
{
    CGRect frame = self.weeklyRepeatFromView.frame;
    if ( enabled )
    {
        if ( frame.origin.x != 0 )
        {
            frame.origin.x = 0;
            
            [UIView animateWithDuration:0.2 animations:^{
                self.weeklyRepeatFromView.frame = frame;
            } completion:^(BOOL finished) {
            }];
        }
    }
    else
    {
        if ( frame.origin.x != 320 )
        {
            frame.origin.x = 320;
            
            [UIView animateWithDuration:0.2 animations:^{
                self.weeklyRepeatFromView.frame = frame;
            } completion:^(BOOL finished) {
            }];
        }
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
    
    [self updateStartFromControls:multiSelecSegmendedControl];
}

@end
