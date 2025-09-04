#import <Foundation/Foundation.h>
#import <spawn.h>
#import "InstanceModel.h"
#import "LogosCompat.h"

@interface IXInstanceManager : NSObject
@property(nonatomic) NSMutableDictionary<NSString*, IXAppState*> *apps;
+ (instancetype)shared;
- (void)createInstancesForBundle:(NSString*)bundleID count:(NSUInteger)count;
- (void)addInstanceForBundle:(NSString*)bundleID;
- (void)handleProcessExitPid:(pid_t)pid;
@end

@implementation IXInstanceManager

+ (instancetype)shared { static IXInstanceManager *S; static dispatch_once_t once; dispatch_once(&once, ^{ S=[IXInstanceManager new]; S.apps=[NSMutableDictionary new]; }); return S; }

- (void)createInstancesForBundle:(NSString*)bundleID count:(NSUInteger)count {
    if (!bundleID) return;
    count = MIN(MAX(2, count), 4);
    IXAppState *state = self.apps[bundleID];
    if (!state) { state = [IXAppState new]; state.bundleID = bundleID; state.instances = [NSMutableArray new]; self.apps[bundleID] = state; }
    // terminate existing processes
    for (IXInstanceRecord *r in [state.instances copy]) {
        if (r.pid > 0) kill(r.pid, SIGKILL);
    }
    [state.instances removeAllObjects];
    for (NSUInteger i=0;i<count;i++) {
        IXInstanceRecord *rec = [self _launchInstanceForBundle:bundleID index:i];
        if (rec) [state.instances addObject:rec];
    }
    [self _applyLayoutForBundle:bundleID];
}

- (void)addInstanceForBundle:(NSString*)bundleID {
    IXAppState *state = self.apps[bundleID];
    if (!state) { state = [IXAppState new]; state.bundleID = bundleID; state.instances = [NSMutableArray new]; self.apps[bundleID] = state; }
    if (state.instances.count >= 4) return;
    IXInstanceRecord *rec = [self _launchInstanceForBundle:bundleID index:state.instances.count];
    if (rec) [state.instances addObject:rec];
    [self _applyLayoutForBundle:bundleID];
}

