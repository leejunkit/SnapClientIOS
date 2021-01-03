//
//  SocketHandler.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import "SocketHandler.h"
#import <GCDAsyncSocket.h>

typedef enum : uint16_t {
    MESSAGE_TYPE_BASE = 0,
    MESSAGE_TYPE_CODEC_HEADER = 1,
    MESSAGE_TYPE_WIRE_CHUNK = 2,
    MESSAGE_TYPE_SERVER_SETTINGS = 3,
    MESSAGE_TYPE_TIME = 4,
    MESSAGE_TYPE_HELLO = 5,
    MESSAGE_TYPE_STREAM_TAGS = 6,
} SnapCastMessageType;

@interface SocketHandler () <GCDAsyncSocketDelegate> {
    dispatch_queue_t queue;
}

@property (nonatomic, copy) NSString *serverHost;
@property (nonatomic) NSUInteger serverPort;
@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation SocketHandler

- (instancetype)initWithSnapServerHost:(NSString *)host port:(NSUInteger)port delegate:(id<SocketHandlerDelegate>)delegate {
    if (self = [super init]) {
        self.serverHost = host;
        self.serverPort = port;
        _delegate = delegate;
        
        queue = dispatch_queue_create("ljk.snapclientios.socketqueue", NULL);
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:queue];
        [self start];
    }
    
    return self;
}

- (void)start {
    NSError *err = nil;
    if (![self.socket connectToHost:self.serverHost onPort:self.serverPort error:&err]) {
        NSLog(@"I goofed: %@", err);
    }
    
    NSMutableData *base = [self baseMessage];
    
    // generate and send the Hello message
    NSDictionary *helloMessage = @{
        @"Arch": @"x86_64",
        @"ClientName": @"SnapClientIOS",
        @"HostName": @"MyHostname",
        @"ID": @"00:11:22:33:44:55",
        @"Instance": @1,
        @"MAC": @"00:11:22:33:44:55",
        @"OS": @"Arch Linux",
        @"SnapStreamProtocolVersion": @2,
        @"Version": @"0.17.1"
    };
    
    NSData *helloJSONData = [NSJSONSerialization dataWithJSONObject:helloMessage
                                                            options:0
                                                              error:nil];
    uint32_t helloJSONLength = (uint32_t)[helloJSONData length];
    NSMutableData *helloData = [[NSMutableData alloc] init];
    [helloData appendBytes:&helloJSONLength length:sizeof(uint32_t)];
    [helloData appendData:helloJSONData];
    
    uint32_t sizeOfHelloTypedMessage = (uint32_t)[helloData length];
    [base appendBytes:&sizeOfHelloTypedMessage length:sizeof(uint32_t)];
    [base appendData:helloData];
    
    [self.socket writeData:base withTimeout:-1 tag:1];
    
    // read the Server Settings message
    [self readNextMessage:self.socket];
}

- (NSMutableData *)baseMessage {
    NSMutableData *base = [[NSMutableData alloc] init];
    uint16_t type = 5;
    uint16_t idField = 0;
    uint16_t refersToField = 0;
    int32_t serverReceivedSeconds = 0;
    int32_t serverReceivedMicroseconds = 0;
    
    NSTimeInterval sentTimestamp = [[NSDate date] timeIntervalSince1970];
    int32_t clientSentSeconds = (int32_t)sentTimestamp;
    int32_t clientSentMicroseconds = (int32_t)((sentTimestamp - clientSentSeconds) * 1000000);
    
    NSLog(@"sentTimestamp: %@", [NSNumber numberWithDouble:sentTimestamp]);
    NSLog(@"clientSentSeconds: %d", clientSentSeconds);
    NSLog(@"clientSentMicroseconds: %d", clientSentMicroseconds);
    
    [base appendBytes:&type length:sizeof(uint16_t)];
    [base appendBytes:&idField length:sizeof(uint16_t)];
    [base appendBytes:&refersToField length:sizeof(uint16_t)];
    [base appendBytes:&serverReceivedSeconds length:sizeof(int32_t)];
    [base appendBytes:&serverReceivedMicroseconds length:sizeof(int32_t)];
    [base appendBytes:&clientSentSeconds length:sizeof(int32_t)];
    [base appendBytes:&clientSentMicroseconds length:sizeof(int32_t)];

    return base;
}

