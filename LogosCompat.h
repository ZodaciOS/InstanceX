#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static inline Class IXClass(NSString *name) { return NSClassFromString(name); }
static inline id IXShared(Class cls, NSString *selector) {
    SEL s = NSSelectorFromString(selector);
    if (!cls) return nil;
    if ([cls respondsToSelector:s]) return ((id(*)(id,SEL))objc_msgSend)(cls,s);
    return nil;
}
static inline BOOL IXResponds(id obj, NSString *sel) { return obj && [obj respondsToSelector:NSSelectorFromString(sel)]; }
