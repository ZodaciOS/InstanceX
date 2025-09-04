#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IXLayoutMode) {
    IXLayoutModeTwo = 2,
    IXLayoutModeThree = 3,
    IXLayoutModeFour = 4
};

@interface IXInstanceRecord : NSObject <NSSecureCoding>
@property(nonatomic, copy) NSString *bundleID;
@property(nonatomic, copy) NSString *containerID; // container identifier used by shim
@property(nonatomic, copy) NSString *sceneID;
@property(nonatomic) pid_t pid;
@property(nonatomic) NSUInteger slotIndex;
@end

@interface IXAppState : NSObject
@property(nonatomic, copy) NSString *bundleID;
@property(nonatomic) NSMutableArray<IXInstanceRecord*> *instances;
@end
