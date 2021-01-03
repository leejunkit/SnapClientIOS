//
//  AudioRenderer.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer.h"
#import "StreamInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioRenderer : NSObject

- (instancetype)initWithStreamInfo:(StreamInfo *)info PCMCircularBuffer:(TPCircularBuffer *)circularBuffer;

@end

NS_ASSUME_NONNULL_END
