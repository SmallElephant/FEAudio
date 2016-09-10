//
//  AudioUnitViewController.h
//  FEAudio
//
//  Created by FlyElephant on 16/8/30.
//  Copyright © 2016年 FlyElephant. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#ifndef max
#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef min
#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )
#endif

@interface AudioUnitViewController : UIViewController{
    AudioComponentInstance audioUnit;
    AudioBuffer tempBuffer; // this will hold the latest data from the microphone
}

//@property (assign, nonatomic) AudioUnit remoteUnit;
//@property (assign, nonatomic) AudioBufferList bufferList;

@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioBuffer tempBuffer;

+ (instancetype)auFromStoryBoard;

- (void) start;
- (void) stop;
- (void) processAudio: (AudioBufferList*) bufferList;

@end
