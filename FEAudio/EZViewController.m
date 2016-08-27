//
//  EZViewController.m
//  FEAudio
//
//  Created by FlyElephant on 16/8/27.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EZViewController.h"
#import "EZAudioDisplayLink.h"
#import "EZAudioPlot.h"
#import "EZAudioFile.h"
#import "EZAudioPlayer.h"

@interface EZViewController ()<EZAudioDisplayLinkDelegate,AVAudioPlayerDelegate,EZAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet EZAudioPlot *audioPlot;

@property (strong, nonatomic) EZAudioDisplayLink *displayLink;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) EZAudioFile *audioFile;

@property (nonatomic, strong) EZAudioPlayer *player;


@end

@implementation EZViewController

+ (instancetype)ezFromStoryBoard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([EZViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUp];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - EZAudioDisplayLinkDelegate

- (void)displayLinkNeedsDisplay:(EZAudioDisplayLink *)displayLink {
    NSLog(@"displayLinkNeedsDisplay");
}

#pragma mark - Acitons

- (IBAction)playAction:(id)sender {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    [self playSound];
}

- (IBAction)drawAction:(id)sender {
    [self drawAudioPlot];
}

- (IBAction)realTimeAction:(id)sender {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"drum" withExtension:@"wav"];
    self.audioFile = [EZAudioFile audioFileWithURL:fileUrl];
    
    
    //
    // Plot the whole waveform
    //
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    __weak typeof (self) weakSelf = self;
    [self.audioFile getWaveformDataWithCompletionBlock:^(float **waveformData,
                                                         int length)
     {
         [weakSelf.audioPlot updateBuffer:waveformData[0]
                           withBufferSize:length];
     }];
    
    //
    // Play the audio file
    //
    [self.player setAudioFile:self.audioFile];
    [self.player play];
}


#pragma mark - Private

- (void)drawAudioPlot {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"drum" withExtension:@"wav"];
//    [self playSound];
    
    
    self.audioFile = [EZAudioFile audioFileWithURL:fileUrl];

    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    __weak typeof (self) weakSelf = self;
    [self.audioFile getWaveformDataWithCompletionBlock:^(float **waveformData,
                                                         int length)
     {
         [weakSelf.audioPlot updateBuffer:waveformData[0]
                           withBufferSize:length];
     }];
}

- (void)playSound {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"MyWay" withExtension:@"mp3"];
    NSError *err = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&err];
    self.audioPlayer.numberOfLoops = 0;
    self.audioPlayer.delegate = self;
    self.audioPlayer.volume = 1;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"播放结束");
}

#pragma mark - EZAudioPlayerDelegate
//需要实时更新
- (void)  audioPlayer:(EZAudioPlayer *)audioPlayer
          playedAudio:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
          inAudioFile:(EZAudioFile *)audioFile
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlot updateBuffer:buffer[0]
                          withBufferSize:bufferSize];
    });
}


#pragma mark - SetUp

- (void)setUp {
    //CADisplayLink 每秒60fps 执行
    self.displayLink = [EZAudioDisplayLink displayLinkWithDelegate:self];
//    [self.displayLink start];
    
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed:0.984 green:0.471 blue:0.525 alpha:1.0];
//    self.audioPlot.color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.audioPlot.color = [UIColor greenColor];
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
    
    self.audioPlot.shouldOptimizeForRealtimePlot = NO;
    self.audioPlot.waveformLayer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.audioPlot.waveformLayer.shadowRadius = 0.0;
    self.audioPlot.waveformLayer.shadowColor = [UIColor colorWithRed: 0.069 green: 0.543 blue: 0.575 alpha: 1].CGColor;
    self.audioPlot.waveformLayer.shadowOpacity = 1.0;
    
    self.player = [EZAudioPlayer audioPlayerWithDelegate:self];
    self.player.shouldLoop = YES;
}

@end