- (void)readNextMessage:(GCDAsyncSocket *)socket {
    NSUInteger baseMessageLength = sizeof(uint16_t) + sizeof(uint16_t) + sizeof(uint16_t) + sizeof(int32_t) + sizeof(int32_t) + sizeof(int32_t) + sizeof(int32_t) + sizeof(uint32_t);
    [socket readDataToLength:baseMessageLength withTimeout:-1 tag:MESSAGE_TYPE_BASE];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == MESSAGE_TYPE_BASE) {
        // determine the message type
        uint16_t messageType;
        [data getBytes:&messageType length:sizeof(uint16_t)];
        
        //NSLog(@"BASE_MESSAGE: Reeived message of type %d", messageType);
        
        // advance to the field storing the length of the typed message
        NSUInteger lengthToAdvance = sizeof(uint16_t) + sizeof(uint16_t) + sizeof(uint16_t) + sizeof(int32_t) + sizeof(int32_t) + sizeof(int32_t) + sizeof(int32_t);
        
        // determine the length of the typed message
        uint32_t typedMessageLength;
        [data getBytes:&typedMessageLength range:NSMakeRange(lengthToAdvance, sizeof(uint32_t))];
        
        // read the typed message
        @try {
            [sock readDataToLength:typedMessageLength withTimeout:-1 tag:messageType];
        } @catch (NSException *exception) {
            NSLog(@"Exception thrown: %@", exception);
            [sock readDataToLength:typedMessageLength withTimeout:-1 tag:messageType];
        } @finally {
            
        }
        return;
    }
    
    if (tag == MESSAGE_TYPE_WIRE_CHUNK) {
        // get the payload size
        uint32_t payloadSize;
        [data getBytes:&payloadSize range:NSMakeRange(sizeof(int32_t) + sizeof(int32_t), sizeof(uint32_t))];
        
        NSData *payload = [data subdataWithRange:NSMakeRange(sizeof(int32_t) + sizeof(int32_t) + sizeof(uint32_t), payloadSize)];
        [self handleWireChunkPayload:payload];
    }
    
    if (tag == MESSAGE_TYPE_SERVER_SETTINGS) {
        uint32_t serverSettingsJSONLength;
        [data getBytes:&serverSettingsJSONLength length:sizeof(uint32_t)];
        
        NSData *payload = [data subdataWithRange:NSMakeRange(sizeof(uint32_t), serverSettingsJSONLength)];
        [self handleServerSettingsJSONPayload:payload];
    }
    
    if (tag == MESSAGE_TYPE_STREAM_TAGS) {
        uint32_t streamTagsJSONLength;
        [data getBytes:&streamTagsJSONLength length:sizeof(uint32_t)];
        
        NSData *payload = [data subdataWithRange:NSMakeRange(sizeof(uint32_t), streamTagsJSONLength)];
        [self handleStreamTagsJSONPayload:payload];
    }
    
    if (tag == MESSAGE_TYPE_CODEC_HEADER) {
        [self handleCodecHeaderPayload:data];
    }
    
    if (tag == MESSAGE_TYPE_TIME) {
        [self handleTimePayload:data];
    }
    
    // read the next message
    [self readNextMessage:sock];
}

- (void)handleWireChunkPayload:(NSData *)payload {
    [self.delegate socketHandler:self didReceiveAudioData:payload];
}

- (void)handleServerSettingsJSONPayload:(NSData *)payload {
    NSError *error = nil;
    NSDictionary *serverSettings = [NSJSONSerialization JSONObjectWithData:payload options:0 error:&error];
    if (error) {
        NSLog(@"Error deserializing ServerSettings: %@", error);
    } else {
        NSLog(@"ServerSettings: %@", serverSettings);
    }
}

- (void)handleStreamTagsJSONPayload:(NSData *)payload {
    NSError *error = nil;
    //NSDictionary *streamTags = [NSJSONSerialization JSONObjectWithData:payload options:0 error:&error];
    if (error) {
        NSLog(@"Error deserializing StreamTags: %@", error);
    } else {
        NSLog(@"StreamTags: (snipped)");
    }
}

- (void)handleCodecHeaderPayload:(NSData *)data {
    uint32_t codecSize;
    [data getBytes:&codecSize range:NSMakeRange(0, sizeof(uint32_t))];
    
    char codec[codecSize];
    [data getBytes:codec range:NSMakeRange(sizeof(uint32_t), codecSize)];
    
    uint32_t payloadSize;
    [data getBytes:&payloadSize range:NSMakeRange(sizeof(uint32_t) + codecSize, sizeof(uint32_t))];
    
    char payload[payloadSize];
    [data getBytes:payload range:NSMakeRange(sizeof(uint32_t) + codecSize + sizeof(uint32_t), payloadSize)];
    
    NSString *codecString = [[NSString alloc] initWithBytes:codec length:codecSize encoding:NSASCIIStringEncoding];
    if ([codecString isEqualToString:@"flac"]) {
        [self.delegate socketHandler:self didReceiveCodec:codecString header:[NSData dataWithBytes:payload length:payloadSize]];
    }
}

- (void)handleTimePayload:(NSData *)data {
    NSLog(@"Time: (snipped)");
}

@end
