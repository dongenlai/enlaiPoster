#include "ngccAudioJsb.hpp"
#include "cocos2d_specifics.hpp"
#include "ngccAudio.h"

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
JSClass  *jsb_ngcc_CNgcAudio_class;
JSObject *jsb_ngcc_CNgcAudio_prototype;

bool js_ngccAudioJsb_CNgcAudio_cacheGameSound(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_cacheGameSound : Invalid Native Object");
    if (argc == 1) {
        std::string arg0;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_cacheGameSound : Error processing arguments");
        int ret = cobj->cacheGameSound(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_cacheGameSound : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_removeGameSound(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_removeGameSound : Invalid Native Object");
    if (argc == 1) {
        std::string arg0;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_removeGameSound : Error processing arguments");
        int ret = cobj->removeGameSound(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_removeGameSound : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_playBackMusic(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_playBackMusic : Invalid Native Object");
    if (argc == 1) {
        std::string arg0;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_playBackMusic : Error processing arguments");
        int ret = cobj->playBackMusic(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_playBackMusic : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_playGameSound(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_playGameSound : Invalid Native Object");
    if (argc == 1) {
        std::string arg0;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_playGameSound : Error processing arguments");
        int ret = cobj->playGameSound(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_playGameSound : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_mayRecord(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_mayRecord : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->mayRecord();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_mayRecord : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic : Invalid Native Object");
    if (argc == 1) {
        double arg0 = 0;
        ok &= JS::ToNumber( cx, args.get(0), &arg0) && !isnan(arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic : Error processing arguments");
        int ret = cobj->setVolumeBackMusic(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_update(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_update : Invalid Native Object");
    if (argc == 0) {
        cobj->update();
        args.rval().setUndefined();
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_update : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_endRecord(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_endRecord : Invalid Native Object");
    if (argc == 0) {
        std::string ret = cobj->endRecord();
        jsval jsret = JSVAL_NULL;
        jsret = std_string_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_endRecord : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_playVoice(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_playVoice : Invalid Native Object");
    if (argc == 1) {
        std::string arg0;
        ok &= jsval_to_std_string(cx, args.get(0), &arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_playVoice : Error processing arguments");
        int ret = cobj->playVoice(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_playVoice : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_setVolumeVoice(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeVoice : Invalid Native Object");
    if (argc == 1) {
        double arg0 = 0;
        ok &= JS::ToNumber( cx, args.get(0), &arg0) && !isnan(arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeVoice : Error processing arguments");
        int ret = cobj->setVolumeVoice(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_setVolumeVoice : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_isRecording(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_isRecording : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->isRecording();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_isRecording : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_removeBackMusic(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_removeBackMusic : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->removeBackMusic();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_removeBackMusic : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_startRecord(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_startRecord : Invalid Native Object");
    if (argc == 0) {
        int ret = cobj->startRecord();
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_startRecord : wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_setVolumeGame(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeGame : Invalid Native Object");
    if (argc == 1) {
        double arg0 = 0;
        ok &= JS::ToNumber( cx, args.get(0), &arg0) && !isnan(arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_setVolumeGame : Error processing arguments");
        int ret = cobj->setVolumeGame(arg0);
        jsval jsret = JSVAL_NULL;
        jsret = int32_to_jsval(cx, ret);
        args.rval().set(jsret);
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_setVolumeGame : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_setPaused(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    JS::RootedObject obj(cx, args.thisv().toObjectOrNull());
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcAudio* cobj = (ngcc::CNgcAudio *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2( cobj, cx, false, "js_ngccAudioJsb_CNgcAudio_setPaused : Invalid Native Object");
    if (argc == 1) {
        int arg0 = 0;
        ok &= jsval_to_int32(cx, args.get(0), (int32_t *)&arg0);
        JSB_PRECONDITION2(ok, cx, false, "js_ngccAudioJsb_CNgcAudio_setPaused : Error processing arguments");
        cobj->setPaused(arg0);
        args.rval().setUndefined();
        return true;
    }

    JS_ReportError(cx, "js_ngccAudioJsb_CNgcAudio_setPaused : wrong number of arguments: %d, was expecting %d", argc, 1);
    return false;
}
bool js_ngccAudioJsb_CNgcAudio_constructor(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    bool ok = true;
    ngcc::CNgcAudio* cobj = new (std::nothrow) ngcc::CNgcAudio();
    TypeTest<ngcc::CNgcAudio> t;
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

void js_ngcc_CNgcAudio_finalize(JSFreeOp *fop, JSObject *obj) {
    CCLOGINFO("jsbindings: finalizing JS object %p (CNgcAudio)", obj);
    js_proxy_t* nproxy;
    js_proxy_t* jsproxy;
    jsproxy = jsb_get_js_proxy(obj);
    if (jsproxy) {
        ngcc::CNgcAudio *nobj = static_cast<ngcc::CNgcAudio *>(jsproxy->ptr);
        nproxy = jsb_get_native_proxy(jsproxy->ptr);

        if (nobj) {
            jsb_remove_proxy(nproxy, jsproxy);
            delete nobj;
        }
        else jsb_remove_proxy(nullptr, jsproxy);
    }
}
void js_register_ngccAudioJsb_CNgcAudio(JSContext *cx, JS::HandleObject global) {
    jsb_ngcc_CNgcAudio_class = (JSClass *)calloc(1, sizeof(JSClass));
    jsb_ngcc_CNgcAudio_class->name = "CNgcAudio";
    jsb_ngcc_CNgcAudio_class->addProperty = JS_PropertyStub;
    jsb_ngcc_CNgcAudio_class->delProperty = JS_DeletePropertyStub;
    jsb_ngcc_CNgcAudio_class->getProperty = JS_PropertyStub;
    jsb_ngcc_CNgcAudio_class->setProperty = JS_StrictPropertyStub;
    jsb_ngcc_CNgcAudio_class->enumerate = JS_EnumerateStub;
    jsb_ngcc_CNgcAudio_class->resolve = JS_ResolveStub;
    jsb_ngcc_CNgcAudio_class->convert = JS_ConvertStub;
    jsb_ngcc_CNgcAudio_class->finalize = js_ngcc_CNgcAudio_finalize;
    jsb_ngcc_CNgcAudio_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

    static JSPropertySpec properties[] = {
        JS_PSG("__nativeObj", js_is_native_obj, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_PS_END
    };

    static JSFunctionSpec funcs[] = {
        JS_FN("cacheGameSound", js_ngccAudioJsb_CNgcAudio_cacheGameSound, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("removeGameSound", js_ngccAudioJsb_CNgcAudio_removeGameSound, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("playBackMusic", js_ngccAudioJsb_CNgcAudio_playBackMusic, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("playGameSound", js_ngccAudioJsb_CNgcAudio_playGameSound, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("mayRecord", js_ngccAudioJsb_CNgcAudio_mayRecord, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setVolumeBackMusic", js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("update", js_ngccAudioJsb_CNgcAudio_update, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("endRecord", js_ngccAudioJsb_CNgcAudio_endRecord, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("playVoice", js_ngccAudioJsb_CNgcAudio_playVoice, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setVolumeVoice", js_ngccAudioJsb_CNgcAudio_setVolumeVoice, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("isRecording", js_ngccAudioJsb_CNgcAudio_isRecording, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("removeBackMusic", js_ngccAudioJsb_CNgcAudio_removeBackMusic, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("startRecord", js_ngccAudioJsb_CNgcAudio_startRecord, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setVolumeGame", js_ngccAudioJsb_CNgcAudio_setVolumeGame, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("setPaused", js_ngccAudioJsb_CNgcAudio_setPaused, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FS_END
    };

    JSFunctionSpec *st_funcs = NULL;

    jsb_ngcc_CNgcAudio_prototype = JS_InitClass(
        cx, global,
        JS::NullPtr(), // parent proto
        jsb_ngcc_CNgcAudio_class,
        js_ngccAudioJsb_CNgcAudio_constructor, 0, // constructor
        properties,
        funcs,
        NULL, // no static properties
        st_funcs);
    // make the class enumerable in the registered namespace
//  bool found;
//FIXME: Removed in Firefox v27 
//  JS_SetPropertyAttributes(cx, global, "CNgcAudio", JSPROP_ENUMERATE | JSPROP_READONLY, &found);

    // add the proto and JSClass to the type->js info hash table
    TypeTest<ngcc::CNgcAudio> t;
    js_type_class_t *p;
    std::string typeName = t.s_name();
    if (_js_global_type_map.find(typeName) == _js_global_type_map.end())
    {
        p = (js_type_class_t *)malloc(sizeof(js_type_class_t));
        p->jsclass = jsb_ngcc_CNgcAudio_class;
        p->proto = jsb_ngcc_CNgcAudio_prototype;
        p->parentProto = NULL;
        _js_global_type_map.insert(std::make_pair(typeName, p));
    }
}

void register_all_ngccAudioJsb(JSContext* cx, JS::HandleObject obj) {
    // Get the ns
    JS::RootedObject ns(cx);
    get_or_create_js_obj(cx, obj, "ngcc", &ns);

    js_register_ngccAudioJsb_CNgcAudio(cx, ns);
}

