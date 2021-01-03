//
//  ViewController.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 29/12/20.
//

#import "ViewController.h"
#import "ClientSession.h"

@interface ViewController ()

@property (strong, nonatomic) ClientSession *session;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.session = [[ClientSession alloc] initWithSnapServerHost:@"192.168.1.5" port:1704];
}

/*
#pragma mark - Audio Queue
- (void)initAudioQueue {
    
    AudioStreamBasicDescription streamFormat = {0};
    streamFormat.mSampleRate = 44100;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mBitsPerChannel = 16;

    streamFormat.mBytesPerFrame = (streamFormat.mBitsPerChannel / 8) * streamFormat.mChannelsPerFrame;
    streamFormat.mBytesPerPacket = streamFormat.mBytesPerFrame;
    streamFormat.mReserved = 0;
    
    // fill out thr ASBD for FLAC
    AudioStreamBasicDescription streamFormat = {0};
    //streamFormat.mFormatFlags = kAppleLosslessFormatFlag_24BitSourceData;
    streamFormat.mSampleRate = 44100;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mFormatID = kAudioFormatFLAC;
    
    uint32_t size = sizeof(streamFormat);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &streamFormat);

    // create the audio queue
    OSStatus err = AudioQueueNewOutput(&streamFormat, audioQueueCallback, (__bridge void *)self, NULL, NULL, 0, &audioQueue);
    if (err != noErr) {
        
    }
    
    // allocate some audio queue buffers
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(audioQueue, BUFFER_SIZE, &audioQueueBuffers[i]);
        audioQueueBuffers[i]->mAudioDataByteSize = BUFFER_SIZE;
        audioQueueCallback((__bridge void *)(self), audioQueue, audioQueueBuffers[i]);
        //AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, NULL);
    }
    
    //AudioQueuePrime(audioQueue, 0, NULL);
    
    err = AudioQueueStart(audioQueue, NULL);
    if (err != noErr) {
        NSLog(@"Error occurred starting AudioQueue: %d", err);
    }
}

#pragma mark - Cleanup
- (void)dealloc {
    TPCircularBufferCleanup(&buffer);
}

void audioQueueCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    ViewController *THIS = (__bridge ViewController *)inUserData;
    
    uint32_t bufferAudioDataByteSize = inBuffer->mAudioDataByteSize;
    SInt16 *targetBuffer = inBuffer->mAudioData;
    
    // pull audio from circular buffer
    uint32_t availableBytesFromCircularBuffer;
    SInt16 *buffer = TPCircularBufferTail(&THIS->buffer, &availableBytesFromCircularBuffer);
    
    uint32_t bytesToCopy = MIN(bufferAudioDataByteSize, availableBytesFromCircularBuffer);
    if (bytesToCopy > 0) {
        memcpy(targetBuffer, buffer, bytesToCopy);
        TPCircularBufferConsume(&THIS->buffer, bytesToCopy);
        
        OSStatus error = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if (error != noErr) {
            NSLog(@"Error enqueuing buffer: %d", error);
        } else {
            NSLog(@"Enqueued audioQueue buffer");
        }
    } else {
        NSLog(@"Not enough bytes in circular buffer to copy, no-op");
    }
}
 */

@end
