#import <UIKit/UIKit.h>
#import "InstanceModel.h"

static CGRect slotFrameForMode(IXLayoutMode mode, NSUInteger slotIdx, CGSize s) {
    CGFloat w = s.width, h = s.height;
    if (mode == IXLayoutModeTwo) {
        CGFloat halfW = w/2.0;
        return CGRectMake(slotIdx==0?0:halfW, 0, halfW, h);
    } else if (mode == IXLayoutModeThree) {
        CGFloat halfW = w/2.0;
        if (slotIdx == 2) return CGRectMake(halfW, 0, halfW, h);
        CGFloat halfH = h/2.0;
        return CGRectMake(0, slotIdx==0?0:halfH, halfW, halfH);
    } else {
        CGFloat halfW = w/2.0, halfH = h/2.0;
        if (slotIdx == 0) return CGRectMake(0,0,halfW,halfH);
        if (slotIdx == 1) return CGRectMake(halfW,0,halfW,halfH);
        if (slotIdx == 2) return CGRectMake(0,halfH,halfW,halfH);
        return CGRectMake(halfW,halfH,halfW,halfH);
    }
}

static NSArray<UIWindow*> *windowsForBundle(NSString *bundleID) {
    NSMutableArray *out = [NSMutableArray new];
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.windowScene) {
            NSString *pid = w.windowScene.session.persistentIdentifier ?: @"";
            if ([pid containsString:bundleID] || (w.accessibilityIdentifier && [w.accessibilityIdentifier containsString:bundleID])) {
                [out addObject:w];
            }
        }
    }
    return out;
}

void IXApplyLayoutsForBundle(NSString *bundleID, NSArray *instances, IXLayoutMode mode) {
    CGSize screen = UIScreen.mainScreen.bounds.size;
    NSArray *wins = windowsForBundle(bundleID);
    for (NSUInteger i=0;i<instances.count;i++) {
        CGRect f = slotFrameForMode(mode, i, screen);
        UIWindow *w = (i < wins.count) ? wins[i] : nil;
        if (w) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.15 animations:^{
                    w.frame = f;
                }];
            });
        }
    }
}
