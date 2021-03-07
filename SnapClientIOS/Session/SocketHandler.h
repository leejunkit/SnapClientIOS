//
//  SocketHandler.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SocketHandler;

@protocol SocketHandlerDelegate <NSObject>

- (void)socketHandler:(SocketHandler *)socketHandler didReceiveCodec:(NSString *)codec header:(NSData *)codecHeader;
- (void)socketHandler:(SocketHandler *)socketHandler didReceiveAudioData:(NSData *)audioData;

@end

@interface SocketHandler : NSObject

@property (readonly, weak, nonatomic) id<SocketHandlerDelegate> delegate;

- (instancetype)initWithSnapServerHost:(NSString *)host port:(NSUInteger)port delegate:(id<SocketHandlerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
