/**
 * Created by admin on 2016/8/19.
 */

ngc.game.layer.JoinGameLayer = ngc.CLayerBase.extend({
    _numBtn: [],
    _textInPut: null,
    _customEventListener:null,
    _customEventName: "getServerrData_JoinGameLaye",
    _layerNet:null,

    ctor: function () {
        this._super();
        this.myInit();
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.joinGameLayer, true);
        this.mySetVisible(true);
        this.setAnchorPoint(cc.p(0, 0));
        this._regCallback();

        if(!this._customEventListener){
            var self = this;
            this._customEventListener = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName:self._customEventName,
                callback: function(event){
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener, this);
        }

        //添加网络模块
        var layerNet = new ngc.game.net(null, null);
        this.addChild(layerNet);
        layerNet.changeCallBack(this.gameMessage, this);
        layerNet.setConnectFailedCallBack(this.checkIsGameingFailed, this);
        layerNet.setMaxReconnectedNum(0);
        this._layerNet = layerNet;

    },

    //请求Fs
    connectFs:function(){
        // var gameRoomId = ngc.curUser.gameRoomId;
        var gameRoomTypeId = ngc.curUser.gameRoomTypeId;
        var accessToken = ngc.curUser.access_token;
        var postData = {
            "accessToken":accessToken,
            "jingWeiDu":"{'jingdu':'0.0','weidu':'0.0'}",
            // "gameRoomId":gameRoomId,
            "gameRoomType":gameRoomTypeId,
            "isFind":1  ,    //创建房间的时候传 0 加入房间传1
            "tableNum":this._textInPut.string,   //桌子号 穿件房间的时候传""  加入房间的时候传实际的房间号(string)
        };
        var fsUrl = ngc.cfg.GAME_FSADRRESS;
        ngc.http.httpPostFs(fsUrl, postData, this._customEventName, "fs");
    },

    onHttpEvent: function (userData) {
        if (userData.errorCode !== 0) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "获取服务器失败");
            this.addChild(commonLayer);
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        if (retJson["retCode"] == 1) {
            switch (userData.data) {
                case "fs":
                    this.onFsSuccess(retJson);
                    break;
                default:
                    ngc.log.error("onHttpEvent data=" + userData.data);
                    break;
            }
        } else if(retJson["retCode"] == 3) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "房间号错误");
            this.addChild(commonLayer);
            ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
        }else{
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, retJson["msg"]);
            this.addChild(commonLayer);
            ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
        }
    },

    onFsSuccess:function(jsonData){
        ngc.log.info(jsonData);
        if (this._customEventListener) {
            cc.eventManager.removeListener(this._customEventListener);
            this._customEventListener = null;
        }
        var data = jsonData["data"];
        var ip = data[0].ip;
        var port = data[0].port;
        ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": ip, "port": port});
        ngc.cfg.GAME_ADRRESS = ip;
        ngc.cfg.GAME_PORT = port;
        //连接webSocket
        var layerNet = this._layerNet;
        layerNet.connectWs();
    },

    gameMessage:function(actionId, data){
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
        ngc.log.info("check is gameing failed!");
        ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
        var _hallScene = new ngc.game.scene.HallScene();
        cc.director.pushScene(_hallScene);
    },

    loginGame:function(){
        var loginPack = new game_pack_template_send.LOGIN();
        loginPack.accessToken = ngc.curUser.access_token;
        loginPack.mac = "AA-BB";
        loginPack.whereFrom = 2;
        loginPack.version = 1;
        var layerNet = this._layerNet;
        layerNet.sendData(loginPack);
    },

    afterLoginGame:function(data){
        if(data["userState"] != 1){//非正常入座，断线重连
            var scene = new ngc.game.scene.main();
            cc.director.runScene(scene);
            this._layerNet.retain();
            this._layerNet.removeFromParent();
            scene.addNet(this._layerNet, {"creating":true}, data);
            this._layerNet.release();
            this._layerNet = null;
        }else{
            ngc.log.info("not in gameing!");
            this.inPutRoom();
        }
    },

    onInPutGame:function(){
        var eMjServerData = ngc.pubUtils.getLocalDataJson("eMjServerData");
        var ip = eMjServerData.ip;
        if(eMjServerData && ip){
            this.inPutRoom();
        }else{
            this.connectFs();
        }
    },

    inPutRoom:function () {
        var gameData={
            isFind:1,
            tableNum:this._textInPut.string,
            creating:true,
            piaoType:0
        };

        if(this._layerNet){
            this._layerNet.removeFromParent(true);
            this._layerNet = null;
        }

        var scene=new ngc.hall.SceneLoadGame(gameData);
        cc.director.runScene(scene);

    },

    onEnter: function () {
        this._super();
    },

    onExit: function () {
        this._super();
        this._numBtn.length = 0;
        this._textInPut.string = "";
    },

    onDelNum: function () {
        var str = this._textInPut.string;
        str = str.slice(0, str.length - 1);
        this._textInPut.string = str;
    },

    onAgainInput: function () {
        this._textInPut.string = "";
    },
    
    onClose: function () {
        this.removeFromParent(true);
    },

    _regCallback: function () {
        var _btnArr = this._numBtn;
        var self = this;
        for (var i = 0; i < _btnArr.length; ++i) {
            var _btn = _btnArr[i];
            (function (idx) {
                console.log("idx = " + i);
                _btn.addTouchEventListener(function (sender, type) {
                    if (type == ccui.Widget.TOUCH_ENDED) {
                        var len = self._textInPut.string.length;
                        if(len <= 6)
                            self._textInPut.string += idx;
                        if (len == 5) {
                            cc.log("join Game");
                            var eMjServerData = ngc.pubUtils.getLocalDataJson("eMjServerData");
                            var ip = eMjServerData.ip;
                            if(eMjServerData && ip){
                                self.onInPutGame();
                            }else{
                                self.connectFs();
                            }
                        }
                    }
                });
            })(i);
        }
    },

});