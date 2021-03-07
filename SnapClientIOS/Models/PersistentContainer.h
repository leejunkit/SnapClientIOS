//
//  PersistentContainer.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 7/3/21.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface PersistentContainer : NSPersistentContainer

- (NSArray *)servers;
- (void)addServerWithName:(NSString *)name host:(NSString *)host port:(NSUInteger)port;

@end

NS_ASSUME_NONNULL_END
