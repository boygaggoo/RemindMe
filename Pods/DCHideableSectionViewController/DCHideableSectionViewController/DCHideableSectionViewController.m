//
//  DCHideableSectionViewController.m
//  RemindMe
//
//  Created by Dan Cohn on 2/5/14.
//  Copyright (c) 2014 Dan Cohn. All rights reserved.
//

#import "DCHideableSectionViewController.h"

@interface DCHideableSectionViewController ()

@end

@implementation DCHideableSectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Help hide padding above top of grouped sections when trying to hide the section
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
}

- (UIView *)sectionFiller
{
    static UILabel *emptyLabel = nil;
    if (!emptyLabel)
    {
        emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        emptyLabel.backgroundColor = [UIColor clearColor];
    }
    
    return emptyLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ( [self tableView:tableView numberOfRowsInSection:section] == 0 )
    {
        return 0;
    }
    
    return self.headerViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ( [self tableView:tableView numberOfRowsInSection:section] == 0 )
    {
        return [self sectionFiller];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ( [self tableView:tableView numberOfRowsInSection:section] == 0 )
    {
        return 0;
    }
    
    return self.footerViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ( [self tableView:tableView numberOfRowsInSection:section] == 0 )
    {
        return [self sectionFiller];
    }
    
    return nil;
}

@end
