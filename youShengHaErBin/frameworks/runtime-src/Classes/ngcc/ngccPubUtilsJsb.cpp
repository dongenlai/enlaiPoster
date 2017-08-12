#include "ngccPubUtilsJsb.hpp"
#include "cocos2d_specifics.hpp"
#include "ngccPubUtils.h"

template<class T>
static bool dummy_constructor(JSContext *cx, uint32_t argc, jsval *vp) {
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedValue initializing(cx);
    bool isNewValid = true;
    if (isNewValid)
    {
        TypeTest<T> t;
        js_type_class_t *typeClass = nullptr;
        std::string typeName = t.s_name();
        auto typeMapIter = _js_global_type_map.find(typeName);
        CCASSERT(typeMapIter != _js_global_type_map.end(), "Can't find the class type!");
        typeClass = typeMapIter->second;
        CCASSERT(typeClass, "The value is null.");

        JS::RootedObject proto(cx, typeClass->proto.get());
        JS::RootedObject parent(cx, typeClass->parentProto.get());
        JS::RootedObject _tmp(cx, JS_NewObject(cx, typeClass->jsclass, proto, parent));
        
        T* cobj = new T();
        js_proxy_t *pp = jsb_new_proxy(cobj, _tmp);
        AddObjectRoot(cx, &pp->obj);
        args.rval().set(OBJECT_TO_JSVAL(_tmp));
        return true;
    }

    return false;
}

static bool empty_constructor(JSContext *cx, uint32_t argc, jsval *vp) {
    return false;
}

static bool js_is_native_obj(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    args.rval().setBoolean(true);
    return true;    
}
JSClass  *jsb_ngcc_CSyncPubUtils_class;
JSObject *jsb_ngcc_CSyncPubUtils_prototype;

