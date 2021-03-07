//
//  StreamInfo.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamInfo : NSObject

@property (nonatomic, readonly) uint32_t sampleRate;
@property (nonatomic, readonly) uint16_t bitsPerSample;
@property (nonatomic, readonly) uint16_t channels;
@property (nonatomic, readonly) uint16_t sampleSize;
@property (nonatomic, readonly) uint16_t frameSize;

- (instancetype)initWithSampleRate:(uint32_t)rate bitsPerSample:(uint16_t)bits channels:(uint16_t)channels;

@end

NS_ASSUME_NONNULL_END
