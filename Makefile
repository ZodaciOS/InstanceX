include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = InstanceX
InstanceX_FILES = \
	Tweak.xm \
	lib/IXContainerManager.mm \
	lib/IXKeychainManager.mm \
	lib/IXLayoutManager.mm

InstanceX_CFLAGS = -fobjc-arc
InstanceX_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
