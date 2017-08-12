//大厅的声音播放，包含声音开关(游戏中的声音播放要使用大厅的设置的话，请用这个ngc.audio)
/*
var ngcAudio=function(){
    this._audioFMOD=new ngcc.CNgcAudio();
    this._audioDension= cc.audioEngine;

    this._musicOpened=true;
    this._effectOpened=true;

    this._localSettingStr="musicSetting";

    this._bgMusicUrl="";

    if(!ngcAudio.initialized){
        ngcAudio.initialized=true;

        ngcAudio.prototype.initSetting=function(){
            var settingData=ngc.pubUtils.getLocalDataJson(this._localSettingStr);
            if(settingData&&settingData["music"]&&settingData["effect"]){
                this._musicOpened=settingData["music"]?true:false;
                this._effectOpened=settingData["effect"]?true:false;
            }
        }

        ngcAudio.prototype.setPaused=function(int){
            this._audioFMOD.setPaused(int);
            if (0 === int) {
                this._audioDension.resumeMusic();
            } else {
                this._audioDension.pauseMusic();
            }
        }

        ngcAudio.prototype.update=function(){
            this._audioFMOD.update();
        }

        ngcAudio.prototype.cacheGameSound=function(str){
            this._audioFMOD.cacheGameSound(str);
        }

        ngcAudio.prototype.setEffectVolume=function(float){
            this._audioFMOD.setVolumeVoice(float);
            this._audioDension.setEffectsVolume(float);
        }

        ngcAudio.prototype.setMusicVolume=function(float){
            this._audioFMOD.setVolumeBackMusic(float);
            this._audioDension.setMusicVolume(float);
        }

        //cocos dension
        ngcAudio.prototype.playEffectDension=function(url,loop){
            if(this._effectOpened){
                return this._audioDension.playEffect(url,loop);
            }
        }
        //cocos dension
        ngcAudio.prototype.stopEffectDension=function(str){
            this._audioDension.stopEffect(str);
        }

        //fmod 音频引擎
        ngcAudio.prototype.playEffectFMOD=function(url,loop){
            if(this._effectOpened){
                this._audioFMOD.playGameSound(url);
            }
        }

        ngcAudio.prototype.playGameSound=function(url){
            if(this._effectOpened){
                this._audioFMOD.playGameSound(url);
            }
        }



        //cocos dension
        ngcAudio.prototype.playMusicDension=function(url,loop){
            if(this._musicOpened){
                if(this._bgMusicUrl!=url||!this._audioDension.isMusicPlaying()){
                    this._bgMusicUrl=url;
                    this._audioDension.playMusic(url,loop);
                }
            }
        }
        //fmod 音频引擎
        ngcAudio.prototype.playMusicFMOD=function(url){
            if(this._musicOpened){
                if(this._bgMusicUrl!=url){
                    this._bgMusicUrl=url;
                    this._audioFMOD.playBackMusic(url);
                }
            }
        }
        //fmod 音频引擎
        ngcAudio.prototype.playBackMusic=function(url){
            if(this._musicOpened){
                this._audioFMOD.playBackMusic(url);
            }
        }

        //fmod 音频引擎
        ngcAudio.prototype.removeBackMusic=function(){
            this._audioFMOD.removeBackMusic();
        }

        //fmod 音频引擎
        ngcAudio.prototype.removeGameSound=function(str){
            this._audioFMOD.removeGameSound(str);
        }

        ngcAudio.prototype.stopAllEffects=function(){
            this._audioDension.stopAllEffects();
        }

        ngcAudio.prototype.stopMusic=function(){
            this._audioDension.stopMusic(true);
            this._audioFMOD.removeBackMusic();
        }
        //不要从外部调用
        ngcAudio.prototype.closeMusic=function(){
            this.stopMusic();
            this._musicOpened=false;
            ngc.pubUtils.setLocalDataJson(this._localSettingStr,{"music":this._musicOpened,"effect":this._effectOpened});
        }
        //不要从外部调用
        ngcAudio.prototype.openMusic=function(){
            this._musicOpened=true;
            ngc.pubUtils.setLocalDataJson(this._localSettingStr,{"music":this._musicOpened,"effect":this._effectOpened});
        }

        ngcAudio.prototype.closeEffect=function(){
            this.stopAllEffects();
            this._effectOpened=false;
            ngc.pubUtils.setLocalDataJson(this._localSettingStr,{"music":this._musicOpened,"effect":this._effectOpened});
        }
        ngcAudio.prototype.openEffect=function(){
            this._effectOpened=true;
            ngc.pubUtils.setLocalDataJson(this._localSettingStr,{"music":this._musicOpened,"effect":this._effectOpened});
        }

        Object.defineProperties(this,{
            musicOpened:{
                get:function(){
                    return this._musicOpened;
                },
                set:function(status){
                    if(status)
                        this.openMusic();
                    else
                        this.closeMusic();
                }
            },
            effectOpened:{
                get:function(){
                    return this._effectOpened;
                },
                set:function(status){
                    if(status)
                        this.openEffect();
                    else
                        this.closeEffect();
                }
            }
        });
    }
}
*/

/**
 * 必须是单例
 * @type {{}}
 */
ngc.audio=ngc.audio||{};
ngc.audio._instance=null;
ngc.audio.getInstance=function(){
    if(!ngc.audio._instance){
        ngc.audio._instance=new ngcc.CNgcAudio();
        cc.eventManager.addCustomListener(cc.game.EVENT_HIDE, function(){
            ngc.audio._instance.setPaused(1);
        });
        cc.eventManager.addCustomListener(cc.game.EVENT_SHOW, function(){
            ngc.audio._instance.setPaused(0);
        });
    }
    return ngc.audio._instance;
}
//ngc.audio.initSetting();