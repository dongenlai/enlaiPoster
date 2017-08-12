#include "base/ccConfig.h"
#ifndef __ngccPubUtilsJsb_h__
#define __ngccPubUtilsJsb_h__

#include "jsapi.h"
#include "jsfriendapi.h"

extern JSClass  *jsb_ngcc_CSyncPubUtils_class;
extern JSObject *jsb_ngcc_CSyncPubUtils_prototype;

bool js_ngccPubUtilsJsb_CSyncPubUtils_constructor(JSContext *cx, uint32_t argc, jsval *vp);
void js_ngccPubUtilsJsb_CSyncPubUtils_finalize(JSContext *cx, JSObject *obj);
void js_register_ngccPubUtilsJsb_CSyncPubUtils(JSContext *cx, JS::HandleObject global);
void register_all_ngccPubUtilsJsb(JSContext* cx, JS::HandleObject obj);
bool js_ngccPubUtilsJsb_CSyncPubUtils_getAnotherMoreComplexField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_setSomeField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_thisReturnsALongLong(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_getObjectType(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_getSomeOtherField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_returnsACString(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_getSomeField(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_returnsAString(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_func(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CSyncPubUtils_CSyncPubUtils(JSContext *cx, uint32_t argc, jsval *vp);

extern JSClass  *jsb_ngcc_CAsyncPubUtils_class;
extern JSObject *jsb_ngcc_CAsyncPubUtils_prototype;

bool js_ngccPubUtilsJsb_CAsyncPubUtils_constructor(JSContext *cx, uint32_t argc, jsval *vp);
void js_ngccPubUtilsJsb_CAsyncPubUtils_finalize(JSContext *cx, JSObject *obj);
void js_register_ngccPubUtilsJsb_CAsyncPubUtils(JSContext *cx, JS::HandleObject global);
void register_all_ngccPubUtilsJsb(JSContext* cx, JS::HandleObject obj);
bool js_ngccPubUtilsJsb_CAsyncPubUtils_getStatus(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccPubUtilsJsb_CAsyncPubUtils_CAsyncPubUtils(JSContext *cx, uint32_t argc, jsval *vp);

#endif // __ngccPubUtilsJsb_h__