bool js_ngccPubUtilsJsb_CSyncPubUtils_getAnotherMoreComplexField(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_getAnotherMoreComplexField : Invalid Native Object");
    if (argc == 0) {
        const char* ret = cobj->getAnotherMoreComplexField();
        jsval jsret = JSVAL_NULL;
        jsret = c_string_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_getAnotherMoreComplexField : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_setSomeField(JSContext *cx, uint32_t argc, jsval *vp)
{
    bool ok = true;
    ngcc::CSyncPubUtils* cobj = nullptr;

    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx);
    obj = args.thisv().toObjectOrNull();
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : nullptr);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_setSomeField : Invalid Native Object");
    do {
        if (argc == 0) {
            cobj->setSomeField();
            args.rval().setUndefined();
            return true;
        }
    } while(0);

    do {
        if (argc == 1) {
            int arg0 = 0;
            ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
            if (!ok) { ok = true; break; }
            cobj->setSomeField(arg0);
            args.rval().setUndefined();
            return true;
        }
    } while(0);

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_setSomeField : wrong number of arguments");
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong : Invalid Native Object");
    if (argc == 1) {
        long long arg0 = 0;
        ok &= jsval_to_long_long(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong : Error processing arguments");
        long long ret = cobj->receivesLongLong(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = long_long_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_thisReturnsALongLong(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_thisReturnsALongLong : Invalid Native Object");
    if (argc == 0) {
        long long ret = cobj->thisReturnsALongLong();
        jsval jsret = JSVAL_NULL;
        jsret = long_long_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_thisReturnsALongLong : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_getObjectType(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_getObjectType : Invalid Native Object");
    if (argc == 0) {
        unsigned int ret = cobj->getObjectType();
        jsval jsret = JSVAL_NULL;
        jsret = uint32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_getObjectType : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField : Invalid Native Object");
    if (argc == 1) {
        const char* arg0 = nullptr;
        std::string arg0_tmp; ok &= jsval_to_std_string(cx, args.get(0), &arg0_tmp); arg0 = arg0_tmp.c_str();
        JSB_PRECONDITION2(ok, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField : Error processing arguments");
        cobj->setAnotherMoreComplexField(arg0);
        args.rval().setUndefined();
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField : Invalid Native Object");
    if (argc == 1) {
        int arg0 = 0;
        ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField : Error processing arguments");
        cobj->setSomeOtherField(arg0);
        args.rval().setUndefined();
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_getSomeOtherField(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_getSomeOtherField : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->getSomeOtherField();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_getSomeOtherField : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_returnsACString(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_returnsACString : Invalid Native Object");
    if (argc == 0) {
        const char* ret = cobj->returnsACString();
        jsval jsret = JSVAL_NULL;
        jsret = c_string_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_returnsACString : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing : Invalid Native Object");
    if (argc == 2) {
        std::string arg0;
        std::string arg1;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        ok &= jsval_to_std_string(cx, args.get(1), &arg1);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing : Error processing arguments");
        int ret = cobj->doSomeProcessing(arg0, arg1);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing : wrong number of arguments: %d, was expecting %d", argc, 2);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_getSomeField(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_getSomeField : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->getSomeField();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_getSomeField : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_returnsAString(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CSyncPubUtils* cobj = (ngcc::CSyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CSyncPubUtils_returnsAString : Invalid Native Object");
    if (argc == 0) {
        std::string ret = cobj->returnsAString();
        jsval jsret = JSVAL_NULL;
        jsret = std_string_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_returnsAString : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_func(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    
    do {
        if (argc == 1) {
            int arg0 = 0;
            ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
            if (!ok) { ok = true; break; }
            ngcc::CSyncPubUtils::func(arg0);
            return true;
        }
    } while (0);
    
    do {
        if (argc == 0) {
            ngcc::CSyncPubUtils::func();
            return true;
        }
    } while (0);
    
    do {
        if (argc == 2) {
            int arg0 = 0;
            ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
            if (!ok) { ok = true; break; }
            double arg1 = 0;
            ok &= JS::ToNumber( cx, args.get(1), &arg1) && !isnan(arg1);
            if (!ok) { ok = true; break; }
            ngcc::CSyncPubUtils::func(arg0, arg1);
            return true;
        }
    } while (0);
    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_func : wrong number of arguments");
    return false;
}
bool js_ngccPubUtilsJsb_CSyncPubUtils_constructor(JSContext *cx, uint32_t argc, jsval *vp)
{
    bool ok = true;
    ngcc::CSyncPubUtils* cobj = nullptr;

    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx);
    do {
        if (argc == 1) {
            int arg0 = 0;
            ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
            if (!ok) { ok = true; break; }
            cobj = new (std::nothrow) ngcc::CSyncPubUtils(arg0);

            TypeTest<ngcc::CSyncPubUtils> t;
            js_type_class_t *typeClass = nullptr;
            std::string typeName = t.s_name();
            auto typeMapIter = _js_global_type_map.find(typeName);
            CCASSERT(typeMapIter != _js_global_type_map.end(), "Can't find the class type!");
            typeClass = typeMapIter->second;
            CCASSERT(typeClass, "The value is null.");
            // obj = JS_NewObject(cx, typeClass->jsclass, typeClass->proto, typeClass->parentProto);
            JS::RootedObject proto(cx, typeClass->proto.get());
            JS::RootedObject parent(cx, typeClass->parentProto.get());
            obj = JS_NewObject(cx, typeClass->jsclass, proto, parent);

            js_proxy_t* p = jsb_new_proxy(cobj, obj);
        }
    } while(0);

    do {
        if (argc == 0) {
            cobj = new (std::nothrow) ngcc::CSyncPubUtils();

            TypeTest<ngcc::CSyncPubUtils> t;
            js_type_class_t *typeClass = nullptr;
            std::string typeName = t.s_name();
            auto typeMapIter = _js_global_type_map.find(typeName);
            CCASSERT(typeMapIter != _js_global_type_map.end(), "Can't find the class type!");
            typeClass = typeMapIter->second;
            CCASSERT(typeClass, "The value is null.");
            // obj = JS_NewObject(cx, typeClass->jsclass, typeClass->proto, typeClass->parentProto);
            JS::RootedObject proto(cx, typeClass->proto.get());
            JS::RootedObject parent(cx, typeClass->parentProto.get());
            obj = JS_NewObject(cx, typeClass->jsclass, proto, parent);

            js_proxy_t* p = jsb_new_proxy(cobj, obj);
        }
    } while(0);

    do {
        if (argc == 2) {
            int arg0 = 0;
            ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
            if (!ok) { ok = true; break; }
            int arg1 = 0;
            ok &= jsval_to_int32(cx, args.get(1), (int32_t *)&arg1);
            if (!ok) { ok = true; break; }
            cobj = new (std::nothrow) ngcc::CSyncPubUtils(arg0, arg1);

            TypeTest<ngcc::CSyncPubUtils> t;
            js_type_class_t *typeClass = nullptr;
            std::string typeName = t.s_name();
            auto typeMapIter = _js_global_type_map.find(typeName);
            CCASSERT(typeMapIter != _js_global_type_map.end(), "Can't find the class type!");
            typeClass = typeMapIter->second;
            CCASSERT(typeClass, "The value is null.");
            // obj = JS_NewObject(cx, typeClass->jsclass, typeClass->proto, typeClass->parentProto);
            JS::RootedObject proto(cx, typeClass->proto.get());
            JS::RootedObject parent(cx, typeClass->parentProto.get());
            obj = JS_NewObject(cx, typeClass->jsclass, proto, parent);

            js_proxy_t* p = jsb_new_proxy(cobj, obj);
        }
    } while(0);

    if (cobj) {
        if (JS_HasProperty(cx, obj, "_ctor", &ok) && ok)
                ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(obj), "_ctor", args);

        args.rval().set(OBJECT_TO_JSVAL(obj));
        return true;
    }
    JS_ReportError(cx, "js_ngccPubUtilsJsb_CSyncPubUtils_constructor : wrong number of arguments");
    return false;
}


void js_ngcc_CSyncPubUtils_finalize(JSFreeOp *fop, JSObject *obj) {
    CCLOGINFO("jsbindings: finalizing JS object %p (CSyncPubUtils)", obj);
    js_proxy_t* nproxy;
    js_proxy_t* jsproxy;
    jsproxy = jsb_get_js_proxy(obj);
    if (jsproxy) {
        ngcc::CSyncPubUtils *nobj = static_cast<ngcc::CSyncPubUtils *>(jsproxy->ptr);
        nproxy = jsb_get_native_proxy(jsproxy->ptr);

        if (nobj) {
            jsb_remove_proxy(nproxy, jsproxy);
            delete nobj;
        }
        else jsb_remove_proxy(nullptr, jsproxy);
    }
}
void js_register_ngccPubUtilsJsb_CSyncPubUtils(JSContext *cx, JS::HandleObject global) {
    jsb_ngcc_CSyncPubUtils_class = (JSClass *)calloc(1, sizeof(JSClass));
    jsb_ngcc_CSyncPubUtils_class->name = "CSyncPubUtils";
    jsb_ngcc_CSyncPubUtils_class->addProperty = JS_PropertyStub;
    jsb_ngcc_CSyncPubUtils_class->delProperty = JS_DeletePropertyStub;
    jsb_ngcc_CSyncPubUtils_class->getProperty = JS_PropertyStub;
    jsb_ngcc_CSyncPubUtils_class->setProperty = JS_StrictPropertyStub;
    jsb_ngcc_CSyncPubUtils_class->enumerate = JS_EnumerateStub;
    jsb_ngcc_CSyncPubUtils_class->resolve = JS_ResolveStub;
    jsb_ngcc_CSyncPubUtils_class->convert = JS_ConvertStub;
    jsb_ngcc_CSyncPubUtils_class->finalize = js_ngcc_CSyncPubUtils_finalize;
    jsb_ngcc_CSyncPubUtils_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

    static JSPropertySpec properties[] = {
        JS_PSG("__nativeObj", js_is_native_obj, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_PS_END
    };

    static JSFunctionSpec funcs[] = {
        JS_FN("getAnotherMoreComplexField", js_ngccPubUtilsJsb_CSyncPubUtils_getAnotherMoreComplexField, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setSomeField", js_ngccPubUtilsJsb_CSyncPubUtils_setSomeField, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("receivesLongLong", js_ngccPubUtilsJsb_CSyncPubUtils_receivesLongLong, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("thisReturnsALongLong", js_ngccPubUtilsJsb_CSyncPubUtils_thisReturnsALongLong, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("getObjectType", js_ngccPubUtilsJsb_CSyncPubUtils_getObjectType, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setAnotherMoreComplexField", js_ngccPubUtilsJsb_CSyncPubUtils_setAnotherMoreComplexField, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setSomeOtherField", js_ngccPubUtilsJsb_CSyncPubUtils_setSomeOtherField, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("getSomeOtherField", js_ngccPubUtilsJsb_CSyncPubUtils_getSomeOtherField, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("returnsACString", js_ngccPubUtilsJsb_CSyncPubUtils_returnsACString, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("doSomeProcessing", js_ngccPubUtilsJsb_CSyncPubUtils_doSomeProcessing, 2, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("getSomeField", js_ngccPubUtilsJsb_CSyncPubUtils_getSomeField, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("returnsAString", js_ngccPubUtilsJsb_CSyncPubUtils_returnsAString, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FS_END
    };

    static JSFunctionSpec st_funcs[] = {
        JS_FN("func", js_ngccPubUtilsJsb_CSyncPubUtils_func, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FS_END
    };

    jsb_ngcc_CSyncPubUtils_prototype = JS_InitClass(
        cx, global,
        JS::NullPtr(), // parent proto
        jsb_ngcc_CSyncPubUtils_class,
        js_ngccPubUtilsJsb_CSyncPubUtils_constructor, 0, // constructor
        properties,
        funcs,
        NULL, // no static properties
        st_funcs);
    // make the class enumerable in the registered namespace
//  bool found;
//FIXME: Removed in Firefox v27 
//  JS_SetPropertyAttributes(cx, global, "CSyncPubUtils", JSPROP_ENUMERATE | JSPROP_READONLY, &found);

    // add the proto and JSClass to the type->js info hash table
    TypeTest<ngcc::CSyncPubUtils> t;
    js_type_class_t *p;
    std::string typeName = t.s_name();
    if (_js_global_type_map.find(typeName) == _js_global_type_map.end())
    {
        p = (js_type_class_t *)malloc(sizeof(js_type_class_t));
        p->jsclass = jsb_ngcc_CSyncPubUtils_class;
        p->proto = jsb_ngcc_CSyncPubUtils_prototype;
        p->parentProto = NULL;
        _js_global_type_map.insert(std::make_pair(typeName, p));
    }
}

JSClass  *jsb_ngcc_CAsyncPubUtils_class;
JSObject *jsb_ngcc_CAsyncPubUtils_prototype;

bool js_ngccPubUtilsJsb_CAsyncPubUtils_getStatus(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CAsyncPubUtils* cobj = (ngcc::CAsyncPubUtils *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccPubUtilsJsb_CAsyncPubUtils_getStatus : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->getStatus();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccPubUtilsJsb_CAsyncPubUtils_getStatus : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccPubUtilsJsb_CAsyncPubUtils_constructor(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    ngcc::CAsyncPubUtils* cobj = new (std::nothrow) ngcc::CAsyncPubUtils();
    TypeTest<ngcc::CAsyncPubUtils> t;
    js_type_class_t *typeClass = nullptr;
    std::string typeName = t.s_name();
    auto typeMapIter = _js_global_type_map.find(typeName);
    CCASSERT(typeMapIter != _js_global_type_map.end(), "Can't find the class type!");
    typeClass = typeMapIter->second;
    CCASSERT(typeClass, "The value is null.");
    JS::RootedObject proto(cx, typeClass->proto.get());
    JS::RootedObject parent(cx, typeClass->parentProto.get());
    JS::RootedObject obj(cx, JS_NewObject(cx, typeClass->jsclass, proto, parent));
    args.rval().set(OBJECT_TO_JSVAL(obj));
    // link the native object with the javascript object
    js_proxy_t* p = jsb_new_proxy(cobj, obj);
    if (JS_HasProperty(cx, obj, "_ctor", &ok) && ok)
        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(obj), "_ctor", args);
    return true;
}

void js_ngcc_CAsyncPubUtils_finalize(JSFreeOp *fop, JSObject *obj) {
    CCLOGINFO("jsbindings: finalizing JS object %p (CAsyncPubUtils)", obj);
    js_proxy_t* nproxy;
    js_proxy_t* jsproxy;
    jsproxy = jsb_get_js_proxy(obj);
    if (jsproxy) {
        ngcc::CAsyncPubUtils *nobj = static_cast<ngcc::CAsyncPubUtils *>(jsproxy->ptr);
        nproxy = jsb_get_native_proxy(jsproxy->ptr);

        if (nobj) {
            jsb_remove_proxy(nproxy, jsproxy);
            delete nobj;
        }
        else jsb_remove_proxy(nullptr, jsproxy);
    }
}
void js_register_ngccPubUtilsJsb_CAsyncPubUtils(JSContext *cx, JS::HandleObject global) {
    jsb_ngcc_CAsyncPubUtils_class = (JSClass *)calloc(1, sizeof(JSClass));
    jsb_ngcc_CAsyncPubUtils_class->name = "CAsyncPubUtils";
    jsb_ngcc_CAsyncPubUtils_class->addProperty = JS_PropertyStub;
    jsb_ngcc_CAsyncPubUtils_class->delProperty = JS_DeletePropertyStub;
    jsb_ngcc_CAsyncPubUtils_class->getProperty = JS_PropertyStub;
    jsb_ngcc_CAsyncPubUtils_class->setProperty = JS_StrictPropertyStub;
    jsb_ngcc_CAsyncPubUtils_class->enumerate = JS_EnumerateStub;
    jsb_ngcc_CAsyncPubUtils_class->resolve = JS_ResolveStub;
    jsb_ngcc_CAsyncPubUtils_class->convert = JS_ConvertStub;
    jsb_ngcc_CAsyncPubUtils_class->finalize = js_ngcc_CAsyncPubUtils_finalize;
    jsb_ngcc_CAsyncPubUtils_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

    static JSPropertySpec properties[] = {
        JS_PSG("__nativeObj", js_is_native_obj, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_PS_END
    };

    static JSFunctionSpec funcs[] = {
        JS_FN("getStatus", js_ngccPubUtilsJsb_CAsyncPubUtils_getStatus, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FS_END
    };

    JSFunctionSpec *st_funcs = NULL;

    jsb_ngcc_CAsyncPubUtils_prototype = JS_InitClass(
        cx, global,
        JS::NullPtr(), // parent proto
        jsb_ngcc_CAsyncPubUtils_class,
        js_ngccPubUtilsJsb_CAsyncPubUtils_constructor, 0, // constructor
        properties,
        funcs,
        NULL, // no static properties
        st_funcs);
    // make the class enumerable in the registered namespace
//  bool found;
//FIXME: Removed in Firefox v27 
//  JS_SetPropertyAttributes(cx, global, "CAsyncPubUtils", JSPROP_ENUMERATE | JSPROP_READONLY, &found);

    // add the proto and JSClass to the type->js info hash table
    TypeTest<ngcc::CAsyncPubUtils> t;
    js_type_class_t *p;
    std::string typeName = t.s_name();
    if (_js_global_type_map.find(typeName) == _js_global_type_map.end())
    {
        p = (js_type_class_t *)malloc(sizeof(js_type_class_t));
        p->jsclass = jsb_ngcc_CAsyncPubUtils_class;
        p->proto = jsb_ngcc_CAsyncPubUtils_prototype;
        p->parentProto = NULL;
        _js_global_type_map.insert(std::make_pair(typeName, p));
    }
}

void register_all_ngccPubUtilsJsb(JSContext* cx, JS::HandleObject obj) {
    // Get the ns
    JS::RootedObject ns(cx);
    get_or_create_js_obj(cx, obj, "ngcc", &ns);

    js_register_ngccPubUtilsJsb_CAsyncPubUtils(cx, ns);
    js_register_ngccPubUtilsJsb_CSyncPubUtils(cx, ns);
}

