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
        [self decode];
    }
    
    return YES;
}

- (void)decode {
    if (self.isDecoding) return;
    
    dispatch_async(decoderQueue, ^{
        self.isDecoding = YES;
        
        uint32_t availableBytesFromCircularBuffer;
        TPCircularBufferTail(&self->circularBuffer, &availableBytesFromCircularBuffer);

        while (availableBytesFromCircularBuffer > 0) {
            if (!FLAC__stream_decoder_process_single(self->decoder)) {
                NSLog(@"Error occurred during decoding!");
                self.isDecoding = NO;
                return;
            }
            TPCircularBufferTail(&self->circularBuffer, &availableBytesFromCircularBuffer);
        }
        
        self.isDecoding = NO;
    });
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
    
    NSData *pcmData = [NSData dataWithBytes:pcmBuffer length:(NSUInteger)bytes];
    free(pcmBuffer);
    
    [THIS.delegate decoder:THIS didDecodePCMData:pcmData];
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

@end
