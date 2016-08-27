//
//  ViewController.m
//  FEAudio
//
//  Created by FlyElephant on 16/8/10.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "MainViewController.h"
#import "CustomAudioViewController.h"
#import "EZViewController.h"

@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *dataArray;

@end

@implementation MainViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSouce

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (!cell) {
         cell= [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([UITableViewCell class])];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        CustomAudioViewController *controller = [CustomAudioViewController amazingFromStoryBoard];
        [self.navigationController pushViewController:controller animated:YES];
    }else if (indexPath.row ==1 ) {
        EZViewController *controller = [EZViewController ezFromStoryBoard];
        [self.navigationController pushViewController:controller animated:YES];
    }
}


#pragma mark - SetUp

- (void)setup{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.dataArray = @[@"AEAudio",@"EZAudio"];
}

@end
