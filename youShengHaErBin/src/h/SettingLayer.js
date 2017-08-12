/**
 * Created by admin on 2016/8/19.
 */

ngc.game.layer.SettingLayer = ngc.CLayerBase.extend({

    _musicBtn: null,
    _soundBtn: null,
    _shakeBtn: null,
    _handBtn: null,
    _musicFlag: null,
    _soundFlag: null,
    _shakeFlag: null,
    _handFlag:null,
    _changePanel: null,

    ctor: function (flag) {
        var flg  = flag || false;
        this._super();
        this.myInit(flg);
    },

    myInit: function (flag) {
        this._super(ngc.hall.jsonRes.settingLayer, true);
        this.mySetVisible(true);

        if (flag) {
            // this._changePanel.setVisible(false);
        }
    },

    onEnter: function () {
        this._super();

        this._musicFlag = ngc.flag.MUSIC_FLAG || false;
        this._soundFlag = ngc.flag.SOUND_FLAG || false;
        this._shakeFlag = ngc.flag.SHAKE_FLAG || false;
        this._handFlag = ngc.flag.HAND_FLAG || false;
        this._refreshTextrue();
    },

    onExit: function () {
        this._super();
    },

    _refreshTextrue: function () {
        var _btnArr = [this._musicBtn, this._soundBtn, this._shakeBtn, this._handBtn];
        var _flagArr = [this._musicFlag, this._soundFlag, this._shakeFlag, this._handFlag];

        for (var i = 0; i < 4; i++) {
            var _curBtn =_btnArr[i];
            var _curFlag = _flagArr[i];
            var _file = _curFlag ? ngc.hall.pngRes.setBtn1 : ngc.hall.pngRes.setBtn2;
            _curBtn.loadTextureNormal(_file);
            _curBtn.loadTexturePressed(_file);
            _curBtn.loadTextureDisabled(_file);
        }
    },

    _loadTextrue: function (name, sender) {
        var _file = this[name + "Flag"] ? ngc.hall.pngRes.setBtn2 : ngc.hall.pngRes.setBtn1;
        sender.loadTextureNormal(_file);
        sender.loadTexturePressed(_file);
        sender.loadTextureDisabled(_file);
        this[name + "Flag"] = !this[name + "Flag"];
    },

    onMusic: function (sender) {
        this._loadTextrue("_music", sender);
        ngc.flag.MUSIC_FLAG = this._musicFlag;
        console.log("ngc.flag.MUSIC_FLAG = " + ngc.flag.MUSIC_FLAG);
        if (!ngc.flag.MUSIC_FLAG) {
            //cc.audioEngine.pauseMusic();
            //cc.audioEngine.stopMusic(true);
            ngc.audio.getInstance().removeBackMusic();
        } else {
            //ngc.audio.setPaused(0);
            ngc.audio.getInstance().playBackMusic(ngc.hall.musicGame.bgm);
            //cc.audioEngine.playMusic(ngc.hall.musicGame.bgm, true);
        }
        ngc.pubUtils.setLocalDataJson("setFlag", {"music": ngc.flag.MUSIC_FLAG, "sound": ngc.flag.SOUND_FLAG, "shake": ngc.flag.SHAKE_FLAG});
    },

    onSound: function (sender) {
        this._loadTextrue("_sound", sender);
        ngc.flag.SOUND_FLAG = this._soundFlag;
        //if (!ngc.flag.SOUND_FLAG) {
        //    cc.audioEngine.pauseAllEffects();
        //} else {
        //    cc.audioEngine.resumeAllEffects();
        //}
        ngc.pubUtils.setLocalDataJson("setFlag", {"music": ngc.flag.MUSIC_FLAG, "sound": ngc.flag.SOUND_FLAG, "shake": ngc.flag.SHAKE_FLAG});
    },

    onShake: function (sender) {
        this._loadTextrue("_shake", sender);
        ngc.flag.SHAKE_FLAG = this._shakeFlag;
        ngc.pubUtils.setLocalDataJson("setFlag", {"music": ngc.flag.MUSIC_FLAG, "sound": ngc.flag.SOUND_FLAG, "shake": ngc.flag.SHAKE_FLAG});
    },

    onChangeLogin: function () {
        cc.sys.localStorage.removeItem("localUser");
        //ngc.cfg.GAME_FSADRRESS = "";
        var mainScene = new ngc.game.scene.LoginScene();
        cc.director.pushScene(mainScene);
    },

    onService: function () {
        var _aboutLayer = new ngc.game.layer.AboutLayer("protocol");
        this.addChild(_aboutLayer);
    },

    onClose: function () {
        this.mySetVisibleFalse();
    },
    onHand:function(sender){
        this._loadTextrue("_hand", sender);
        ngc.flag.HAND_FLAG=this._handFlag;
        ngc.pubUtils.setLocalDataJson("setFlag", {"music": ngc.flag.MUSIC_FLAG, "sound": ngc.flag.SOUND_FLAG, "shake": ngc.flag.SHAKE_FLAG, "hand": ngc.flag.HAND_FLAG});
    }
});