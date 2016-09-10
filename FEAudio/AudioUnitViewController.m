//
//  AudioUnitViewController.m
//  FEAudio
//
//  Created by FlyElephant on 16/8/30.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import "AudioUnitViewController.h"

//http://www.programgo.com/article/48012458406/
//因为对remoteio来说，1是input，0是output  
#define kOutputBus 0
#define kInputBus 1
FILE *pFile;

void checkStatus(OSStatus status) {
    if(status!=0)
        printf("Error: %d\n", (int)status);
}

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // Because of the way our audio format (setup below) is chosen:
    // we only need 1 buffer, since it is mono
    // Samples are 16 bits = 2 bytes.
    // 1 frame includes only 1 sample
    
    AudioUnitViewController *unitController = (__bridge AudioUnitViewController *)(inRefCon);
    
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    buffer.mData = malloc( inNumberFrames * 2 );
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Then:
    // Obtain recorded samples
    
    OSStatus status;
    
    status = AudioUnitRender([unitController audioUnit],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    checkStatus(status);
    
    // Now, we have the samples we just read sitting in buffers in bufferList
    // Process the new data
    [unitController processAudio:&bufferList];
    
    fwrite(bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize,1 , pFile);
    fflush(pFile);
    
    // release the malloc'ed data in the buffer we created earlier
    free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    AudioUnitViewController *unitController = (__bridge AudioUnitViewController *)(inRefCon);
    
    for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
        AudioBuffer buffer = ioData->mBuffers[i];
        
        //		NSLog(@"  Buffer %d has %d channels and wants %d bytes of data.", i, buffer.mNumberChannels, buffer.mDataByteSize);
        
        // copy temporary buffer data to output buffer
        UInt32 size = min(buffer.mDataByteSize, [unitController tempBuffer].mDataByteSize); // dont copy more data then we have, or then fits
        memcpy(buffer.mData, [unitController tempBuffer].mData, size);
        buffer.mDataByteSize = size; // indicate how much data we wrote in the buffer
        
        // uncomment to hear random noise
        /*
         UInt16 *frameBuffer = buffer.mData;
         for (int j = 0; j < inNumberFrames; j++) {
         frameBuffer[j] = rand();
         }
         */
        
    }
    
    return noErr;
}



@interface AudioUnitViewController () {
   AudioUnit remoteUnit;
//   AudioBufferList bufferList;
}

@property (strong, nonatomic) NSURL *fileURL;

@end

@implementation AudioUnitViewController


+ (instancetype)auFromStoryBoard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([AudioUnitViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *Pathes = path.lastObject;
//    NSString *filePath = [Pathes stringByAppendingPathComponent:@"Audio.pcm"];
//    NSLog(@"录制音频的路径:%@",filePath);
//    const char *str = [filePath UTF8String];
//    pFile = fopen(str, "w");
    [self setUp];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    AudioComponentInstanceDispose(remoteUnit);
}

#pragma mark - Actions

/**
 Start the audioUnit. This means data will be provided from
 the microphone, and requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
    
    OSStatus status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
}

/**
 Stop the audioUnit
 */
- (void) stop {
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
}

/**
 Change this funtion to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */
- (void) processAudio: (AudioBufferList*) bufferList{
    AudioBuffer sourceBuffer = bufferList->mBuffers[0];
    
    // fix tempBuffer size if it's the wrong size
    if (tempBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        free(tempBuffer.mData);
        tempBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
        tempBuffer.mData = malloc(sourceBuffer.mDataByteSize);
    }
    
    // copy incoming audio data to temporary buffer
    memcpy(tempBuffer.mData, bufferList->mBuffers[0].mData, bufferList->mBuffers[0].mDataByteSize);
}



- (IBAction)recordAction:(id)sender {
//    OSStatus status = AudioOutputUnitStart(remoteUnit);
////    NSLog(@"%@",status);
//    checkStatus(status);
    [self start];
}


- (IBAction)playAction:(id)sender {
    float duration = [self audioSoundDuration:self.fileURL];
    NSLog(@"音频时长:%f",duration);
}

- (IBAction)pauseAction:(id)sender {
//    OSStatus status = AudioOutputUnitStop(remoteUnit);
//    checkStatus(status);
    [self stop];
}

- (float)audioSoundDuration:(NSURL *)fileUrl{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:fileUrl options:options];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
}



#pragma mark - SetUp

