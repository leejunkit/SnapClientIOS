//
//  AudioRenderer.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import "AudioRenderer.h"
@import AVFoundation;

#define NUM_BUFFERS 3
#define BUFFER_SIZE 19200

@interface AudioRenderer () {
    TPCircularBuffer pcmCircularBuffer;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffers[NUM_BUFFERS];
}

@property (nonatomic, strong) StreamInfo *streamInfo;

@end

@implementation AudioRenderer

- (instancetype)initWithStreamInfo:(StreamInfo *)info PCMCircularBuffer:(TPCircularBuffer *)cb {
    if (self = [super init]) {
        self.streamInfo = info;
        pcmCircularBuffer = *cb;
        [self initAudioQueue];
    }
    return self;
}

- (void)initAudioQueue {
    AudioStreamBasicDescription format;
    format.mSampleRate = self.streamInfo.sampleRate;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    format.mBitsPerChannel = self.streamInfo.bitsPerSample;
    format.mChannelsPerFrame = self.streamInfo.channels;
    format.mBytesPerFrame = self.streamInfo.frameSize;
    format.mFramesPerPacket = 1;
    format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;
    format.mReserved = 0;

    // create the audio queue
    OSStatus err = AudioQueueNewOutput(&format, audioQueueCallback, (__bridge void *)self, NULL, NULL, 0, &audioQueue);
    if (err != noErr) {
        
    }
    
    // allocate some audio queue buffers
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(audioQueue, BUFFER_SIZE, &audioQueueBuffers[i]);
        audioQueueBuffers[i]->mAudioDataByteSize = BUFFER_SIZE;
        audioQueueCallback((__bridge void *)(self), audioQueue, audioQueueBuffers[i]);
    }
    
    //AudioQueuePrime(audioQueue, 0, NULL);
    
    err = AudioQueueStart(audioQueue, NULL);
    if (err != noErr) {
        NSLog(@"Error occurred starting AudioQueue: %d", err);
    }
}

void audioQueueCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    AudioRenderer *THIS = (__bridge AudioRenderer *)inUserData;
    
    uint32_t audioQueueBufferRequestedSize = inBuffer->mAudioDataByteSize;
    SInt16 *targetBuffer = inBuffer->mAudioData;
    
    // pull audio from circular buffer
    uint32_t availableBytesFromCircularBuffer;
    SInt16 *buffer = TPCircularBufferTail(&THIS->pcmCircularBuffer, &availableBytesFromCircularBuffer);
    
    if (availableBytesFromCircularBuffer > 0) {
        if (availableBytesFromCircularBuffer > audioQueueBufferRequestedSize) {
            memcpy(targetBuffer, buffer, audioQueueBufferRequestedSize);
            TPCircularBufferConsume(&THIS->pcmCircularBuffer, audioQueueBufferRequestedSize);
        } else {
            // audioQueueBuffer is requesting more data than what we have
            // in the circular buffer - give it everything we've got then
            // top up with silence (0s) at the end
            memset(targetBuffer, 0, audioQueueBufferRequestedSize);
            memcpy(targetBuffer, buffer, availableBytesFromCircularBuffer);
            TPCircularBufferConsume(&THIS->pcmCircularBuffer, availableBytesFromCircularBuffer);
        }
    } else {
        // we have nothing to offer the audioQueueBuffer
        // fill the buffer with 0s
        //memcpy(targetBuffer, (void *)memcpy, audioQueueBufferRequestedSize);
        memset(targetBuffer, 0, audioQueueBufferRequestedSize);
    }
    
    OSStatus error = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    if (error != noErr) {
        NSLog(@"Error enqueuing buffer: %d", error);
    } else {
        //NSLog(@"Enqueued audioQueue buffer");
    }
}

@end
