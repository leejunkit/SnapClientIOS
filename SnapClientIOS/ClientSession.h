//
//  ClientSession.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 31/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClientSession : NSObject

- (instancetype)initWithSnapServerHost:(NSString *)host port:(NSUInteger)port;
- (void)start;

@end

NS_ASSUME_NONNULL_END