- (IXInstanceRecord*)_launchInstanceForBundle:(NSString*)bundleID index:(NSUInteger)index {
    // 1) Try FrontBoard multi-scene
    Class FBSSystemService = IXClass(@"FBSSystemService");
    if (FBSSystemService) {
        id svc = IXShared(FBSSystemService, @"sharedService");
        SEL sel = NSSelectorFromString(@"createAndActivateApplicationSceneWithBundleIdentifier:options:completion:");
        if (svc && [svc respondsToSelector:sel]) {
            IXInstanceRecord *rec = [IXInstanceRecord new];
            rec.bundleID = bundleID;
            rec.slotIndex = index;
            NSDictionary *opts = @{@"IXInstanceSlot": @(index)};
            void (^cb)(id) = ^(id info){
                if ([info isKindOfClass:NSDictionary.class]) {
                    id sid = info[@"sceneID"];
                    if ([sid isKindOfClass:NSString.class]) rec.sceneID = sid;
                    id pidv = info[@"pid"];
                    if (pidv) rec.pid = (pid_t)[pidv intValue];
                }
            };
            ((void(*)(id,SEL,NSString*,NSDictionary*,id))objc_msgSend)(svc, sel, bundleID, opts, cb);
            return rec;
        }
    }

    // 2) Fallback to container + posix_spawn
    ContainerManager *cm = [ContainerManager shared];
    NSString *cid = [cm createContainerForBundle:bundleID instanceIndex:index];
    if (!cid) return nil;

    // find executable path via LSApplicationProxy if available
    NSString *binaryPath = nil;
    Class LSApplicationProxy = IXClass(@"LSApplicationProxy");
    if (LSApplicationProxy && [LSApplicationProxy respondsToSelector:NSSelectorFromString(@"applicationProxyForIdentifier:")]) {
        id proxy = ((id(*)(id,SEL,NSString*))objc_msgSend)(LSApplicationProxy, NSSelectorFromString(@"applicationProxyForIdentifier:"), bundleID);
        if (proxy && [proxy respondsToSelector:NSSelectorFromString(@"bundleURL")]) {
            NSURL *url = ((id(*)(id,SEL))objc_msgSend)(proxy, NSSelectorFromString(@"bundleURL"));
            NSString *infoPath = [[url path] stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            NSString *exe = info[@"CFBundleExecutable"];
            if (exe) binaryPath = [[url path] stringByAppendingPathComponent:exe];
        }
    }

    if (!binaryPath || ![[NSFileManager defaultManager] fileExistsAtPath:binaryPath]) {
        // final fallback: open application normally
        Class LSWorkspace = IXClass(@"LSApplicationWorkspace");
        id ws = IXShared(LSWorkspace, @"defaultWorkspace");
        if (ws && [ws respondsToSelector:NSSelectorFromString(@"openApplicationWithBundleID:")]) {
            ((void(*)(id,SEL,NSString*))objc_msgSend)(ws, NSSelectorFromString(@"openApplicationWithBundleID:"), bundleID);
            return nil;
        }
        return nil;
    }

    // Prepare env
    extern char **environ;
    NSMutableDictionary *env = [NSMutableDictionary new];
    for (char **e = environ; *e; ++e) {
        NSString *s = [NSString stringWithUTF8String:*e];
        NSRange r = [s rangeOfString:@"="];
        if (r.location != NSNotFound) {
            NSString *k = [s substringToIndex:r.location];
            NSString *v = [s substringFromIndex:r.location+1];
            env[k] = v;
        }
    }
    if (![[ContainerManager shared] prepareLaunchEnvironmentForContainer:cid intoEnv:env]) return nil;

    // Convert env dict to char**
    NSUInteger n = env.count;
    char **envp = malloc((n+1) * sizeof(char*));
    NSUInteger i = 0;
    for (NSString *k in env) {
        NSString *v = env[k];
        NSString *pair = [NSString stringWithFormat:@"%@=%@", k, v];
        envp[i] = strdup([pair UTF8String]);
        i++;
    }
    envp[i] = NULL;

    // argv
    const char *path = [binaryPath fileSystemRepresentation];
    char *const argv[] = {(char *)path, NULL};
    pid_t pid = 0;
    int res = posix_spawn(&pid, path, NULL, NULL, argv, envp);
    for (NSUInteger j=0;j<i;j++) free(envp[j]);
    free(envp);

    if (res == 0 && pid > 0) {
        IXInstanceRecord *rec = [IXInstanceRecord new];
        rec.bundleID = bundleID;
        rec.containerID = cid;
        rec.pid = pid;
        rec.slotIndex = index;
        return rec;
    }
    return nil;
}

- (void)handleProcessExitPid:(pid_t)pid {
    for (IXAppState *st in self.apps.allValues) {
        NSUInteger idx = [st.instances indexOfObjectPassingTest:^BOOL(IXInstanceRecord * _Nonnull obj, NSUInteger i, BOOL * _Nonnull stop) {
            return obj.pid == pid;
        }];
        if (idx != NSNotFound) {
            [st.instances removeObjectAtIndex:idx];
            [self _applyLayoutForBundle:st.bundleID];
            break;
        }
    }
}

- (void)_applyLayoutForBundle:(NSString*)bundleID {
    IXAppState *st = self.apps[bundleID];
    if (!st) return;
    extern void IXApplyLayoutsForBundle(NSString*, NSArray*, IXLayoutMode);
    IXLayoutMode mode = (IXLayoutMode)MAX(2, (int)st.instances.count);
    IXApplyLayoutsForBundle(bundleID, st.instances, mode);
}

@end

IXInstanceManager *IXManager(void) {
    return [IXInstanceManager shared];
}
