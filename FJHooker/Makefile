TARGET := iphone:clang:13.1:7.1

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = FJHooker

FJHooker_FILES = FJHooker.m fishhook/fishhook.c FJHPattern.m
FJHooker_PUBLIC_HEADERS = FJHooker.h
FJHooker_INSTALL_PATH = /Library/Frameworks
FJHooker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/framework.mk
