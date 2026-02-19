# EverLight v2.0 — Theos Makefile
# Compatible with Sideloadly

TARGET := iphone:clang:latest:13.0
ARCHS := arm64 arm64e
DEBUG := 0
GO_EASY_ON_ME := 1

# Tweak name
TWEAK_NAME = EverLight

# Source files
EverLight_FILES = Tweak.mm

# Frameworks
EverLight_FRAMEWORKS = UIKit QuartzCore Foundation
EverLight_PRIVATE_FRAMEWORKS = 

# Libraries
EverLight_LIBRARIES = substrate

# Compiler flags
EverLight_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
EverLight_LDFLAGS = -Wl,-segalign,4000

# Bundle identifier
EverLight_BUNDLE_IDENTIFIER = com.everlight.tweak

# Installation path
EverLight_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# Post-install actions
after-install::
	install.exec "killall -9 SpringBoard || true"

# Clean
clean::
	rm -rf .theos obj packages
