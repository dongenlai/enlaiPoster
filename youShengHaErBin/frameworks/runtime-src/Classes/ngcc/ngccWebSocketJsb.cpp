#include "ngccWebSocketJsb.hpp"
#include "cocos2d_specifics.hpp"
#include "ngccWebSocket.h"

class JSB_CNgcWebSocketDelegate : public ngcc::CNgcWebSocket::Delegate
{
public:

    virtual void onOpen(ngcc::CNgcWebSocket* ws)
    {
        js_proxy_t * p = jsb_get_native_proxy(ws);
        if (!p) return;

        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

            JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();
        JS::RootedObject jsobj(cx, JS_NewObject(cx, NULL, JS::NullPtr(), JS::NullPtr()));
        JS::RootedValue vp(cx);
        vp = c_string_to_jsval(cx, "open");
        JS_SetProperty(cx, jsobj, "type", vp);

        jsval args = OBJECT_TO_JSVAL(jsobj);

        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(_JSDelegate), "onopen", 1, &args);
    }

    virtual void onMessage(ngcc::CNgcWebSocket* ws, const ngcc::CNgcWebSocket::Data& data)
    {
        js_proxy_t * p = jsb_get_native_proxy(ws);
        if (!p) return;

        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

            JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();
        JS::RootedObject jsobj(cx, JS_NewObject(cx, NULL, JS::NullPtr(), JS::NullPtr()));
        JS::RootedValue vp(cx);
        vp = c_string_to_jsval(cx, "message");
        JS_SetProperty(cx, jsobj, "type", vp);

        jsval args = OBJECT_TO_JSVAL(jsobj);

        if (data.isBinary)
        {// data is binary
            JSObject* buffer = JS_NewArrayBuffer(cx, static_cast<uint32_t>(data.len));
            uint8_t* bufdata = JS_GetArrayBufferData(buffer);
            memcpy((void*)bufdata, (void*)data.bytes, data.len);
            JS::RootedValue dataVal(cx);
            dataVal = OBJECT_TO_JSVAL(buffer);
            JS_SetProperty(cx, jsobj, "data", dataVal);
        }
        else
        {// data is string
            JS::RootedValue dataVal(cx);
            dataVal = c_string_to_jsval(cx, data.bytes);
            JS_SetProperty(cx, jsobj, "data", dataVal);
        }

        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(_JSDelegate), "onmessage", 1, &args);
    }

    virtual void onClose(ngcc::CNgcWebSocket* ws)
    {
        js_proxy_t * p = jsb_get_native_proxy(ws);
        if (!p) return;

        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

            JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();
        JS::RootedObject jsobj(cx, JS_NewObject(cx, NULL, JS::NullPtr(), JS::NullPtr()));
        JS::RootedValue vp(cx);
        vp = c_string_to_jsval(cx, "close");
        JS_SetProperty(cx, jsobj, "type", vp);

        jsval args = OBJECT_TO_JSVAL(jsobj);
        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(_JSDelegate), "onclose", 1, &args);

        js_proxy_t* jsproxy = jsb_get_js_proxy(p->obj);
        JS::RemoveObjectRoot(cx, &jsproxy->obj);
        jsb_remove_proxy(p, jsproxy);
        CC_SAFE_DELETE(ws);
    }

    virtual void onError(ngcc::CNgcWebSocket* ws, const ngcc::CNgcWebSocket::ErrorCode& error)
    {
        js_proxy_t * p = jsb_get_native_proxy(ws);
        if (!p) return;

        JSB_AUTOCOMPARTMENT_WITH_GLOBAL_OBJCET

            JSContext* cx = ScriptingCore::getInstance()->getGlobalContext();
        JS::RootedObject jsobj(cx, JS_NewObject(cx, NULL, JS::NullPtr(), JS::NullPtr()));
        JS::RootedValue vp(cx);
        vp = c_string_to_jsval(cx, "error");
        JS_SetProperty(cx, jsobj, "type", vp);

        jsval args = OBJECT_TO_JSVAL(jsobj);

        ScriptingCore::getInstance()->executeFunctionWithOwner(OBJECT_TO_JSVAL(_JSDelegate), "onerror", 1, &args);
    }

    void setJSDelegate(JSObject* pJSDelegate)
    {
        _JSDelegate = pJSDelegate;
    }
private:
    JS::Heap<JSObject*> _JSDelegate;
};

