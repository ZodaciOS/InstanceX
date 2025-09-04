#import <UIKit/UIKit.h>
#import "LogosCompat.h"

// simple ctor to allow early enable-check gating if needed
%ctor {
    // nothing here; InstanceManager will check prefs when invoked
}
