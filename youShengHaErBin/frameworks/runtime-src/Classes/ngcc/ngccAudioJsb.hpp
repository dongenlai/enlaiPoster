#include "base/ccConfig.h"
#ifndef __ngccAudioJsb_h__
#define __ngccAudioJsb_h__

#include "jsapi.h"
#include "jsfriendapi.h"

extern JSClass  *jsb_ngcc_CNgcAudio_class;
extern JSObject *jsb_ngcc_CNgcAudio_prototype;

bool js_ngccAudioJsb_CNgcAudio_constructor(JSContext *cx, uint32_t argc, jsval *vp);
void js_ngccAudioJsb_CNgcAudio_finalize(JSContext *cx, JSObject *obj);
void js_register_ngccAudioJsb_CNgcAudio(JSContext *cx, JS::HandleObject global);
void register_all_ngccAudioJsb(JSContext* cx, JS::HandleObject obj);
bool js_ngccAudioJsb_CNgcAudio_cacheGameSound(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_removeGameSound(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_playBackMusic(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_playGameSound(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_mayRecord(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_setVolumeBackMusic(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_update(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_endRecord(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_playVoice(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_setVolumeVoice(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_isRecording(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_removeBackMusic(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_startRecord(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_setVolumeGame(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_setPaused(JSContext *cx, uint32_t argc, jsval *vp);
bool js_ngccAudioJsb_CNgcAudio_CNgcAudio(JSContext *cx, uint32_t argc, jsval *vp);

#endif // __ngccAudioJsb_h__
