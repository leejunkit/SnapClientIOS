//
//  AppDelegate.h
//  SnapClientIOS
//
//  Created by Lee Jun Kit on 29/12/20.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersistentContainer.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PersistentContainer *persistentContainer;

@end

