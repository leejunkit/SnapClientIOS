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

@interface FlacDecoder : NSObject {
    @public TPCircularBuffer pcmCircularBuffer;
}

@property (copy, nonatomic) NSData *codecHeader;

- (BOOL)feedAudioData:(NSData *)audioData;
- (StreamInfo *)getStreamInfo;

@end

NS_ASSUME_NONNULL_END