JSClass  *js_cocos2dx_cngcwebsocket_class;
JSObject *js_cocos2dx_cngcwebsocket_prototype;

void js_cocos2dx_CNgcWebSocket_finalize(JSFreeOp *fop, JSObject *obj) {
    CCLOG("jsbindings: finalizing JS object %p (WebSocket)", obj);
}

bool js_cocos2dx_extension_CNgcWebSocket_send(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSObject *obj = JS_THIS_OBJECT(cx, vp);
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcWebSocket* cobj = (ngcc::CNgcWebSocket *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2(cobj, cx, false, "Invalid Native Object");

    if (argc == 1){
        do
        {
            if (args.get(0).isString())
            {
                std::string data;
                jsval_to_std_string(cx, args.get(0), &data);
                cobj->send(data);
                break;
            }

            if (args.get(0).isObject())
            {
                uint8_t *bufdata = NULL;
                uint32_t len = 0;

                JSObject* jsobj = args.get(0).toObjectOrNull();
                if (JS_IsArrayBufferObject(jsobj))
                {
                    bufdata = JS_GetArrayBufferData(jsobj);
                    len = JS_GetArrayBufferByteLength(jsobj);
                }
                else if (JS_IsArrayBufferViewObject(jsobj))
                {
                    bufdata = (uint8_t*)JS_GetArrayBufferViewData(jsobj);
                    len = JS_GetArrayBufferViewByteLength(jsobj);
                }

                if (bufdata && len > 0)
                {
                    cobj->send(bufdata, len);
                    break;
                }
            }

            JS_ReportError(cx, "data type to be sent is unsupported.");

        } while (0);

        args.rval().setUndefined();

        return true;
    }
    JS_ReportError(cx, "wrong number of arguments: %d, was expecting %d", argc, 0);
    return true;
}

bool js_cocos2dx_extension_CNgcWebSocket_close(JSContext *cx, uint32_t argc, jsval *vp){
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSObject *obj = JS_THIS_OBJECT(cx, vp);
    js_proxy_t *proxy = jsb_get_js_proxy(obj);
    ngcc::CNgcWebSocket* cobj = (ngcc::CNgcWebSocket *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2(cobj, cx, false, "Invalid Native Object");

    if (argc == 0){
        cobj->close();
        args.rval().setUndefined();
        return true;
    }
    JS_ReportError(cx, "wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}

bool js_cocos2dx_extension_CNgcWebSocket_constructor(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

    if (argc == 1 || argc == 2)
    {

        std::string url;

        do {
            bool ok = jsval_to_std_string(cx, args.get(0), &url);
            JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
        } while (0);

        JS::RootedObject obj(cx, JS_NewObject(cx, js_cocos2dx_cngcwebsocket_class, JS::RootedObject(cx, js_cocos2dx_cngcwebsocket_prototype), JS::NullPtr()));
        //JS::RootedObject obj(cx, JS_NewObjectForConstructor(cx, js_cocos2dx_cngcwebsocket_class, args));

        ngcc::CNgcWebSocket* cobj = new ngcc::CNgcWebSocket();
        JSB_CNgcWebSocketDelegate* delegate = new JSB_CNgcWebSocketDelegate();
        delegate->setJSDelegate(obj);

        if (argc == 2)
        {
            std::vector<std::string> protocols;

            if (args.get(1).isString())
            {
                std::string protocol;
                do {
                    bool ok = jsval_to_std_string(cx, args.get(1), &protocol);
                    JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
                } while (0);
                protocols.push_back(protocol);
            }
            else if (args.get(1).isObject())
            {
                bool ok = true;
                JS::RootedObject arg2(cx, args.get(1).toObjectOrNull());
                JSB_PRECONDITION(JS_IsArrayObject(cx, arg2), "Object must be an array");

                uint32_t len = 0;
                JS_GetArrayLength(cx, arg2, &len);

                for (uint32_t i = 0; i< len; i++)
                {
                    JS::RootedValue valarg(cx);
                    JS_GetElement(cx, arg2, i, &valarg);
                    std::string protocol;
                    do {
                        ok = jsval_to_std_string(cx, valarg, &protocol);
                        JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
                    } while (0);

                    protocols.push_back(protocol);
                }
            }
            cobj->init(*delegate, url, &protocols);
        }
        else
        {
            cobj->init(*delegate, url);
        }


        JS_DefineProperty(cx, obj, "URL", args.get(0), JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);

        //protocol not support yet (always return "")
        JS_DefineProperty(cx, obj, "protocol", JS::RootedValue(cx, c_string_to_jsval(cx, "")), JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);

        // link the native object with the javascript object
        js_proxy_t *p = jsb_new_proxy(cobj, obj);
        JS::AddNamedObjectRoot(cx, &p->obj, "CNgcWebSocket");

        args.rval().set(OBJECT_TO_JSVAL(obj));
        return true;
    }

    JS_ReportError(cx, "wrong number of arguments: %d, was expecting %d", argc, 0);
    return false;
}

static bool js_cocos2dx_extension_CNgcWebSocket_get_readyState(JSContext *cx, uint32_t argc, jsval *vp)
{
    JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
    JSObject* jsobj = args.thisv().toObjectOrNull();
    js_proxy_t *proxy = jsb_get_js_proxy(jsobj);
    ngcc::CNgcWebSocket* cobj = (ngcc::CNgcWebSocket *)(proxy ? proxy->ptr : NULL);
    JSB_PRECONDITION2(cobj, cx, false, "Invalid Native Object");

    if (cobj) {
        args.rval().set(INT_TO_JSVAL((int)cobj->getReadyState()));
        return true;
    }
    else {
        JS_ReportError(cx, "Error: WebSocket instance is invalid.");
        return false;
    }
}

void js_register_ngccWebSocketJsb_CNgcWebSocket(JSContext *cx, JS::HandleObject global) {

    js_cocos2dx_cngcwebsocket_class = (JSClass *)calloc(1, sizeof(JSClass));
    js_cocos2dx_cngcwebsocket_class->name = "CNgcWebSocket";
    js_cocos2dx_cngcwebsocket_class->addProperty = JS_PropertyStub;
    js_cocos2dx_cngcwebsocket_class->delProperty = JS_DeletePropertyStub;
    js_cocos2dx_cngcwebsocket_class->getProperty = JS_PropertyStub;
    js_cocos2dx_cngcwebsocket_class->setProperty = JS_StrictPropertyStub;
    js_cocos2dx_cngcwebsocket_class->enumerate = JS_EnumerateStub;
    js_cocos2dx_cngcwebsocket_class->resolve = JS_ResolveStub;
    js_cocos2dx_cngcwebsocket_class->convert = JS_ConvertStub;
    js_cocos2dx_cngcwebsocket_class->finalize = js_cocos2dx_CNgcWebSocket_finalize;
    js_cocos2dx_cngcwebsocket_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

    static JSPropertySpec properties[] = {
        JS_PSG("readyState", js_cocos2dx_extension_CNgcWebSocket_get_readyState, JSPROP_ENUMERATE | JSPROP_PERMANENT),
        JS_PS_END
    };

    static JSFunctionSpec funcs[] = {
        JS_FN("send", js_cocos2dx_extension_CNgcWebSocket_send, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FN("close", js_cocos2dx_extension_CNgcWebSocket_close, 0, JSPROP_PERMANENT | JSPROP_ENUMERATE),
        JS_FS_END
    };

    static JSFunctionSpec st_funcs[] = {
        JS_FS_END
    };

    js_cocos2dx_cngcwebsocket_prototype = JS_InitClass(
        cx, global,
        JS::NullPtr(),
        js_cocos2dx_cngcwebsocket_class,
        js_cocos2dx_extension_CNgcWebSocket_constructor, 0, // constructor
        properties,
        funcs,
        NULL, // no static properties
        st_funcs);

    JS_DefineProperty(cx, global, "CONNECTING", (int)ngcc::CNgcWebSocket::State::CONNECTING, JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);
    JS_DefineProperty(cx, global, "OPEN", (int)ngcc::CNgcWebSocket::State::OPEN, JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);
    JS_DefineProperty(cx, global, "CLOSING", (int)ngcc::CNgcWebSocket::State::CLOSING, JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);
    JS_DefineProperty(cx, global, "CLOSED", (int)ngcc::CNgcWebSocket::State::CLOSED, JSPROP_ENUMERATE | JSPROP_PERMANENT | JSPROP_READONLY);
}

void register_all_ngccWebSocketJsb(JSContext* cx, JS::HandleObject obj) {
    // Get the ns
    JS::RootedObject ns(cx);
    get_or_create_js_obj(cx, obj, "ngcc", &ns);

    js_register_ngccWebSocketJsb_CNgcWebSocket(cx, ns);
}