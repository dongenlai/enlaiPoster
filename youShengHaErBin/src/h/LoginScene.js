/**
 * Created by admin on 2016/8/19.
 */

ngc.game.scene.LoginScene = ngc.CSceneBase.extend({
    _customEventListener: null,
    _customEventName: "httpLayerLogin",
    _checkBoxBtn:null,
    _lblText:null,
    _btnYK:null,
    _wxBtn:null,

    ctor: function () {
        this._super();
        this.myInit();
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.loginScene);
        if(!this._customEventListener){
            var self = this;
            this._customEventListener = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: self._customEventName,
                callback: function(event){
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener, this);
        }
        if(cc.sys.os==cc.sys.OS_ANDROID){
            cc.eventManager.addListener({
                event: cc.EventListener.KEYBOARD,
                onKeyReleased: function(keyCode, event){
                    if(keyCode == cc.KEY.back){
                        var quitLayer=new ngc.game.layer.quit();
                        quitLayer.showInScene();
                    }
                }
            }, this);
        }

        //显示版本号：
        var fileStr="";
        if(jsb.fileUtils.isFileExist("version.manifest"))
            fileStr=jsb.fileUtils.getStringFromFile("version.manifest");
        else
            fileStr=jsb.fileUtils.getStringFromFile("res/version.manifest");
        if(fileStr){
            var jsonObj=ngc.pubUtils.string2Obj(fileStr);
            if(jsonObj["version"]){
                this._lblText.setString("当前版本号："+jsonObj["version"]);
            }
        }

        //windows显示游客
        if(cc.sys.os==cc.sys.OS_WINDOWS || cc.sys.os == cc.sys.OS_OSX){
            this._btnYK.setVisible(true);
        }else{
            this._wxBtn.setVisible(true);
        }
    },

    onEnter: function () {
        this._super();
        var _locaData = ngc.pubUtils.getLocalDataJson("setFlag");
        if (_locaData.music!=undefined) {
            ngc.flag.MUSIC_FLAG = _locaData.music;
            ngc.flag.SOUND_FLAG = _locaData.sound;
            ngc.flag.SHAKE_FLAG = _locaData.shake;
            ngc.flag.HAND_FLAG = _locaData.hand;
        }
        if (ngc.flag.MUSIC_FLAG)
            //cc.audioEngine.playMusic(ngc.hall.musicGame.bgm, true);
            ngc.audio.getInstance().playBackMusic(ngc.hall.musicGame.bgm);

        var localUserData = ngc.pubUtils.getLocalDataJson("localUser");
        if(localUserData&&localUserData.token!=undefined){  //自动登录
            this.autoLogin(localUserData);
        }
    },

    //打开 用户协议页面儿
    _openProto:function(){
        var _aboutLayer = new ngc.game.layer.AboutLayer(true);
        this.addChild(_aboutLayer);
    },

    onExit: function () {
        this._super();
        cc.eventManager.removeListener(this._customEventListener);
        //cc.audioEngine.end();
    },

    autoLogin: function (_locaData) {
        this.showLogining();
        var postData = {"userId": _locaData.userId, "token": _locaData.token};
        ngc.http.httpPostHs("/interface/base_autoLogin.do", postData, this._customEventName, "autoLogin");
        ngc.curUser.token = _locaData.token;
    },

    onLoginSuccess: function(json) {
        if(json){
            ngc.curUser.baseInfo.readFromJson(json);
            ngc.curUser.gold = json["gold"];
            ngc.curUser.access_token = json["access_token"];
            if (json["token"]) {
                ngc.curUser.token = json["token"];
            }
            if(!ngc.cfg._testState)
               ngc.pubUtils.setLocalDataJson("localUser", {"userId": ngc.curUser.baseInfo.userId, "token": ngc.curUser.token});
            //请求公告
            this.requestGetNotifcation();
        }
    },

    connectFS: function(){
        //如果是从游戏内返回到大厅那么不用再链接分发了直接请求登录进入游戏（包括断线重连）
        var postData = {"gameIds":ngc.curUser.gameId};
        ngc.http.httpPostHs("/interface/base_getFSAddr.do", postData, this._customEventName, "FS");
    },

    getFsSuccess:function(retJson){
        var fsUrl = retJson["fsUrls"]["6"];
        ngc.cfg.GAME_FSADRRESS = fsUrl;
        ngc.pubUtils.setLocalDataJson("eMjFsUrl", {"fsUrl": fsUrl});
        this.checkIsGameing();
    },

    //获取公告信息成功
    getNotifcationSuccess: function (retJson) {
        var contentAry = [];
        var vo = retJson["vo"];
        if(vo){
            for(var k = 0, length = vo.length; k < length; ++k){
                var content = vo[k]["content"];
                contentAry.push(content);
            }
        }

        ngc.curUser.contentArry = contentAry;

        //var eMjFSData = ngc.pubUtils.getLocalDataJson("eMjFsUrl");
        //var fsUrl = eMjFSData.fsUrl;
        //if(eMjFSData && fsUrl){
        //    ngc.cfg.GAME_FSADRRESS = fsUrl;
        //    this.checkIsGameing();
        //}else{
        //    this.connectFS();
        //}

        if(ngc.cfg.GAME_FSADRRESS != ""){
            this.checkIsGameing();
        }else{
            this.connectFS();
        }

    },

    //检查是否同意用户协议
    checkIsUserAgreement:function(){
        var currentState = this._checkBoxBtn.isSelected();
        return currentState;
    },

    onWXLogin: function () {
        if(this.checkIsUserAgreement()){
            this.showLogining();
            LayerLogic.WXLogin(null);
        }else{
            var commonLayer = new ngc.game.layer.commonBigBombBoxLayer(1, true);
            this.addChild(commonLayer);
        }
    },

    showLogining:function(){
        if(!this.loginingNode){
            var loadInfo = ngc.uiUtils.loadJson(this, ngc.hall.jsonRes.logining);
            this.addChild(loadInfo.node);
            this.loginingNode=loadInfo;
        }
        this.loginingNode.node.setVisible(true);
        this.loginingNode.action.play("animation0",true);
    },
    hideLogining:function(){
        if(this.loginingNode)
            this.loginingNode.node.setVisible(false);
    },

    onVisitorLogin: function () {
        if(this.checkIsUserAgreement()){
            this.showLogining();
            var _locaData = ngc.pubUtils.getLocalDataJson("localUser");
            if (_locaData.token) {
                this.autoLogin(_locaData);
            } else {
                var postData = {};
                ngc.http.httpPostHs("/interface/base_guestGenerateAndLogin.do", postData, this._customEventName, "guestLogin");
                console.log("游客登录");
            }

        }else{
            var commonLayer = new ngc.game.layer.commonBigBombBoxLayer(1, true);
            this.addChild(commonLayer);
        }
    },

    //请求公告
    requestGetNotifcation: function () {
        var gameRoomId = ngc.curUser.gameRoomId;
        var postData = {
            gameRoomId: gameRoomId
        };
        ngc.http.httpPostHs("/interface/base_getnotifcation.do", postData, this._customEventName, "getNotifcation");
    },

    onHttpEvent: function(userData) {
        if(userData.errorCode !== 0){
            this.hideLogining();
            console.log("连接服务器失败");
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        switch (userData.data){
            case "login":
                if(retJson["response"] !== 1){
                    console.log(retJson["msg"]);
                    this.hideLogining();
                }
                else{
                    this.onLoginSuccess(retJson);
                }
                break;
            case "autoLogin":
                 this.onLoginSuccess(retJson);
                break;
            case "weixinLogin":
                 this.onLoginSuccess(retJson);
                break;
            case "guestLogin":
                 this.onLoginSuccess(retJson);
                break;
            case "getNotifcation":
                this.getNotifcationSuccess(retJson);
                break;
            case "FS":
                this.getFsSuccess(retJson);
                break;
            default:
                this.hideLogining();

                ngc.log.error("onHttpEvent data=" + userData.data);
                break;
        }
    },

    checkIsGameing:function(){
        this.loadGameRes();
        //这里面从jsb.sqlite中读取之前读取成功后的痕迹
        var eMjServerData = ngc.pubUtils.getLocalDataJson("eMjServerData");
        var ip = eMjServerData.ip;
        if(eMjServerData && ip){
            if(!this._layerNet){
                var layerNet = new ngc.game.net(null, null);
                this.addChild(layerNet);
                layerNet.setMaxReconnectedNum(0);
                this._layerNet = layerNet;
            }

            this._layerNet.changeCallBack(this.gameMessage, this);
            this._layerNet.setConnectFailedCallBack(this.checkIsGameingFailed, this);
            ngc.cfg.GAME_ADRRESS = ip;
            ngc.cfg.GAME_PORT = eMjServerData.port;
            this._layerNet.connectWs();
        }else{
            var _hallScene = new ngc.game.scene.HallScene();
            cc.director.pushScene(_hallScene);
        }
    },

    gameMessage:function(actionId,data){
        switch(data.action) {
            case 0:
                this.loginGame();
                break;
            case game_msgId_rcv.LOGIN_RESP:
                if(data["code"]==0) {
                    this.afterLoginGame(data);
                } else {
                    ngc.log.info(data);
                    this.checkIsGameingFailed();
                }
                break;
        }
    },

    checkIsGameingFailed:function(){
        ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
        ngc.log.info("check is gameing failed!");
        var _hallScene = new ngc.game.scene.HallScene();
        cc.director.pushScene(_hallScene);
    },

    loginGame:function(){
        var loginPack=new game_pack_template_send.LOGIN();
        loginPack.accessToken=ngc.curUser.access_token;
        loginPack.mac="AA-BB";
        loginPack.whereFrom = 2;
        loginPack.version = 1;
        this._layerNet.sendData(loginPack);
    },

    afterLoginGame:function(data){
        if(data["userState"]!=1){//(2)  非正常入座，断线重连
            var scene = new ngc.game.scene.main();
            cc.director.runScene(scene);
            this._layerNet.retain();
            this._layerNet.removeFromParent();
            scene.addNet(this._layerNet,{"creating":true}, data);
            this._layerNet.release();
            this._layerNet = null;
        }else{
            ngc.log.info("not in gameing!");
            ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
            var _hallScene = new ngc.game.scene.HallScene();
            cc.director.pushScene(_hallScene);
        }
    },

    loadGameRes:function(){
        var self = this;
        if(ngc.game&&ngc.game.jsFiles) return;
        cc.loader.loadJs(["src/g/mjBloody/resource.js"], function(err){
            ngc.game.resJs = "src/g/mjBloody/resource.js"
            if(err){
                self.clearGameRes();
                return;
            }
            cc.loader.loadJs(ngc.game.jsFiles, function(err){
                if(err){
                    self.clearGameRes();
                    return;
                }
            });
        });
    }
});



