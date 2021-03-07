//
//  PersistentContainer.m
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 7/3/21.
//

#import "PersistentContainer.h"

@implementation PersistentContainer

- (NSArray *)servers {
    NSFetchRequest *fetchReq = [NSFetchRequest fetchRequestWithEntityName:@"Server"];
    
    NSError *error = nil;
    NSArray *servers = [self.viewContext executeFetchRequest:fetchReq error:&error];
    if (error) {
        NSLog(@"CoreData error: %@", error);
        @throw NSInternalInconsistencyException;
    }
    
    return servers;
}

- (void)addServerWithName:(NSString *)name host:(NSString *)host port:(NSUInteger)port {
    NSManagedObjectContext *moc = [self newBackgroundContext];
    [moc performBlock:^{
        NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:moc];
        [obj setValue:name forKey:@"name"];
        [obj setValue:host forKey:@"host"];
        [obj setValue:@(port) forKey:@"port"];
        
        NSError *error = nil;
        [moc save:&error];
        if (error) {
            NSLog(@"CoreData error: %@", error);
        }
    }];
}

@end
