ARCHS = arm64 arm64e
TARGET := iphone:clang:15.0:15.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = InstanceX
InstanceX_FILES = Tweak.xm SBMenuHooks.xm InstanceManager.mm ContainerManager.mm InstanceLayout.mm
InstanceX_CFLAGS = -fobjc-arc
InstanceX_LDFLAGS += -Wl,-undefined,dynamic_lookup
InstanceX_PRIVATE_FRAMEWORKS = FrontBoardServices BackBoardServices SpringBoardServices
InstanceX_FRAMEWORKS = UIKit Foundation
InstanceX_LIBRARIES = objc

SUBPROJECTS += prefs ContainerShim
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