ngc.game.layer.quit=ngc.CLayerBase.extend({
    _exitImage:null,
    _exitText:null,
    target:null,
    callback:null,

    ctor:function(){
        this._super();
        this.myInit();
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.quitGame, true);
        this.mySetVisible(true);
        this._exitText.setVisible(false);
    },

    setText:function (str) {
        this._exitText.string = str;
        this._exitText.setVisible(true);
        this._exitImage.setVisible(false);
    },

    setFunc:function (callback, target,  str) {
        this.target = target;
        this.callback = callback;
        this.setText(str);
    },

    onCloseClick:function(){
        this.removeFromParent(true);
    },

    onQuitGameClick:function(){
        if(this.target && this.callback){
            this.callback.call(this.target);
            this.onCloseClick();
        }else{
            cc.director.end();
        }
    },

    showInScene:function(){
        var scene=cc.director.getRunningScene();
        if(scene){
            if(!scene.getChildByTag(111233478))
                scene.addChild(this,0,111233478);
        }
    }
})

/**
 * 供js调用微信登录
 *
 * @param {function}
 * cb 回调函数,第一个参数: -1被取消,-2被拒绝,其它对应平台状态码
 */

var LayerLogic = LayerLogic || {};

LayerLogic.WXLogin = function (cb) {
    this.WXLogin.cb = cb;
    if (cc.sys.os == cc.sys.OS_ANDROID) {
        jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "sendWXLoginRequest", "(Ljava/lang/String;)V", "");
    } else if (cc.sys.os == cc.sys.OS_IOS) {
        jsb.reflection.callStaticMethod("NGCWeiXinAgent", "sendWXLoginRequest:", "");
    }
};

LayerLogic.WXLoginRes = function (reCode, code, state) {
    if (reCode == 1) {
        var postData = {code: code};
        ngc.http.httpPostHs("/interface/base_wxlogin.do", postData, "httpLayerLogin", "weixinLogin");
        console.log("WXLoginRes回调被执行ss:" + reCode + ",code=" + code + ",state=" + state);
    } else {
        console.log("微信登陆失败");
    }


};
