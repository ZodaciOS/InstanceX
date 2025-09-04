#import <UIKit/UIKit.h>
#import "InstanceModel.h"
#import "InstanceManager.mm"

extern IXInstanceManager *IXManager(void);

%hook SBIconView

- (NSArray *)applicationShortcutItems {
    NSArray *orig = %orig ?: @[];
    id icon = nil;
    @try { icon = [self valueForKey:@"_icon"]; } @catch(...) { icon = nil; }
    NSString *bundleID = nil;
    if (icon && [icon respondsToSelector:NSSelectorFromString(@"applicationBundleIdentifier")]) {
        bundleID = ((id(*)(id,SEL))objc_msgSend)(icon, NSSelectorFromString(@"applicationBundleIdentifier"));
    }
    if (!bundleID) return orig;

    UIMutableApplicationShortcutItem *i2 = [[UIMutableApplicationShortcutItem alloc] initWithType:[@"com.instancex.launch2:" stringByAppendingString:bundleID] localizedTitle:@"Launch 2 Instances"];
    UIMutableApplicationShortcutItem *i3 = [[UIMutableApplicationShortcutItem alloc] initWithType:[@"com.instancex.launch3:" stringByAppendingString:bundleID] localizedTitle:@"Launch 3 Instances"];
    UIMutableApplicationShortcutItem *i4 = [[UIMutableApplicationShortcutItem alloc] initWithType:[@"com.instancex.launch4:" stringByAppendingString:bundleID] localizedTitle:@"Launch 4 Instances"];
    UIMutableApplicationShortcutItem *add = [[UIMutableApplicationShortcutItem alloc] initWithType:[@"com.instancex.add:" stringByAppendingString:bundleID] localizedTitle:@"Add Instance"];

    return [orig arrayByAddingObjectsFromArray:@[i2,i3,i4,add]];
}

- (void)performActionForShortcutItem:(UIApplicationShortcutItem *)item fromSource:(id)source {
    NSString *t = item.type;
    NSRange r = [t rangeOfString:@":" options:NSBackwardsSearch];
    if (r.location != NSNotFound) {
        NSString *bid = [t substringFromIndex:r.location+1];
        if ([t hasPrefix:@"com.instancex.launch2:"]) { [IXManager() createInstancesForBundle:bid count:2]; return; }
        if ([t hasPrefix:@"com.instancex.launch3:"]) { [IXManager() createInstancesForBundle:bid count:3]; return; }
        if ([t hasPrefix:@"com.instancex.launch4:"]) { [IXManager() createInstancesForBundle:bid count:4]; return; }
        if ([t hasPrefix:@"com.instancex.add:"])    { [IXManager() addInstanceForBundle:bid]; return; }
    }
    %orig;
}

%end
