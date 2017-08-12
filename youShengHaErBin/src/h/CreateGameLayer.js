/**
 * Created by admin on 2016/8/19.
 */

ngc.game.layer.CreateGameLayer = ngc.CLayerBase.extend({

    _customEventName:"createRoom",
    _haErBinBg:null,
    _haHeiLongJiangBg:null,
    _haErBinBtn:null,
    _heiLongJiangBtn:null,
    _haErBinNode:null,
    _heiLongJiangNode:null,

    _roomChekBox:null,
    _playText:null,
    _quanCheckBox:null,
    _peopleNumCheckBox:null,
    _playTypeCheckBox:null,
    _roundNum:1,


    ctor: function () {
        this._super();
        this._roomChekBox = [];
        this._quanCheckBox = [];
        this._playText = [];
        this._playTypeCheckBox = [];
        this._peopleNumCheckBox = [];

        this.myInit();
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.createGameLayer, true);
        this.mySetVisible(true);

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
    },

    onHttpEvent: function (userData) {
        if (userData.errorCode !== 0) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "获取服务器失败");
            this.addChild(commonLayer);
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        ngc.log.info("-=-=-=---retJson=-=-=" + JSON.stringify(retJson));
        if (retJson["retCode"] == 1) {
            switch (userData.data) {
                case "fs":
                    this.onFsSuccess(retJson);
                    break;
                default:
                    ngc.log.error("onHttpEvent data=" + userData.data);
                    break;
            }
        } else {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, retJson["msg"]);
            this.addChild(commonLayer);
            ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
        }
    },

    onEnter: function () {
        this._super();
        this._roundNum = 1;
    },

    onExit: function () {
        this._super();
    },

    onSure:function () {
        var eMjServerData = ngc.pubUtils.getLocalDataJson("eMjServerData");
        var ip = eMjServerData.ip;
        if(eMjServerData && ip){
            this.onInPutGame();
        }else{
            //创建网络模块
            var layerNet = new ngc.game.net(null, null);
            this.addChild(layerNet);
            layerNet.changeCallBack(this.gameMessage, this);
            layerNet.setConnectFailedCallBack(this.checkIsGameingFailed, this);
            layerNet.setMaxReconnectedNum(0);
            this._layerNet = layerNet;
            this.connectFs();
        }
    },

    //进入游戏
    onInPutGame: function () {
        var gameData = {
            isFind: 0,
            creating: true,
            totalRound: this._quanCheckBox[0].isSelected() ? 2 : 4,
            isChunJia: Number(this._playTypeCheckBox[0].isSelected()),   // 是否带纯夹
            isSanQiJia: Number(this._playTypeCheckBox[1].isSelected()),  // 是否带三期夹
            isZhanLiHu: 1,                                               // 是否带站立胡
            isLaizi: Number(this._playTypeCheckBox[4].isSelected()),     // 是否带红中宝
            isDanDiaoJia: Number(this._playTypeCheckBox[3].isSelected()),// 是否带单吊夹
            isGuaDaFeng: Number(this._playTypeCheckBox[5].isSelected()),  // 是否带刮大风
            isZhiDuiJia: 0,// 是否带支对胡
            isMenQing: 1, // 是否带门清
            isAnKe: 0,    // 是否带暗刻
            isKaiPaiZha: 1,// 是否开牌炸
            isBaoZhongBao: 0,// 是否宝中宝
            isHEBorDQ: 0
        };
        if(this._haHeiLongJiangBg.isVisible())
            gameData.isAnKe = 1;
        if(this._haErBinBg.isVisible())
            gameData.isBaoZhongBao = 1;

        var sene = new ngc.hall.SceneLoadGame(gameData);
        cc.director.runScene(sene);
    },

    //请求Fs
    connectFs:function(){
        var gameRoomId = ngc.curUser.gameRoomId;
        ngc.cfg.GAME_PORT = 8873;
        if(this._peopleNumCheckBox[1].isSelected()){
            gameRoomId = ngc.curUser.game3RenRoomId;
            ngc.cfg.GAME_PORT = 8876;
        }
        else if(this._peopleNumCheckBox[2].isSelected()){
            gameRoomId = ngc.curUser.game2RenRoomId;
            ngc.cfg.GAME_PORT = 8878;
        }

        var gameRoomTypeId = ngc.curUser.gameRoomTypeId;
        var accessToken = ngc.curUser.access_token;
        var postData = {
            "accessToken":accessToken,
            "jingWeiDu":"{'jingdu':'0.0','weidu':'0.0'}",
            "gameRoomId":gameRoomId,
            "gameRoomType":gameRoomTypeId,
            "isFind":0  ,     //创建房间的时候传 0 加入房间传1
            "tableNum":"" ,   //桌子号 穿件房间的时候传""  加入房间的时候传实际的房间号(string)
        };
        var fsUrl = ngc.cfg.GAME_FSADRRESS;
        ngc.http.httpPostFs(fsUrl, postData, this._customEventName, "fs");
    },

    onFsSuccess:function(jsonData){
        var data = jsonData["data"];
        var ip = data[0].ip;
        var port = data[0].port;
        ngc.cfg.GAME_ADRRESS = ip;
        ngc.cfg.GAME_PORT = port;
        ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": ip, "port": port});
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
                    //链接分发
                    this.connectFs();
                    //this.checkIsGameingFailed();
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
            this.onInPutGame();
        }
    },

    onRoomTouch:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        this.onInputRule(this._roomChekBox[tag], 2);
    },

    onInputRule:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        for(var k = 0; k < this._roomChekBox.length; ++k){
            if(this._roomChekBox[k])
              this._roomChekBox[k].setSelected(false);
        }
        this._roomChekBox[tag].setSelected(true);
    },


    onCircleRule:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        for(var k = 0;k < this._quanCheckBox.length; ++k){
            if(this._quanCheckBox[k])
                this._quanCheckBox[k].setSelected(false);
        }
        this._quanCheckBox[tag].setSelected(true);
    },

    onCircleTouchText:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        this.onCircleRule(this._quanCheckBox[tag], 2);
    },

    onPeopleRule:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        for(var k = 0;k < this._peopleNumCheckBox.length; ++k){
            if(this._peopleNumCheckBox[k])
                this._peopleNumCheckBox[k].setSelected(false);
        }
        this._peopleNumCheckBox[tag].setSelected(true);
    },

    onPeopleTouch:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        this.onPeopleRule(this._peopleNumCheckBox[tag], 2)
    },

    onGameType:function (sender, type) {
        if(type != 2) return;
        var tag = sender.getTag();
        if(this._playTypeCheckBox[tag].isSelected())
            this._playTypeCheckBox[tag].setSelected(false);
        else
            this._playTypeCheckBox[tag].setSelected(true);
    },


    onHaErBin:function () {
        this.setViewVisible(true);
    },

    onHeiLongJiang:function () {
        this.setViewVisible(false);
    },

    setViewVisible:function (visible) {
        this._haErBinNode.setVisible(visible);
        this._heiLongJiangNode.setVisible(!visible);
        this._playTypeCheckBox[6].setVisible(!visible);
        this._playText[6].setVisible(!visible);
        this._haErBinBg.setVisible(visible);
        this._haHeiLongJiangBg.setVisible(!visible);
    },

    onBackGameScene: function () {
        if (this._customEventListener) {
            cc.eventManager.removeListener(this._customEventListener);
            this._customEventListener = null;
        }
        this.removeFromParent(true);
    }
});