LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_SRC_FILES := fsmlex.l fsmparse.y
LOCAL_CFLAGS := -g -O0
LOCAL_YACCFLAGS := -v
LOCAL_MODULE := fsmparse

include $(BUILD_HOST_EXECUTABLE)
