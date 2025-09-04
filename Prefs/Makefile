ARCHS = arm64 arm64e
TARGET := iphone:clang:15.0:15.0
THEOS_PACKAGE_SCHEME = rootless

BUNDLE_NAME = InstanceXPrefs
InstanceXPrefs_FILES = InstanceXPrefs.mm
InstanceXPrefs_INSTALL_PATH = /Library/PreferenceBundles
InstanceXPrefs_FRAMEWORKS = UIKit
InstanceXPrefs_PRIVATE_FRAMEWORKS = Preferences
InstanceXPrefs_CFLAGS = -fobjc-arc
InstanceXPrefs_RESOURCE_DIRS = Resources

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk
