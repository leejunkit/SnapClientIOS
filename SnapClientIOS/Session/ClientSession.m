//
//  ClientSession.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import "ClientSession.h"
#import "SocketHandler.h"
#import "FlacDecoder.h"
#import "AudioRenderer.h"

@interface ClientSession () <SocketHandlerDelegate, FlacDecoderDelegate>

@property (strong, nonatomic) SocketHandler *socketHandler;
@property (strong, nonatomic) FlacDecoder *flacDecoder;
@property (strong, nonatomic) AudioRenderer *audioRenderer;

@end

@implementation ClientSession

- (instancetype)initWithSnapServerHost:(NSString *)host port:(NSUInteger)port {
    if (self = [super init]) {
        self.socketHandler = [[SocketHandler alloc] initWithSnapServerHost:host port:port delegate:self];
    }
    return self;
}

- (void)start {
    
}

#pragma mark - SocketHandlerDelegate
- (void)socketHandler:(SocketHandler *)socketHandler didReceiveCodec:(NSString *)codec header:(NSData *)codecHeader {
    if ([codec isEqualToString:@"flac"]) {
        self.flacDecoder = [[FlacDecoder alloc] init];
        self.flacDecoder.delegate = self;
        self.flacDecoder.codecHeader = codecHeader;
        self.audioRenderer = [[AudioRenderer alloc] initWithStreamInfo:[self.flacDecoder getStreamInfo]];
    }
}

- (void)socketHandler:(SocketHandler *)socketHandler didReceiveAudioData:(NSData *)audioData {
    if (![self.flacDecoder feedAudioData:audioData]) {
        NSLog(@"Error feeding audio data to the decoder");
    }
}

#pragma mark - FlacDecoderDelegate
- (void)decoder:(FlacDecoder *)decoder didDecodePCMData:(NSData *)pcmData {
    [self.audioRenderer feedPCMData:pcmData];
}

@end
