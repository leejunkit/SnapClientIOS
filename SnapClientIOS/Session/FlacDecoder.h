//
//  FlacDecoder.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer.h"
#import "StreamInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class FlacDecoder;

@protocol FlacDecoderDelegate <NSObject>

- (void)decoder:(FlacDecoder *)decoder didDecodePCMData:(NSData *)pcmData;

@end

@interface FlacDecoder : NSObject

@property (nonatomic, weak) id<FlacDecoderDelegate> delegate;
@property (copy, nonatomic) NSData *codecHeader;

- (BOOL)feedAudioData:(NSData *)audioData;
- (StreamInfo *)getStreamInfo;

@end

NS_ASSUME_NONNULL_END
