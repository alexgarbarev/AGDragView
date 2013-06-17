//
//  ViewController.m
//  AGDragViewExample
//
//  Created by Aleksey Garbarev on 17.06.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "ViewController.h"
#import "AGDragView.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController {
    UITableView *contentTableView;
    UIView *headerView;
    AGDragView *dragView;
}


- (void) createHeaderView
{
    headerView = [[[NSBundle mainBundle] loadNibNamed:@"HeaderView" owner:nil options:nil] objectAtIndex:0];
}

- (void) createTableView
{
    contentTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    contentTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    contentTableView.dataSource = self;
    contentTableView.delegate = self;
    
    [self.view addSubview:contentTableView];
}

- (void) createDragView
{
    dragView = [[AGDragView alloc] initWithFrame:self.view.bounds];
    dragView.contentView = contentTableView;
    dragView.contentScrollView = contentTableView;
    dragView.headerView = headerView;
    dragView.shouldHidesNavigationBar = YES;
    dragView.navigationBar = self.navigationController.navigationBar;

    [self.view addSubview:dragView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self createTableView];
    [self createHeaderView];
    [self createDragView];
    
    [dragView minimizeAnimated:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [dragView refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView delegate method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"aCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"A some cell %d",indexPath.row];
    
    return cell;
}

@end
