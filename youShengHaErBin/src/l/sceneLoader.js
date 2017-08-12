ngc.loader.pngRes = {

};

ngc.loader.jsonRes = {

};


ngc.loader.resources = [];

for (var i in ngc.loader.jsonRes) {
    ngc.loader.resources.push(ngc.loader.jsonRes[i]);
}

for (var n in ngc.loader.pngRes) {
    ngc.loader.resources.push(ngc.loader.pngRes[n]);
}


ngc.loader.startLoading = function(){
    var updateScene = new ngc.loader.CSceneLoad();
    updateScene.myInit(function(){
        for(var name in ngc.loader.pngRes){
            var png = ngc.loader.pngRes[name];
            cc.loader.release(png);
            cc.textureCache.removeTextureForKey(png);
        }

        //var mainScene = new ngc.hall.CSceneMain();
        //var mainScene = new ngc.hall.SceneLoadGame({});
        try{
            var mainScene = new ngc.game.scene.LoginScene();
            cc.director.runScene(mainScene);
        }
        catch (ex){
            ngc.log.info(ex.message+"&&&&&&&"+ex.name);
        }

    });
    updateScene.startUpdate();
};

ngc.loader.CSceneLoad = ngc.CSceneBase.extend({
    _customEventName: "httpLayerLogin",
    _lblProgress:null,
    _cbLoadEnd: null,
    _versionMgr:null,
    _myListener: null,
    _updateFailCount: 0,
    _updateStage:0,
    _updatePercent:0,
    _totalSec: 0,

    _localUserName:"",
    _localPwd:"",
    _tryLogin:0,
    ctor:function(){
       this._super();
    },
    myInit: function(cbLoadEnd){
        this._cbLoadEnd = cbLoadEnd;
        //this._super(ngc.loader.jsonRes.layerLoading);
        var sprite=new cc.Sprite("res/hallUi/f/f-4.jpg");
        sprite.setAnchorPoint(cc.p(0,0));
        sprite.setPosition(cc.p(0,0));
        this.addChild(sprite);


        var lable=new ccui.Text("正在检测版本...","Arial","32");
        lable.setTextColor(cc.color(255,255,255));
        lable.enableShadow(cc.color(255,255,255),cc.size(1,-1),1);
        lable.setPosition(cc.p(cc.winSize.width/2,160));
        this.addChild(lable);
        this._lblProgress=lable;

        /*if(!this._customEventListener){
            var self = this;
            this._customEventListener = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: self._customEventName,
                callback: function(event){
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener, 1);
        }*/
    },

    myClear: function(){
        this.unscheduleAllCallbacks();
        if(this._myListener){
            cc.eventManager.removeListener(this._myListener);
            this._myListener = null;
        }
        if (this._versionMgr) {
            this._versionMgr.release();
            this._versionMgr = null;
        }
    },

    updateProgress:function(dt){
        this._totalSec += dt;
        var state = this._versionMgr.getState();
        if(state === 2 || state === 5){
            if(this._totalSec > 2.0){
                ngc.log.info("updateProgress 超时");
                this.loadGame();
            }
        }
        if(this._updatePercent>0)
            this._lblProgress.setString(cc.formatStr("正在更新：%d% (%d)", parseInt(this._updatePercent), parseInt(this._totalSec)));
    },

    loadResProgress: function(percent){
        //this._lblProgress.setString(cc.formatStr("加载资源：%d%", percent));
    },

    onExit:function(){
        this.myClear();
        //cc.eventManager.removeListener(this._customEventListener);
        this._super();
    },

    //ios,android检查整包更新
    checkPackUpdate:function(){
        cc.director.runScene(this);

        if (!cc.sys.isNative || (cc.sys.os != cc.sys.OS_ANDROID && cc.sys.os != cc.sys.OS_IOS)) {
            this.startUpdate();
        }
        else{
            this.comparePackVersionWithServer();
        }
    },

    comparePackVersionWithServer:function(){
        var localVersion=this.getVersion();
        ngc.log.info("local version:"+localVersion);
        if(localVersion.length>0){
            ngc.http.httpPostHs("/interface/base_onlineupdate.do", {"versionNum":localVersion}, this._customEventName, "compareVersion");
        }
        else{
            this.startUpdate();
        }
    },

    onCompareVersionSuccess:function(data){
        ngc.log.info("update info:"+JSON.stringify(data));
        if(data&&data["path"]){
            var layer=new ngc.loader.layerTip();
            layer.myInit(GlobalConfig.hs_addr+"/"+data["path"]);
            this.addChild(layer);
        }
        else if(data&&data["game"]&&data["game"].length>0){
            ngc.GameUpgradeInfo.setGameUpgradeInfo(data["game"]);
            this.startUpdate();
        }
        else{
            this.startUpdate();
        }
    },

    getVersion:function(){
        if(cc.sys.os==cc.sys.OS_ANDROID){
            return jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity","getVersionName","()Ljava/lang/String;");
        }
        else if(cc.sys.os==cc.sys.OS_IOS){
            return jsb.reflection.callStaticMethod("AppController", "getVersionName");
        }
    },

    startUpdate:function(){
        if(cc.sys.os==cc.sys.OS_WINDOWS || cc.sys.os==cc.sys.OS_OSX){
            cc.director.runScene(this);
            this.loadGame();
            return;
        }
        if (!cc.sys.isNative) {
            cc.director.runScene(this);
            this.loadGame();
            return;
        }
        if (this._versionMgr){
            ngc.log.error("update running");
            return;
        }

        var storagePath = (jsb.fileUtils ? jsb.fileUtils.getWritablePath() : "/");
        ngc.log.info("Storage path: " + storagePath);
        this._versionMgr = new jsb.AssetsManager("res/version.manifest", storagePath);
        this._versionMgr.retain();

        if (!this._versionMgr.getLocalManifest().isLoaded())
        {
            ngc.log.info("Fail to update assets, step skipped.");
            this.loadGame();
        } else {
            var that = this;
            var listener = new jsb.EventListenerAssetsManager(this._versionMgr, function(event) {
                switch (event.getEventCode()){
                    case jsb.EventAssetsManager.ERROR_NO_LOCAL_MANIFEST:
                        ngc.log.info("No local manifest file found, skip assets update.");
                        that.loadGame();
                        break;
                    case jsb.EventAssetsManager.UPDATE_PROGRESSION:
                        that._updateStage =  event.getPercentByFile();
                        that._updatePercent = event.getPercent();
                        ngc.log.info(cc.formatStr("update progress: percent=%d%(%d)", that._updateStage, that._updatePercent));
                        break;
                    case jsb.EventAssetsManager.ERROR_DOWNLOAD_MANIFEST:
                    case jsb.EventAssetsManager.ERROR_PARSE_MANIFEST:
                        ngc.log.info("Fail download manifest file, update skipped.");
                        that.loadGame();
                        break;
                    case jsb.EventAssetsManager.ALREADY_UP_TO_DATE:
                        ngc.log.info("ALREADY_UP_TO_DATE.");
                    case jsb.EventAssetsManager.UPDATE_FINISHED:
                        ngc.log.info("Update finished.");
                        that.loadGame();
                        break;
                    case jsb.EventAssetsManager.UPDATE_FAILED:
                        ngc.log.info("Update failed. " + event.getMessage());

                        ++that._updateFailCount;
                        if (that._updateFailCount < 5) {
                            that._versionMgr.downloadFailedAssets();
                        } else {
                            ngc.log.info("Reach maximum fail count, exit update process");
                            that.loadGame();
                        }
                        break;
                    case jsb.EventAssetsManager.ERROR_UPDATING:
                        ngc.log.info("Asset update error: " + event.getAssetId() + ", " + event.getMessage());
                        that.loadGame();
                        break;
                    case jsb.EventAssetsManager.ERROR_DECOMPRESS:
                        ngc.log.info("ERROR_DECOMPRESS:" + event.getMessage());
                        that.loadGame();
                        break;
                    default:
                        break;
                }
            });
            cc.eventManager.addListener(listener, 1);
            this._myListener = listener;
            this._versionMgr.update();
            cc.director.runScene(this);
        }
        this.schedule(this.updateProgress, 0.1);
    },

    loadGame:function() {
        this._updateStage = 100;
        this._updatePercent = 100;
        this.myClear();
        var self = this;
        for (var i = 0; i < g_reloadJsArray.length; ++i)
            cc.sys.cleanScript(g_reloadJsArray[i]);
        cc.loader.loadJs(g_reloadJsArray, function(err){
            cc.loader.loadJs(ngc.hall.jsFiles, function (err) {
                cc.loader.load(ngc.hall.resources,
                    function (result, count, loadedCount) {
                        var percent = parseInt((loadedCount / count * 100) | 0);
                        percent = Math.min(percent, 100);
                        self.loadResProgress(percent);
                    },
                    function () {
                        //self._lblProgress.setString("正在载入界面");
                        for (var name in ngc.hall.pngRes) {
                            var png = ngc.hall.pngRes[name];
                            if (!cc.textureCache.getTextureForKey(png))
                                cc.textureCache.addImage(png)
                        }
                        self.schedule(self.callBack, 1, 100000, 1.4);
                    });
            });
        });
        //自动登录
        //this.autoLogin();
    },

    callBack:function(){
        //if((this._tryLogin>0&&this._cbLoadEnd)||this.callBackCallNum>=11){
            this.unschedule(this.callBack);
            this._cbLoadEnd();
        //}
        //else{
        //    this.callBackCallNum=this.callBackCallNum||1;
        //    this.callBackCallNum++;
        //}
    },

    //自动登录
    autoLogin:function(){
        var json = ngc.pubUtils.getLocalDataJson("localUser");
        if(json["userName"]){
            this._localUserName=json["userName"];
            if(json["pwd"])
                this._localPwd=json["pwd"];
        }
        var name=this._localUserName;
        var pwd=this._localPwd;
        if(name.length>0&&pwd.length>0){
            var postData = {loginAccount: name, password: pwd};
            ngc.http.httpPostHs("/interface/base_login.do", postData, this._customEventName, "login");
        }
        else{
            this._tryLogin=2;
        }
    },


    onHttpEvent: function(userData) {
        this._tryLogin=2;
        ngc.log.info("has try to login");

        if(userData.errorCode !== 0){
            this._lblProgress.setString("连接服务器失败");
            return;
        }

        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        switch (userData.data){
            case "login":
                if(retJson["response"] !== 1)
                    this._lblProgress.setString(retJson["msg"]);
                else
                    this.onLoginSuccess(retJson);
                break;
            case "compareVersion":
                this.onCompareVersionSuccess(retJson);
                break;
            default:
                ngc.log.error("onHttpEvent data=" + userData.data);
                break;
        }
    },
    onLoginSuccess: function(json) {
        //ngc.curUser.baseInfo.readFromJson(json);
        //ngc.curUser.gold = json["gold"];
        //ngc.curUser.access_token = json["access_token"];
        //ngc.curUser.token = json["token"];
        //this._tryLogin=1;
    }
});