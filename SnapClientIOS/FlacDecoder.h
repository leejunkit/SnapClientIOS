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
}

@property (copy, nonatomic) NSData *codecHeader;
- (BOOL)feedAudioData:(NSData *)audioData;
- (void)initAudioQueue;

@end

NS_ASSUME_NONNULL_END
