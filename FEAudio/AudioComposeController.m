//
//  AudioComposeController.m
//  FEAudio
//
//  Created by FlyElephant on 16/9/10.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "AudioComposeController.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioComposeController


+ (instancetype)auFromStoryBoard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions

- (IBAction)composeAction:(UIButton *)sender {
    CMTime startTime = CMTimeMake(13, 100);
    CMTimeShow(startTime);
    
    CMTime endTime = CMTimeMake(40, 100);
    CMTimeShow(endTime);
    
    CMTime addTime = CMTimeAdd(startTime, endTime);
    CMTimeShow(addTime);
    
    CMTime subTime = CMTimeSubtract(startTime,endTime);
    CMTimeShow(subTime);
    
    CMTimeRange timeRange = CMTimeRangeMake(startTime, endTime);
    CMTimeRangeShow(timeRange);
    
    CMTimeRange fromRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    CMTimeRangeShow(fromRange);
    
    //交集
    CMTimeRange intersectionRange = CMTimeRangeGetIntersection(timeRange, fromRange);
    CMTimeRangeShow(intersectionRange);
    //合集
    CMTimeRange unionRange = CMTimeRangeGetUnion(timeRange, fromRange);
    CMTimeRangeShow(unionRange);
    
    NSString *wayPath = [[NSBundle mainBundle] pathForResource:@"MyWay" ofType:@"mp3"];
    NSString *easyPath = [[NSBundle mainBundle] pathForResource:@"Easy" ofType:@"mp3"];
    NSMutableArray *dataArr = [NSMutableArray array];
    [dataArr addObject:[NSURL fileURLWithPath:wayPath]];
    [dataArr addObject:[NSURL fileURLWithPath:easyPath]];
    NSString *destPath = [[self composeDir] stringByAppendingString:@"FlyElephant.m4a"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
    }
    [self audioMerge:dataArr destUrl:[NSURL fileURLWithPath:destPath]];
}

- (IBAction)vedioConposition:(UIButton *)sender {
    NSString *wayPath = [[NSBundle mainBundle] pathForResource:@"MyWay" ofType:@"mp3"];
    NSString *easyPath = [[NSBundle mainBundle] pathForResource:@"Way" ofType:@"mp4"];
    
    NSString *destPath = [[self composeDir] stringByAppendingString:@"FlyElephant.mp4"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
    }
    [self audioVedioMerge:[NSURL fileURLWithPath:wayPath] vedioUrl:[NSURL fileURLWithPath:easyPath] destUrl:[NSURL fileURLWithPath:destPath]];
}

- (IBAction)cropAction:(UIButton *)sender {
    NSString *inputPath = [[self composeDir] stringByAppendingString:@"FlyElephant.m4a"];
    
    [self audioCrop:[NSURL fileURLWithPath:inputPath] startTime:kCMTimeZero endTime:CMTimeMake(302, 1)];
}

#pragma mark - Private
//音频合并
- (void)audioMerge:(NSMutableArray *)dataSource destUrl:(NSURL *)destUrl{
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    // 开始时间
    CMTime beginTime = kCMTimeZero;
    // 设置音频合并音轨
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error = nil;
    for (NSURL *sourceURL in dataSource) {
        //音频文件资源
        AVURLAsset  *audioAsset = [[AVURLAsset alloc] initWithURL:sourceURL options:nil];
        //需要合并的音频文件的区间
        CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        // ofTrack 音频文件内容
        BOOL success = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:beginTime error:&error];
        
        if (!success) {
            NSLog(@"Error: %@",error);
        }
        beginTime = CMTimeAdd(beginTime, audioAsset.duration);
    }
    // presetName 与 outputFileType 要对应  导出合并的音频
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
    NSLog(@"%@",assetExportSession.supportedFileTypes);
    assetExportSession.outputURL = destUrl;
    assetExportSession.outputFileType = @"com.apple.m4a-audio";
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"音频合并之后的地址:%@",[destUrl path]);
            NSLog(@"%@",assetExportSession.error);
        });
    }];
}

//音视频合并

- (void)audioVedioMerge:(NSURL *)audioUrl vedioUrl:(NSURL *)vedioUrl destUrl:(NSURL *)destUrl {
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    NSError *error;
    
    AVMutableCompositionTrack *audioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频文件资源
    AVURLAsset  *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    [audioCompostionTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:&error];
    
    //视频文件资源
    AVMutableCompositionTrack *vedioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVURLAsset *vedioAsset = [[AVURLAsset alloc] initWithURL:vedioUrl options:nil];
    CMTimeRange vedio_timeRange = CMTimeRangeMake(kCMTimeZero, vedioAsset.duration);
    [vedioCompostionTrack insertTimeRange:vedio_timeRange ofTrack:[[vedioAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:&error];
    
    // presetName 与 outputFileType 要对应  导出合并的音频
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    NSLog(@"%@",assetExportSession.supportedFileTypes);
    assetExportSession.outputURL = destUrl;
    assetExportSession.outputFileType = @"com.apple.quicktime-movie";
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"音频合并之后的地址:%@",[destUrl path]);
            NSLog(@"%@",assetExportSession.error);
        });
    }];
    
}

//音频剪切

- (void)audioCrop:(NSURL *)url startTime:(CMTime)startTime endTime:(CMTime)endTime {
    
    NSString *outPutPath = [[self composeDir] stringByAppendingPathComponent:@"Crop.m4a"];
    NSURL *audioFileOutput = [NSURL fileURLWithPath:outPutPath];
    
    [[NSFileManager defaultManager] removeItemAtURL:audioFileOutput error:NULL];
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset
                                                                            presetName:AVAssetExportPresetAppleM4A];
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    
    exportSession.outputURL = audioFileOutput;
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = exportTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (AVAssetExportSessionStatusCompleted == exportSession.status) {
            NSLog(@" OUtput path is \n %@", outPutPath);
        } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
            NSLog(@"failed with error: %@", exportSession.error.localizedDescription);
        }
    }];
}

- (NSString *)composeDir {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    NSString *compseDir = [NSString stringWithFormat:@"%@/AudioCompose/", cacheDir];
    BOOL isDir = NO;
    BOOL existed = [fileManager fileExistsAtPath:compseDir isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:compseDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return compseDir;
}


@end
