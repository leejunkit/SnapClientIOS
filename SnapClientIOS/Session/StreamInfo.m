//
//  StreamInfo.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import "StreamInfo.h"

@interface StreamInfo ()

@property (nonatomic) uint32_t sampleRate;
@property (nonatomic) uint16_t bitsPerSample;
@property (nonatomic) uint16_t channels;
@property (nonatomic) uint16_t sampleSize;
@property (nonatomic) uint16_t frameSize;

@end

@implementation StreamInfo

- (instancetype)initWithSampleRate:(uint32_t)rate bitsPerSample:(uint16_t)bits channels:(uint16_t)channels {
    if (self = [super init]) {
        self.sampleRate = rate;
        self.bitsPerSample = bits;
        self.channels = channels;
        if (self.bitsPerSample == 24) {
            self.sampleSize = 4;
        } else {
            self.sampleSize = self.bitsPerSample / 8;
        }
        self.frameSize = self.channels * self.sampleSize;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"StreamInfo: sampleRate=%d bitsPerSample=%d channels=%d sampleSize=%d frameSize=%d", self.sampleRate, self.bitsPerSample, self.channels, self.sampleSize, self.frameSize];
}

@end
