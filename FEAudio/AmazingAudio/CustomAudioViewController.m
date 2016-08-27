//
//  AmazingViewController.m
//  FEAudio
//
//  Created by FlyElephant on 16/8/10.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "CustomAudioViewController.h"
#import "TheAmazingAudioEngine.h"
#import "AERecorder.h"

@interface CustomAudioViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property (strong, nonatomic) AEAudioController *audioController;
@property (strong, nonatomic) AEAudioFilePlayer *audioPlayer;
@property (strong, nonatomic) AERecorder        *audioRecorder;

@end

@implementation CustomAudioViewController


+ (instancetype)amazingFromStoryBoard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([CustomAudioViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)playAction:(UIButton *)sender {
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"MyWay" withExtension:@"mp3"];
//    self.audioPlayer = [[AEAudioFilePlayer alloc] initWithURL:url error:nil];
//    [self.audioController addChannels:@[_audioPlayer]];

    NSURL *url = [NSURL fileURLWithPath:[self recordPath]];
    if (url) {
        self.audioPlayer = [[AEAudioFilePlayer alloc] initWithURL:url error:nil];
        [self.audioController addChannels:@[_audioPlayer]];
    }
}

- (IBAction)recordAction:(UIButton *)sender {
    self.audioRecorder = [[AERecorder alloc] initWithAudioController:_audioController];
    NSError *error = nil;
    if (![_audioRecorder beginRecordingToFileAtPath:[self recordPath] fileType:kAudioFileM4AType error:&error]) {
        NSString *info = [NSString stringWithFormat:@"Couldn't start recording: %@", [error localizedDescription]];
        NSLog(@"%@", info);
        self.audioRecorder = nil;
        return;
    }
    [self.audioController addOutputReceiver:_audioRecorder];
    [self.audioController addInputReceiver:_audioRecorder];
}

- (IBAction)stopAction:(UIButton *)sender {
    if (self.audioRecorder) {
        [self.audioRecorder finishRecording];
        [self.audioController removeInputReceiver:_audioRecorder];
        [self.audioController removeOutputReceiver:_audioRecorder];
    }
}

#pragma mark - SetUp

- (void)setup {
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController interleaved16BitStereoAudioDescription] inputEnabled:YES];
    NSError *error = NULL;
    BOOL    result = [self.audioController start:&error];
    if (!result) {
        // Report error
        NSLog(@"AEAudioPlayerError:%@", error);
    }
}

- (NSString *)recordPath {
    NSArray  *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path             = [documentsFolders[0] stringByAppendingPathComponent:@"Recording.m4a"];
    return path;
}

@end
