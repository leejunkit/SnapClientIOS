//
//  FlacDecoder.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import "FlacDecoder.h"
#include "FLACiOS/stream_decoder.h"
@import AVFoundation;

#define NUM_BUFFERS 3
#define BUFFER_SIZE 19200

@interface FlacDecoder () {
    dispatch_queue_t decoderQueue;
    TPCircularBuffer circularBuffer;
    FLAC__StreamDecoder *decoder;
    StreamInfo *streamInfo;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffers[NUM_BUFFERS];
}

@property (atomic) BOOL isDecoding;

@end

@implementation FlacDecoder

- (instancetype)init {
    if (self = [super init]) {
        decoderQueue = dispatch_queue_create("ljk.SnapClientIOS.decoderqueue", NULL);
        TPCircularBufferInit(&pcmCircularBuffer, 65536);
        TPCircularBufferInit(&circularBuffer, 8192);
        if ((decoder = FLAC__stream_decoder_new()) == NULL) {
            NSLog(@"Error allocating FLAC decoder!");
            @throw NSInternalInconsistencyException;
        }
    }
    return self;
}

- (StreamInfo *)getStreamInfo {
    return streamInfo;
}

- (void)setCodecHeader:(NSData *)codecHeader {
    _codecHeader = codecHeader;
    TPCircularBufferProduceBytes(&circularBuffer, [codecHeader bytes], (uint32_t)codecHeader.length);
    
    // attempt to initialize the decoder
    FLAC__StreamDecoderInitStatus init_status;
    init_status = FLAC__stream_decoder_init_stream(decoder, read_cb, NULL, NULL, NULL, NULL, write_cb, metadata_cb, error_cb, (__bridge void *)(self));
    if (init_status != FLAC__STREAM_DECODER_INIT_STATUS_OK) {
        const char * errorMessage = FLAC__StreamDecoderInitStatusString[init_status];
        NSLog(@"Error initializing decoder: %@", [[NSString alloc] initWithBytes:errorMessage length:sizeof(errorMessage) encoding:NSASCIIStringEncoding]);
        @throw NSInternalInconsistencyException;
    }
    
    // attempt to get the sample rate
    FLAC__stream_decoder_process_until_end_of_metadata(decoder);
}

- (BOOL)feedAudioData:(NSData *)audioData {
    if (&streamInfo == NULL) {
        NSLog(@"streamInfo is still NULL, ignoring the audio data for now");
        return NO;
    }
    
    if (!TPCircularBufferProduceBytes(&circularBuffer, [audioData bytes], (uint32_t)audioData.length)) {
        return NO;
    }
    
    if (!self.isDecoding) {
        self.isDecoding = YES;
        dispatch_async(decoderQueue, ^{
            [self decode];
        });
        self.isDecoding = NO;
    }
    
    return YES;
}

- (void)decode {
    uint32_t availableBytesFromCircularBuffer;
    TPCircularBufferTail(&circularBuffer, &availableBytesFromCircularBuffer);

    while (availableBytesFromCircularBuffer > 0) {
        if (!FLAC__stream_decoder_process_single(decoder)) {
            NSLog(@"Error occurred during decoding!");
            return;
        }
        TPCircularBufferTail(&circularBuffer, &availableBytesFromCircularBuffer);
    }
}

FLAC__StreamDecoderReadStatus read_cb(const FLAC__StreamDecoder *decoder, FLAC__byte buffer[], size_t *bytes, void *client_data) {
    FlacDecoder *THIS = (__bridge FlacDecoder *)client_data;
    
    uint32_t availableBytesFromCircularBuffer;
    SInt16 *circularBufferData = TPCircularBufferTail(&THIS->circularBuffer, &availableBytesFromCircularBuffer);

    if (availableBytesFromCircularBuffer > 0) {
        if (availableBytesFromCircularBuffer < *bytes) {
            // take everything from the circular buffer and fill the decoder's read buffer,
            // then modify the byte count accordingly
            memcpy(buffer, circularBufferData, availableBytesFromCircularBuffer);
            *bytes = availableBytesFromCircularBuffer;
            TPCircularBufferConsume(&THIS->circularBuffer, availableBytesFromCircularBuffer);
        } else {
            // we have more data in the circular buffer than what the decoder needs
            memcpy(buffer, circularBufferData, *bytes);
            TPCircularBufferConsume(&THIS->circularBuffer, (uint32_t) *bytes);
        }
        
        return FLAC__STREAM_DECODER_READ_STATUS_CONTINUE;
    }
    
    NSLog(@"Decoder read callback should not be called when there is nothing to decode!");
    return FLAC__STREAM_DECODER_READ_STATUS_ABORT;
}

FLAC__StreamDecoderWriteStatus write_cb(const FLAC__StreamDecoder *decoder, const FLAC__Frame *frame, const FLAC__int32 * const buffer[], void *client_data) {
    FlacDecoder *THIS = (__bridge FlacDecoder *)client_data;
    StreamInfo *streamInfo = THIS->streamInfo;
    
    // allocate a buffer
    size_t bytes = frame->header.blocksize * streamInfo.frameSize;
    int16_t * pcmBuffer = malloc(bytes);
    
    for (size_t channel = 0; channel < streamInfo.channels; ++channel) {
        if (streamInfo.sampleSize == 2) {
            for (size_t i = 0; i < frame->header.blocksize; i++) {
                pcmBuffer[streamInfo.channels * i + channel] = (int16_t)buffer[channel][i];
            }
        }
    }
    
    if (!TPCircularBufferProduceBytes(&THIS->pcmCircularBuffer, pcmBuffer, (uint32_t)bytes)) {
        NSLog(@"Error inserting PCM frames into the PCM circular buffer!");
    } else {
        //NSLog(@"Inserted PCM frames");
    }
    
    free(pcmBuffer);
    
    return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

void metadata_cb(const FLAC__StreamDecoder *decoder, const FLAC__StreamMetadata *metadata, void *client_data) {
    if (metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {
        FLAC__StreamMetadata_StreamInfo si = metadata->data.stream_info;
        
        StreamInfo *info = [[StreamInfo alloc] initWithSampleRate:si.sample_rate bitsPerSample:si.bits_per_sample channels:si.channels];
        NSLog(@"%@", [info debugDescription]);
        
        FlacDecoder *THIS = (__bridge FlacDecoder *)client_data;
        THIS->streamInfo = info;
    }
}

void error_cb(const FLAC__StreamDecoder *decoder, FLAC__StreamDecoderErrorStatus status, void *client_data) {
    NSLog(@"Got error callback, %@", status);
}

/*
- (void)initAudioQueue {
    AudioStreamBasicDescription format;
    format.mSampleRate = streamInfo.sampleRate;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    format.mBitsPerChannel = streamInfo.bitsPerSample;
    format.mChannelsPerFrame = streamInfo.channels;
    format.mBytesPerFrame = streamInfo.frameSize;
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
    FlacDecoder *THIS = (__bridge FlacDecoder *)inUserData;
    
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
 */
@end
