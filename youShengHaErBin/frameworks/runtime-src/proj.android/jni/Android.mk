LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := fmodex
LOCAL_SRC_FILES := ../jars/$(TARGET_ARCH_ABI)/libfmodex.so
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/../../Classes/ngcc/inc
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := cocos2djs_shared

LOCAL_MODULE_FILENAME := libcocos2djs

LOCAL_ARM_MODE := arm

LOCAL_SRC_FILES := \
../../Classes/ngcc/ngccAudio.cpp \
../../Classes/ngcc/ngccAudioJsb.cpp \
../../Classes/ngcc/ngccPubUtils.cpp \
../../Classes/ngcc/ngccPubUtilsJsb.cpp \
../../Classes/ngcc/ngccWebSocket.cpp \
../../Classes/ngcc/ngccWebSocketJsb.cpp \
../../Classes/ngcc/ngccGameDownload.cpp \
../../Classes/ngcc/ngccGameDownloadJsb.cpp \
../../Classes/AppDelegate.cpp \
../../Classes/ide-support/SimpleConfigParser.cpp \
../../Classes/ide-support/RuntimeJsImpl.cpp \
hellojavascript/main.cpp

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../Classes 

LOCAL_STATIC_LIBRARIES := cocos2d_js_static
LOCAL_STATIC_LIBRARIES += cocos2d_simulator_static

LOCAL_SHARED_LIBRARIES := fmodex
include $(BUILD_SHARED_LIBRARY)


$(call import-module,scripting/js-bindings/proj.android/prebuilt-mk)
$(call import-module,tools/simulator/libsimulator/proj.android/prebuilt-mk)
