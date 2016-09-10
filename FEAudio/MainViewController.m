//
//  ViewController.m
//  FEAudio
//
//  Created by FlyElephant on 16/8/10.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomAudioViewController.h"
#import "EZViewController.h"
#import "AudioUnitViewController.h"
#import "AudioTestViewController.h"

@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *dataArray;

@property (assign, nonatomic) NSInteger data;

@end

@implementation MainViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setup];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSLog(@"preferredSampleRate %f",[audioSession sampleRate]);
    NSLog(@"初始值:%ld",self.data);

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
    }else if (indexPath.row == 2) {
        AudioUnitViewController *unitController = [AudioUnitViewController auFromStoryBoard];
        [self.navigationController pushViewController:unitController animated:YES];
    } else if (indexPath.row == 3) {
//        AudioTestViewController *testController = [AudioTestViewController auFromStoryBoard];
//        [self.navigationController pushViewController:testController animated:YES];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"1473173586" ofType:@"wav"];
//        NSURL *fileUrl =[NSURL fileURLWithPath:path];
        NSURL *itemPathURL = [NSURL fileURLWithPath:path];
        CGFloat duration = [self audioSoundDuration:itemPathURL];
        NSLog(@"Record的时长:%f",duration);
    }
}


#pragma mark - SetUp

- (void)setup{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.dataArray = @[@"AEAudio",@"EZAudio",@"AudioUnit",@"AudioTest"];
}

- (BOOL)isHeadSetPlugging {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (float)audioSoundDuration:(NSURL *)fileUrl{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:fileUrl options:options];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
    
    
//    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
//    NSArray *keys = @[@"tracks",
//                      @"playable",
//                      @"duration"];
//    
//    __weak typeof(asset) weakAsset = asset;
//    __weak typeof(self) weakSelf = self;
//    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // check the keys
//            for (NSString *key in keys) {
//                NSError *error = nil;
//                AVKeyValueStatus keyStatus = [weakAsset statusOfValueForKey:key error:&error];
//                
//                switch (keyStatus) {
//                    case AVKeyValueStatusFailed:{
//                        // failed
//                            NSLog(@"音频时间:%f",weakAsset.duration);
//                        break;
//                    }
//                    case AVKeyValueStatusLoaded:{
//                        // success
//                        NSLog(@"音频时间:%f",weakAsset.duration);
//                        break;
//                    }case AVKeyValueStatusCancelled:{
//                        // cancelled
//                            NSLog(@"音频时间:%f",weakAsset.duration);
//                        break;
//                    }
//                    default:
//                        break;
//                }
//            }
//            
//            // check playable
//            if (!weakAsset.playable) { // 不能播放
//                return;
//            }
//            
//        });
//    }];
//    return 0;
}

@end