- (void)setUp {
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *Pathes = path.lastObject;
    NSString *filePath = [Pathes stringByAppendingPathComponent:@"FlyElephant.pcm"];
    self.fileURL = [NSURL fileURLWithPath:filePath];
    const char *str = [filePath UTF8String];
    NSLog(@"录音路径:%@",filePath);
    pFile = fopen(str, "w");
    
    // You can adjust the latency of RemoteIO (and, in fact, any other audio framework) by setting the kAudioSessionProperty_PreferredHardwareIOBufferDuration property
    float aBufferLength = 0.005; // In seconds
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(aBufferLength), &aBufferLength);
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Describe format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= 44100.00;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct, 
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit, 
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output, 
                                  kInputBus,
                                  &flag, 
                                  sizeof(flag));
    
    // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
    // Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
    tempBuffer.mNumberChannels = 1;
    tempBuffer.mDataByteSize = 512 * 2;
    tempBuffer.mData = malloc( 512 * 2 );
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
}

- (void)setUp1 {
    OSStatus status;
    AudioComponentInstance audioUnit;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    AudioStreamBasicDescription audioFormat;
    
    // Describe format
    audioFormat.mSampleRate			= 44100.00;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output, 
                                  kInputBus,
                                  &flag, 
                                  sizeof(flag));
    
    // TODO: Allocate our own buffers if we want
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
//    UInt32 category = kAudioSessionCategory_PlayAndRecord;
//    status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
//    checkStatus(status);
//    status = 0;
//    status = AudioSessionSetActive(YES);
//    checkStatus(status);
//    status = AudioUnitInitialize(rioUnit);
//    checkStatus(status);
}



#pragma mark Recording Callback

//static OSStatus recordingCallback(void *inRefCon,
//                                  AudioUnitRenderActionFlags *ioActionFlags,
//                                  const AudioTimeStamp *inTimeStamp,
//                                  UInt32 inBusNumber,
//                                  UInt32 inNumberFrames,
//                                  AudioBufferList *ioData) {
//    
//    AudioUnitViewController *THIS = (__bridge AudioUnitViewController*) inRefCon;
//    AudioBufferList bufferList = THIS->bufferList;
//    bufferList.mNumberBuffers = 1;
//    bufferList.mBuffers[0].mDataByteSize = sizeof(SInt16)*inNumberFrames;
//    bufferList.mBuffers[0].mNumberChannels = 1;
//    bufferList.mBuffers[0].mData = (SInt16*) malloc(sizeof(SInt16)*inNumberFrames);
//    
//    OSStatus status;
//    status = AudioUnitRender(THIS->remoteUnit,
//                             ioActionFlags,
//                             inTimeStamp,
//                             inBusNumber,
//                             inNumberFrames,
//                             &(THIS->bufferList));
//    checkStatus(status);
//
//    fwrite(bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize,1 , pFile);
//    fflush(pFile);
//    free(bufferList.mBuffers[0].mData);
//    return noErr;
//}
//
//
//static OSStatus playbackCallback(void *inRefCon,
//                                 AudioUnitRenderActionFlags *ioActionFlags,
//                                 const AudioTimeStamp *inTimeStamp,
//                                 UInt32 inBusNumber,
//                                 UInt32 inNumberFrames,
//                                 AudioBufferList *ioData) {
//    // Notes: ioData contains buffers (may be more than one!)
//    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
//    // much data is in the buffer.
//    return noErr;
//}


//static OSStatus recordingCallback(void *inRefCon,
//                                  AudioUnitRenderActionFlags *ioActionFlags,
//                                  const AudioTimeStamp *inTimeStamp,
//                                  UInt32 inBusNumber,
//                                  UInt32 inNumberFrames,
//                                  AudioBufferList *ioData) {
//    
//    
//    AudioBuffer buffer;
//    OSStatus status;
//    buffer.mDataByteSize = inNumberFrames *2;
//    buffer.mNumberChannels = 1;
//    buffer.mData= malloc(inNumberFrames *2);
//    AudioBufferList bufferList;
//    bufferList.mNumberBuffers = 1;
//    bufferList.mBuffers[0] = buffer;
//    status = AudioUnitRender([iosAudio audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
//    [iosAudio processAudio:&bufferList];
//    NSLog(@"%u", (unsigned int)bufferList.mBuffers[0].mDataByteSize);
//    //    NSLog(@"%@", bufferList.mBuffers[0].mData);
//    
//    
//    fwrite(bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize,1 , pFile);
//    fflush(pFile);
//    free(bufferList.mBuffers[0].mData);
//    
//    return noErr;
//}

@end
