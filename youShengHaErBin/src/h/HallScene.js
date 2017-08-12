/**
 * Created by admin on 2016/8/19.
 */

ngc.hideicon = ngc.hideicon || true;

ngc.game.scene.HallScene = ngc.CSceneBase.extend({

    _logo: null,
    _volumeNum: null,
    _cardNum: null,
    _nameTxt: null,
    _iconImage:null,
    _exchangeBtn: null,
    _shopBtn: null,
    _volumePanel: null,
    _cardPanel: null,
    //公告
    _Sprite_3:null,
    _bulletinText: '',
    _userIDTxt:null,
    /*
      加入房间不成功后传过来的参数需要在HallScene 弹框
    */
    ctor: function (msg) {
        this._super();
        this.myInit();
        if(cc.isString(msg)){
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(3, true, true, msg);
            this.addChild(commonLayer);
        }
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.hallScene);
        this.refreshIcon();
        this.scheduleUpdate();

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
    },

    onLianXi:function () {
        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "敬请期待！");
        this.addChild(commonLayer);
    },

    //设置头像
    refreshIcon:function(){
        if(ngc.curUser.contentArry.length > 0)
            this._bulletinText.setString(ngc.curUser.contentArry[0]);
        //标题
        //this._bulletinText.string = "请各位玩家文明娱乐，远离赌博，如发现有赌博行为，将封停账号，并向公安机关举报！";
        var user = ngc.curUser;
        var faceUrl = user.baseInfo.calcFaceUrl();
        if (faceUrl.length > 0) {
            this._iconImage.setScale(1.4);
            var data = {type: "selfFace"};
            if (cc.sys.os == cc.sys.OS_IOS) {//ios 头像无法载入bug暂行办法
                JsbBZ.loadHeadImage(this._iconImage, faceUrl, this._customEventNameUrlImage, data);
                return;
            }
            ngc.uiUtils.replaceTextureUrl(this._iconImage, faceUrl, null, null);
        }else {
            var _file = "res/hallUi/a/head.png";
            this._iconImage.setTexture(_file);
        }

    },

    //刷新公告
    update:function(dt){
        var bulletinText = this._bulletinText;
        if (bulletinText) {
            if (bulletinText.x > -bulletinText.getContentSize().width) {
                bulletinText.x -= 3;
            }else {
                bulletinText.x = 700;
                //公告刷新判断
                if(ngc.curUser.contentArry.length != 0){
                   var random = Math.floor(Math.random() * ngc.curUser.contentArry.length);
                    if(ngc.curUser.contentArry[random])
                        bulletinText.setString(ngc.curUser.contentArry[random]);
                    else
                        bulletinText.setString("没有配置公告信息！");
                      //  bulletinText.setString("请各位玩家文明娱乐，远离赌博，如发现有赌博行为，将封停账号，并向公安机关举报！");

                }

            }
        }

    },

    onEnter: function () {
        this._super();
        this._volumeNum.string = 0;
        this._cardNum.string = ngc.curUser.baseInfo.specialGold;
        this._nameTxt.string = ngc.curUser.baseInfo.nickName;
        this._userIDTxt.string = ngc.curUser.baseInfo.userId;
        // if(!ngc.game.scene.HallScene.hasShowedGongGao){
        //     var _noticeLayer = new ngc.game.layer.NoticeLayer(9);
        //     this.addChild(_noticeLayer);
        //     ngc.game.scene.HallScene.hasShowedGongGao=true;
        // }
        cc.sys.garbageCollect();
    },

    onExit: function () {
        this._super();
        //cc.audioEngine.end();
    },

    onShop:function () {
        var shopLayer = new ngc.game.layer.shopLayer();
        shopLayer.myInit();
        this.addChild(shopLayer);
    },

    onKeFu:function () {
        var keFuLayer = new ngc.game.layer.keFuLayer();
        keFuLayer.myInit();
        this.addChild(keFuLayer);
    },

    onHelp:function () {
        this.onWanFa();
    },

    onGongGao:function () {
        var gongGaoLayer = new ngc.game.layer.gongGaoLayer();
        gongGaoLayer.myInit();
        this.addChild(gongGaoLayer);
    },

    onSport:function () {
        var sportLayer = new ngc.game.layer.sportLayer();
        sportLayer.myInit();
        this.addChild(sportLayer);
    },

    onCreateGame: function () {
        var _createGameLayer = new ngc.game.layer.CreateGameLayer();
        this.addChild(_createGameLayer);
    },

    onJoinGame: function () {
        var eMjServerData = ngc.pubUtils.getLocalDataJson("eMjServerData");
        if(eMjServerData && eMjServerData.ip){
            this.redirectToGame();
        }
        else{
            var _joinGameLayer = new ngc.game.layer.JoinGameLayer();
            this.addChild(_joinGameLayer);
        }
    },

    onShare:function(){
        var shareLayer = new ngc.game.layer.shareLayer();
        shareLayer.myInit();
        this.addChild(shareLayer);
    },

    onWanFa:function(){
        var _aboutLayer = new ngc.game.layer.AboutLayer("wanfa");
        this.addChild(_aboutLayer);
    },

    redirectToGame:function(){
        var gameData={
            isFind:1,
            tableNum:"",
            creating:true
        };

        if(this._layerNet){
            this._layerNet.removeFromParent(true);
            this._layerNet = null;
        }

        var scene=new ngc.hall.SceneLoadGame(gameData);
        cc.director.runScene(scene);
    },


    onZhanJi:function(){
        var layer = new ngc.game.layer.zhanJiLayer();
        layer.myInit();
        this.addChild(layer);
    },

    onSetting: function () {
        var _settingLayer = new ngc.game.layer.SettingLayer();
        this.addChild(_settingLayer);
    },

    onExchange: function () {
        var _exchangeLayer = new ngc.game.layer.scoreLayer();
        _exchangeLayer.myInit();
        this.addChild(_exchangeLayer);
    },

    // 购买卷
    onGetVolume: function () {

    },

    onGetCard: function () {
        var _aboutLayer = new ngc.game.layer.AboutLayer();
        this.addChild(_aboutLayer);
    },

    onPersonInfo: function () {
        return;
        var _personInfoLayer = new ngc.game.layer.PersonInfoLayer();
        _personInfoLayer.myInit();
        this.addChild(_personInfoLayer);
    }

});

ngc.game.scene.HallScene.hasShowedGongGao=false;