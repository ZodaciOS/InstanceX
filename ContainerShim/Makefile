ARCHS = arm64 arm64e
TARGET := iphone:clang:15.0:15.0
THEOS_PACKAGE_SCHEME = rootless

LIBRARY_NAME = instancex_container_shim
instancex_container_shim_FILES = ContainerShim.c KeychainShim.c
instancex_container_shim_CFLAGS = -fno-objc-arc
instancex_container_shim_LDFLAGS = -Wl,-undefined,dynamic_lookup
instancex_container_shim_INSTALL_PATH = /usr/lib
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/library.mk
