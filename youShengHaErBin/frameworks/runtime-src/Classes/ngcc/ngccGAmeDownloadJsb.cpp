#include "ngccGameDownloadJsb.hpp"
#include "ngccGameDownload.h"
#include "cocos2d.h"
#include "spidermonkey_specifics.h"
#include "ScriptingCore.h"
#include "cocos2d_specifics.hpp"

JSClass  *js_cocos2dx_ngccgamedownloader_class;
JSObject *js_cocos2dx_ngccgamedownloader_prototype;

using namespace ngcc;

void js_cocos2dx_ngccGameDownloader_finalize(JSFreeOp *fop, JSObject *obj) {
	CCLOG("jsbindings: finalizing JS object %p (ngccGameDownloader)", obj);
}

bool js_cocos2dx_ngccGameDownloader_constructor(JSContext *cx, uint32_t argc, jsval *vp)
{
	JS::CallArgs args = JS::CallArgsFromVp(argc, vp);

	if (argc == 1)
	{
		std::string gameName;

		do {
			bool ok = jsval_to_std_string(cx, args.get(0), &gameName);
			JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
		} while (0);

		JS::RootedObject obj(cx, JS_NewObject(cx, js_cocos2dx_ngccgamedownloader_class, JS::RootedObject(cx, js_cocos2dx_ngccgamedownloader_prototype), JS::NullPtr()));

		ngccGameDownloader* cobj = new ngccGameDownloader(gameName);
		ngccGameDownloadJsDelegate* delegate = new ngccGameDownloadJsDelegate();
		delegate->setJSObj(obj);
		cobj->setDelegate((ngccGameloadDelegate *)delegate);


		// link the native object with the javascript object
		js_proxy_t *p = jsb_new_proxy(cobj, obj);
		JS::AddNamedObjectRoot(cx, &p->obj, "ngccGameDownloader");

		args.rval().set(OBJECT_TO_JSVAL(obj));
		return true;
	}

	JS_ReportError(cx, "wrong number of arguments: %d, was expecting %d", argc, 1);
	return false;
}

bool js_cocos2dx_ngccGameDownloader_startDownloadAsync(JSContext *cx, uint32_t argc, jsval *vp)
{
	if (argc == 1)
	{
		JS::CallArgs args = JS::CallArgsFromVp(argc, vp);
		std::string packageUrl;
		do {
			bool ok = jsval_to_std_string(cx, args.get(0), &packageUrl);
			JSB_PRECONDITION2(ok, cx, false, "Error processing arguments");
		} while (0);

		JSObject *obj = JS_THIS_OBJECT(cx, vp);
		js_proxy_t *proxy = jsb_get_js_proxy(obj);
		ngccGameDownloader* cobj = (ngccGameDownloader *)(proxy ? proxy->ptr : NULL);
		JSB_PRECONDITION2(cobj, cx, false, "Invalid Native Object");

		cobj->startDownloadAsync(packageUrl);
		args.rval().setUndefined();
		return true;
	}
	JS_ReportError(cx, "wrong number of arguments: %d, was expecting %d", argc, 1);
	return false;
}

void js_register_ngccGameDownloaderJsb(JSContext *cx, JS::HandleObject global) {
	js_cocos2dx_ngccgamedownloader_class = (JSClass *)calloc(1, sizeof(JSClass));
	js_cocos2dx_ngccgamedownloader_class->name = "ngccGameDownloader";
	js_cocos2dx_ngccgamedownloader_class->addProperty = JS_PropertyStub;
	js_cocos2dx_ngccgamedownloader_class->delProperty = JS_DeletePropertyStub;
	js_cocos2dx_ngccgamedownloader_class->getProperty = JS_PropertyStub;
	js_cocos2dx_ngccgamedownloader_class->setProperty = JS_StrictPropertyStub;
	js_cocos2dx_ngccgamedownloader_class->enumerate = JS_EnumerateStub;
	js_cocos2dx_ngccgamedownloader_class->resolve = JS_ResolveStub;
	js_cocos2dx_ngccgamedownloader_class->convert = JS_ConvertStub;
	js_cocos2dx_ngccgamedownloader_class->finalize = js_cocos2dx_ngccGameDownloader_finalize;
	js_cocos2dx_ngccgamedownloader_class->flags = JSCLASS_HAS_RESERVED_SLOTS(2);

	static JSPropertySpec properties[] = {
		JS_PS_END
	};

	static JSFunctionSpec funcs[] = {
		JS_FN("startDownloadAsync", js_cocos2dx_ngccGameDownloader_startDownloadAsync, 1, JSPROP_PERMANENT | JSPROP_ENUMERATE),
		JS_FS_END
	};

	static JSFunctionSpec st_funcs[] = {
		JS_FS_END
	};

	js_cocos2dx_ngccgamedownloader_prototype = JS_InitClass(
		cx, global,
		JS::NullPtr(),
		js_cocos2dx_ngccgamedownloader_class,
		js_cocos2dx_ngccGameDownloader_constructor, 0, // constructor
		properties,
		funcs,
		NULL, // no static properties
		st_funcs);
}

void register_all_ngccGameDownloaderJsb(JSContext* cx, JS::HandleObject obj)
{
	JS::RootedObject ns(cx);
	get_or_create_js_obj(cx, obj, "ngcc", &ns);

	js_register_ngccGameDownloaderJsb(cx, ns);
}