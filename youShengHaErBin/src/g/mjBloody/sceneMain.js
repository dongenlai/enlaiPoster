ngc.game.CSoundItem = cc.Class.extend({
    soundType: 0,
    res: ""
});

game_sound_type = {
    op: 1,
    voice: 2,
    chat: 3
};

game_chat_type = {
    text: 4,                                        // 文本
    emotion: 5,                                     // 表情
    fixedSound: 6,                                  // 固定短语
    image: 7                                       // 自定义图片
};

fixedSound_text = [
    "快点吧，我等的花都谢了！",
    "你打牌打得太好了!",
    "和你合作真是太愉快了!",
    "吐了个槽的，整一个杯具啊~",
    "唉…一手烂牌臭到底。",
    "不要吵啦，专心玩牌吧。",
];

ngc.game.CSoundCache = cc.Class.extend({
    _idList: null,

    ctor: function () {
        this.myClear();
    },

    pAddItem: function (userId, item) {
        this._idList[cc.formatStr("%d_%d", item.soundType, userId)] = item;
    },

    pNewItem: function (soundType, res) {
        var ret = new ngc.game.CSoundItem();
        ret.soundType = soundType;
        ret.res = res;

        return ret;
    },

    myClear: function () {
        this._idList = {};
    },

    myPlay: function () {
        for (var name in this._idList) {
            var item = this._idList[name];
            switch (item.soundType) {
                case game_sound_type.op:
                case game_sound_type.chat:
                    ngc.g_mainScene.getAudio().playGameSound(item.res);
                    break;
                case game_sound_type.voice:
                    /*var _time = ngc.g_mainScene.getVoiceTime();
                     if (_time && _time > 1) {
                     cc.audioEngine.pauseAllEffects();
                     cc.director.getScheduler().scheduleOnce(function() {
                     cc.audioEngine.resumeAllEffects();
                     }, _time, "pause");
                     }*/
                    ngc.g_mainScene.getAudio().playVoice(item.res);
                    break;
            }
        }
    },

    getSexSuffix: function (sex) {
        if (sex === 1)
            return "_M";
        else
            return "_W";
    },

    playOpSound: function (userId, resPath) {
        var item = this.pNewItem(game_sound_type.op, resPath);
        this.pAddItem(userId, item);
    },

    playVoice: function (userId, strVoice) {
        var item = this.pNewItem(game_sound_type.voice, strVoice);
        this.pAddItem(userId, item);
    },

    playChatSound: function (userId, resPath) {
        var item = this.pNewItem(game_sound_type.chat, resPath);
        this.pAddItem(userId, item);
    }
});

ngc.game.scene.main = cc.Scene.extend({
    _customEventListener1: null,
    _customEventListener2: null,
    table2d: null,
    table3d: null,
    _players: null,
    _selfCamera: null,

    selfDir: SitDir.EAST,
    chairIndexToDir: null,
    mjCardCountArray: null,
    _maJiangRenShu:4,

    pointer: null,
    tableNum: "209111",
    tableRound: 0,   //总牌局数
    curRound: 0,     //当前第几局
    ip: "",          //当前玩家ip地址

    _soundCache: null,
    _audio: null,
    _voiceTime: 0,

    net: null,

    _selfTip: null,

    _tableRunning: false,
    specialGang: 0,

    _packArray: [],//接收到的网络包的缓冲区
    _packDealing: false,//是否正在处理网络包

    _userIdAry: [null, null, null, null], //用户userIDArry
    _userSex: [null, null, null, null],   //用户user性别Arry
    _userNameAry: {                       //按照userID 存储用户名字
        "0": {userID: null, userName: null},
        "1": {userID: null, userName: null},
        "2": {userID: null, userName: null},
        "3": {userID: null, userName: null},
    },
    _clearTableLayer: null,               //散桌层

    ctor: function (noCreateSound) {
        this._super();
        this.pointer = null;
        this._userIdAry = [null, null, null, null];
        this._userSex = [null, null, null, null];
        this._clearTableLayer = null;
        this._userNameAry = {
            "0": {userID: null, userName: null},
            "1": {userID: null, userName: null},
            "2": {userID: null, userName: null},
            "3": {userID: null, userName: null},
        },

            ngc.g_mainScene = this;

        this.chairIndexToDir = {
            "0": SitDir.EAST,
            "1": SitDir.SOURTH,
            "2": SitDir.WEST,
            "3": SitDir.NORTH
        };

        this.mjCardCountArray = [34, 34, 34, 34];

        this._players = [null, null, null, null];

        this._selfCamera = null;

        this._packArray = [];
        this._packDealing = false;

        this._selfTip = null;

        if (cc.sys.os == cc.sys.OS_ANDROID) {
            cc.eventManager.addListener({
                event: cc.EventListener.KEYBOARD,
                onKeyReleased: function (keyCode, event) {
                    if (keyCode == cc.KEY.back) {
                        var quitLayer = new ngc.game.layer.quit();
                        quitLayer.showInScene();
                    }
                }
            }, this);
        }

        var layerBake = new cc.Layer();
        this.addChild(layerBake);
        var spriteBg = new cc.Sprite(ngc.game.pngRes.mainbg);
        spriteBg.setAnchorPoint(cc.p(0, 0));
        layerBake.addChild(spriteBg);
        layerBake.bake();
        layerBake.setCameraMask(cc.CameraFlag.USER3);

        var layerTable2d = new ngc.game.layer.table2d();
        layerTable2d.myInit();
        this.addChild(layerTable2d);
        this.table2d = layerTable2d;
        var layerTable3d = new ngc.game.layer.table3d();
        this.addChild(layerTable3d);
        this.table3d = layerTable3d;

        //if(!noCreateSound){
        this._audio = ngc.audio.getInstance();//new ngcc.CNgcAudio();
        this._audio.setVolumeVoice(1.0);
        //}
        this._soundCache = new ngc.game.CSoundCache();

        this.initCamera();

        //牌面
        cc.spriteFrameCache.addSpriteFrames("res/g/mjBloody/card/cards.plist");
    },

    //电玩厅公告未使用
    showGongGaoLayer: function () {
        var gameRoomId = ngc.curUser.gameRoomId;
        var notifiLayer = new ngc.game.layer.notifiLayer();
        notifiLayer.myInit(gameRoomId);
        this.addChild(notifiLayer, 100);
    },

    getVoiceTime: function () {
        return this._voiceTime;
    },

    setVoiceTime: function (time) {
        this._voiceTime = time;
    },

    getNet: function () {
        return this.net;
    },

    getAudio: function () {
        return this._audio;
    },

    getSoundCache: function () {
        return this._soundCache;
    },

    getCardResByValue: function (cardValue) {
        var type = Math.floor(cardValue / 9) + 1;
        var prefix = "";
        switch (type) {
            case 0:
            case CardType.WAN:
                prefix = "w_";
                break;
            case CardType.TONG:
                prefix = "tong_";
                break;
            case CardType.TIAO:
                prefix = "tiao_";
                break;
        }
        return prefix + ((cardValue % 9) + 1) + ".png";
    },

    changeMJCardValue: function (newCardValue, mjCard, mjcardclass) {
        if (newCardValue >= 0 && mjCard) {
            if (!mjCard.getChildByTag(223344)) {
                var spriteCardMesh3D = new jsb.Sprite3D();
                var sprite = cc.Sprite.create();
                var res = getCardResByValue(newCardValue);
                if (cc.spriteFrameCache.getSpriteFrame(res))
                    sprite.initWithSpriteFrameName(res);

                spriteCardMesh3D.addChild(sprite, 0, 112233);

                spriteCardMesh3D.setPosition3D(cc.math.vec3(0, -11, 0));
                if ((this._playerIndex == 0 || this._playerIndex == 3) && (mjcardclass == MJCardClass.CHU || mjcardclass == MJCardClass.HU || mjcardclass == MJCardClass.MING))
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90, 0, 0));
                else if (this._playerIndex == 0 && mjcardclass == MJCardClass.SHOU)
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90, 0, 0));
                else
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90, 180, 0));

                spriteCardMesh3D.setScale(0.33);
                spriteCardMesh3D.setScaleZ(0.33);

                mjCard.addChild(spriteCardMesh3D, 0, 223344);
            }
            else {
                var spriteCardMesh3D = mjCard.getChildByTag(223344);
                var sprite = spriteCardMesh3D.getChildByTag(112233);
                if (sprite) {
                    var res = getCardResByValue(newCardValue);
                    var frame = cc.spriteFrameCache.getSpriteFrame(res);
                    if (frame)
                        sprite.setSpriteFrame(frame);
                }
            }
        }
    },


    addMaJiang: function () {
        var pos = cc.math.vec3(510, cc.winSize.height / 2 - 220, -110);
        if (this._lastMJCard) {
            var pos = this._lastMJCard.getPosition3D();
            if (pos.x >= 830) {
                pos.x = 510;
                pos.z += 21;
            }
            else {
                pos.x += 16;
            }
        }
        var mjCard = ngc.game.createMj(0, MJCardClass.MING);//new jsb.Sprite3D(ngc.game.objRes.majiang);

        var randomValue = Math.round(Math.random() * 26);
        this.changeMJCardValue(randomValue, mjCard, MJCardClass.MING);


        mjCard.setCameraMask(cc.CameraFlag.USER1);
        mjCard.setLightMask(0);
        mjCard.setPosition3D(pos);

        //var lightMask=cc.LightFlag.LIGHT1|cc.LightFlag.LIGHT2|cc.LightFlag.LIGHT4;
        //mjCard.setLightMask(lightMask);
        //var children=mjCard.getChildren();
        //children[0].setLightMask(lightMask);
        //children[1].setLightMask(lightMask);
        this._layerTemp.addChild(mjCard);

        this._lastMJCard = mjCard;

        if (!this._mJNum) this._mJNum = 0;
        this._mJNum++;
        this._lable1.setString("麻将数量：" + this._mJNum);


    },


    addMaJiang2: function () {
        var pos = cc.math.vec3(490, cc.winSize.height / 2 - 220, -50);
        if (this._lastMJCard) {
            var pos = this._lastMJCard.getPosition3D();
            if (pos.x >= 840) {
                pos.x = 490;
                pos.z += 18;
            }
            else {
                pos.x += 13;
            }
        }
        cc.spriteFrameCache.addSpriteFrames("res/g/mjBloody/card/cards.plist");

        var mjCard = new jsb.Sprite3D(ngc.game.objRes.majiang_old);
        var randomValue = Math.round(Math.random() * 26);
        var res = getCardLocalResByValue(randomValue);
        var chidren = mjCard.getChildren();
        for (var i = 0; i < chidren.length; i++) {
            var child = chidren[i];

            var mesh = child.getMeshByIndex(0);
            if (mesh.getName() == "pai") {
                mesh.setTexture(res);
                break;
            }
        }

        mjCard.setCameraMask(cc.CameraFlag.USER1);
        mjCard.setPosition3D(pos);

        var lightMask = cc.LightFlag.LIGHT1 | cc.LightFlag.LIGHT2 | cc.LightFlag.LIGHT4;
        mjCard.setLightMask(lightMask);
        var children = mjCard.getChildren();
        children[0].setLightMask(lightMask);
        children[1].setLightMask(lightMask);
        this._layerTemp.addChild(mjCard);

        this._lastMJCard = mjCard;

        if (!this._mJNum) this._mJNum = 0;
        this._mJNum++;
        this._lable1.setString("麻将数量：" + this._mJNum);
    },

    addWG: function () {
        var pos = cc.math.vec3(540, cc.winSize.height / 2 - 220, -220);
        if (this._lastWG) {
            var pos = this._lastWG.getPosition3D();
            if (pos.x >= 800) {
                pos.x = 540;
                pos.z += 50;
            }
            else {
                pos.x += 30;
            }
        }
        var obj = new jsb.Sprite3D("res/g/mjBloody/obj/tortoise.c3b");
        obj.setCameraMask(cc.CameraFlag.USER1);
        obj.setPosition3D(pos);
        var lightMask = cc.LightFlag.LIGHT1 | cc.LightFlag.LIGHT2 | cc.LightFlag.LIGHT4;
        obj.setLightMask(lightMask);
        this._layerTemp.addChild(obj);
        obj.setScale(0.1);
        obj.setScaleZ(0.1);


        this._lastWG = obj;
        if (!this._wGNum) this._wGNum = 0;
        this._wGNum++;
        this._lable2.setString("乌龟数量：" + this._wGNum);
    },
    addCar: function () {
        var pos = cc.math.vec3(500, cc.winSize.height / 2 - 220, -100);
        if (this._lastCar) {
            var pos = this._lastCar.getPosition3D();
            if (pos.x >= 840) {
                pos.x = 500;
                pos.z += 20;
            }
            else {
                pos.x += 24;
            }
        }
        var obj = new jsb.Sprite3D("res/g/mjBloody/obj/boss.c3b");
        obj.setCameraMask(cc.CameraFlag.USER1);
        obj.setPosition3D(pos);
        var lightMask = cc.LightFlag.LIGHT1 | cc.LightFlag.LIGHT2 | cc.LightFlag.LIGHT4;
        obj.setLightMask(lightMask);
        this._layerTemp.addChild(obj);
        obj.setScale(2);
        obj.setScaleZ(2);


        this._lastCar = obj;
        if (!this._carNum) this._carNum = 0;
        this._carNum++;
        this._lable3.setString("飞车数量：" + this._carNum);
    },
    addRole: function () {
        var pos = cc.math.vec3(500, cc.winSize.height / 2 - 220, -220);
        if (this._lastRole) {
            var pos = this._lastRole.getPosition3D();
            if (pos.x >= 840) {
                pos.x = 500;
                pos.z += 40;
            }
            else {
                pos.x += 24;
            }
        }
        var obj = new jsb.Sprite3D("res/g/mjBloody/obj/orc.c3b");
        obj.setCameraMask(cc.CameraFlag.USER1);
        obj.setPosition3D(pos);
        var lightMask = cc.LightFlag.LIGHT1 | cc.LightFlag.LIGHT2 | cc.LightFlag.LIGHT4;
        obj.setLightMask(lightMask);
        this._layerTemp.addChild(obj);
        obj.setScale(2);
        obj.setScaleZ(2);


        this._lastRole = obj;
        if (!this._roleNum) this._roleNum = 0;
        this._roleNum++;
        this._lable4.setString("人物数量：" + this._roleNum);
    },

    clearObj: function () {
        this._layerTemp.removeAllChildren(true);

        this._lastMJCard = null;
        this._mJNum = 0;

        this._lastWG = null;
        this._wGNum = 0;

        this._carNum = 0;
        this._lastCar = null;

        this._lastRole = null;
        this._roleNum = 0;
    },

    turnonoroffLight: function () {
        if (!this._on) this._on = true;
        else this._on = !this._on;
        var spotColor = cc.color(255, 255, 255);
        if (this.checkSystemColor())
            spotColor = cc.color(80, 80, 80);
        if (!this._spotLight) {
            this._spotLight = new jsb.SpotLight(cc.math.vec3(0, -1, 0), cc.math.vec3(cc.winSize.width / 2, cc.winSize.height / 2 + 200, -100), spotColor, 0, 0, 10000);
            this._spotLight.setEnabled(true);
            this._spotLight.setLightFlag(cc.LightFlag.LIGHT1);
            this.addChild(this._spotLight);
        }
        this._spotLight.setEnabled(this._on);


        if (!this._directLight1) {
            var directLight = new jsb.DirectionLight(cc.math.vec3(0, -0.1, -0.035), spotColor);
            directLight.setEnabled(this._on);
            directLight.setLightFlag(cc.LightFlag.LIGHT2);
            this.addChild(directLight);
            this._directLight1 = directLight;
        }
        this._directLight1.setEnabled(this._on);

        if (!this._selfLight) {
            var directLight = new jsb.DirectionLight(cc.math.vec3(0, 0, -1), cc.color(255, 255, 255));
            directLight.setEnabled(this._on);
            directLight.setLightFlag(cc.LightFlag.LIGHT3);
            this.addChild(directLight);
            this._selfLight = directLight;
        }
        this._selfLight.setEnabled(this._on);

        if (!this._ambientLight) {
            this._ambientLight = new jsb.AmbientLight(cc.color(80, 80, 80));
            this._ambientLight.setEnabled(this._on);
            this._ambientLight.setLightFlag(cc.LightFlag.LIGHT4);
            this.addChild(this._ambientLight);
        }
        this._ambientLight.setEnabled(this._on);
    },

    turnonoroff2D: function () {
        this.table2d.setVisible(!this.table2d.isVisible());
    },

    turnonoroff3D: function () {
        this.table3d.setVisible(!this.table3d.isVisible());
        for (var key = 0 in this._players) {
            if (this._players[key]) {
                this._players[key].layerPart3d.setVisible(!this._players[key].layerPart3d.isVisible())
            }
        }
    },

    onEnter: function () {
        this._super();

        this.scheduleUpdate();

        var camera = cc.Camera.getDefaultCamera();
        camera.setDepth(3);

        //绑定事件
        var me = this;
        if (!this._customEventListener1) {
            this._customEventListener1 = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: OPEventName,
                callback: function (event) {
                    me.onOperationMessage(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener1, this);
        }
        if (!this._customEventListener2) {
            this._customEventListener2 = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: PackEventName,
                callback: function (event) {
                    me.endDealPack(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener2, this);
        }
    },

    onExit: function () {
        this._super();
        cc.eventManager.removeListener(this._customEventListener1);
        cc.eventManager.removeListener(this._customEventListener2);

        if (this.net) {
            this.net.closeWs();
            this.net = null;
        }

        this._customEventListener1 = null;
        this._customEventListener2 = null;
        this.table2d = null;
        this.table3d = null;
        this._players = null;
        this._selfCamera = null;
    },
    //相机和灯光
    initCamera: function () {
        var camera = new cc.Camera(cc.Camera.Mode.PERSPECTIVE, 28, cc.winSize.width / cc.winSize.height, 1, 1000);
        camera.setCameraFlag(cc.CameraFlag.USER1);
        camera.setDepth(1);
        camera.setPosition3D(cc.math.vec3(cc.winSize.width / 2, cc.winSize.height / 2 + 115, 201));
        camera.lookAt(cc.math.vec3(cc.winSize.width / 2, cc.winSize.height / 2, 100), cc.math.vec3(0, 1, 0));
        this._camera = camera;
        this.addChild(camera);

        var camera = new cc.Camera(cc.Camera.Mode.PERSPECTIVE, 28, cc.winSize.width / cc.winSize.height, 1, 1000);
        camera.setCameraFlag(cc.CameraFlag.USER4);
        camera.setDepth(4);     //手不被遮挡，所以是最高级
        camera.setPosition3D(cc.math.vec3(cc.winSize.width / 2, cc.winSize.height / 2 + 115, 201));
        camera.lookAt(cc.math.vec3(cc.winSize.width / 2, cc.winSize.height / 2, 100), cc.math.vec3(0, 1, 0));
        this.addChild(camera);


        //////
        //var spotColor=cc.color(255,255,255);
        //if(this.checkSystemColor())
        //    spotColor=cc.color(80,80,80);
        //this._spotLight = new jsb.SpotLight(cc.math.vec3(0, -1, 0), cc.math.vec3(cc.winSize.width/2,cc.winSize.height/2+200,-100), spotColor, 0, 0, 10000);
        //this._spotLight.setEnabled(true);
        //this._spotLight.setLightFlag(cc.LightFlag.LIGHT1);
        //this.addChild(this._spotLight);
        //
        //var directLight=new jsb.DirectionLight(cc.math.vec3(0,-0.1,-0.035),spotColor);
        //directLight.setEnabled(true);
        //directLight.setLightFlag(cc.LightFlag.LIGHT2);
        //this.addChild(directLight);
        //
        //var directLight=new jsb.DirectionLight(cc.math.vec3(0,0,-1),spotColor);
        //directLight.setEnabled(true);
        //directLight.setLightFlag(cc.LightFlag.LIGHT3);
        //this.addChild(directLight);
        //this._selfLight=directLight;
        //
        //this._ambientLight = new jsb.AmbientLight(cc.color(80,80,80));
        //this._ambientLight.setEnabled(true);
        //this._ambientLight.setLightFlag(cc.LightFlag.LIGHT4);
        //this.addChild(this._ambientLight);

        //var pointLight = new jsb.PointLight(cc.math.vec3(cc.winSize.width/2,cc.winSize.height/2-16,500),cc.color(180,180,180),400);
        //pointLight.setEnabled(false);
        //pointLight.setLightFlag(cc.LightFlag.LIGHT4);
        //this.addChild(pointLight);
        //this._pointLight=pointLight;


        var camera = cc.Camera.createOrthographic(cc.winSize.width, cc.winSize.height, 0, cc.winSize.width);
        camera.setCameraFlag(cc.CameraFlag.USER2);
        camera.setPosition3D(cc.math.vec3(0, 70, 200));
        camera.lookAt(cc.math.vec3(0, 0, 0), cc.math.vec3(0, 1, 0));
        camera.setDepth(2);
        this.addChild(camera);
        this._selfCamera = camera;


        var camera = new cc.Camera();
        camera.setCameraFlag(cc.CameraFlag.USER3);
        camera.initDefault();
        this.addChild(camera);
    },

    checkSystemColor: function () {
        if (cc.sys.os == cc.sys.OS_IOS) {
            return true;
        }
        else if (cc.sys.os == cc.sys.OS_ANDROID) {
            var factoryInfo = jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "getPhoneFactoryInfo", "()Ljava/lang/String;");
            if (factoryInfo.indexOf("xiaomi") >= 0) {
                return true;
            }
        }
        return false;
    },

    turnOffSelfLight: function (index) {
        if (!index)  index = 0
        var player = this.getPlayerByCIndex(index);
        var mjCards = player.layerPart3d.layerCard1.getChildren();
        for (var key = 0 in mjCards) {
            mjCards[key].setColor(cc.color(150, 150, 150));
            var child = mjCards[key].getChildren()[0];
            if (!child) continue;
            var child2d = child.getChildren()[0];
            if (!child2d) continue;
            child2d.setColor(cc.color(150, 150, 150));
        }
    },

    turnOnSelfLight: function (index) {
        if (!index) index = 0
        var player = this.getPlayerByCIndex(index);
        var mjCards = player.layerPart3d.layerCard1.getChildren();
        for (var key = 0 in mjCards) {
            mjCards[key].setColor(cc.color(255, 255, 255));
            var child = mjCards[key].getChildren()[0];
            if (!child) continue;
            var child2d = child.getChildren()[0];
            if (!child2d) continue;
            child2d.setColor(cc.color(255, 255, 255));
        }
    },

    getSelfCardCamera: function () {
        return this._selfCamera;
    },

    addPlayer: function (chairIndexInServer, userInfo, isSelf, ZScore, ip) {
        var dir = this.chairIndexToDir[chairIndexInServer];
        var player = new ngc.game.player(this, dir, userInfo, ZScore, ip);
        if (isSelf) {
            player.setSelf();
            var indexInClient = 0;
        }
        else {
            var indexInClient = this.convertSIndexToCIndex(chairIndexInServer);
        }
        player.addToCamera(2);
        player.setPlayerIndex(indexInClient);
        this._players[indexInClient] = player;

        this._userIdAry[indexInClient] = userInfo.userId;
        this._userSex[indexInClient] = userInfo.sex;
        //可以根据userID 找到用户名字  根据 userName 找到 userID
        this._userNameAry[indexInClient + ""].userID = userInfo.userId;
        this._userNameAry[indexInClient + ""].userName = userInfo.nickName;
        this.table2d.showHead(indexInClient, userInfo, ZScore, ip);

        this.checkSameIp(ip);
    },
    checkSameIp: function (ip) {
        var hasSame = 0;
        for (var i = 0; i < this._players.length; i++) {
            if (this._players[i]) {
                if (ip == this._players[i].ip) {
                    if (++hasSame >= 2) break;
                }
            }
        }
        if (hasSame >= 2 && !this.getChildByTag(327238)) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "牌桌有相同IP玩家存在");
            this.addChild(commonLayer, 0, 327238);
        }
    },

    removePlayerBySIndex: function (chairIndexInServer) {
        var indexInClient = this.convertSIndexToCIndex(chairIndexInServer);
        var player = null;
        for (var i = 0; i < this._players.length; i++) {
            if (this._players[i] && this._players[i].getPlayerIndex() == indexInClient) {
                player = this._players[i];
                this._players[i] = null;
                if (this._userIdAry[i]) this._userIdAry[i] = null;
                if (this._userSex[i]) this._userSex[i] = null;
                if (this._userNameAry[indexInClient + ""]) {
                    this._userNameAry[indexInClient + ""].userID = null;
                    this._userNameAry[indexInClient + ""].userName = null;
                }
                player.layerPart2d.removeFromParent(true);
                player.layerPart3d.removeFromParent(true);
                this.table2d.hideHead(indexInClient);
                this.table2d.showOfflineTip(indexInClient, PlayerNetState.tusNormal);
                break;
            }
        }
    },

    //根据服务端的serverindex获取玩家
    getPlayerBySIndex: function (chairIndexInServer) {
        var indexInClient = this.convertSIndexToCIndex(chairIndexInServer);
        return this.getPlayerByCIndex(indexInClient);
    },
    //根据客户端index获取玩家
    getPlayerByCIndex: function (indexInClient) {
        for (var i = 0; i < this._players.length; i++) {
            if (this._players[i] && this._players[i].getPlayerIndex() == indexInClient) {
                return this._players[i];
            }
        }
    },

    convertSIndexToCIndex:function(chairIndexInServer,option){
        if(this._maJiangRenShu == 2 && (!option||option == undefined))
        {
            if(chairIndexInServer == 1)
            {
                chairIndexInServer = 2;
            }
        }
        var dir=this.chairIndexToDir[chairIndexInServer];
        return ((this.selfDir-dir)+4)%4;
    },
    setDir:function(eastP,selftChairIndexInServer){
        if(this._maJiangRenShu == 2)
        {
            if(selftChairIndexInServer == 1)
            {
                selftChairIndexInServer = 2;
            }
        }
        this.chairIndexToDir[eastP.toString()]=SitDir.EAST;
        this.chairIndexToDir[(++eastP%4).toString()]=SitDir.SOURTH;
        this.chairIndexToDir[(++eastP%4).toString()]=SitDir.WEST;
        this.chairIndexToDir[(++eastP%4).toString()]=SitDir.NORTH;

        this.selfDir=this.chairIndexToDir[selftChairIndexInServer.toString()];
        this.table2d.setSelfDir(this.selfDir);
        this.table3d.setSelfDir(this.selfDir);
    },

    initCardCount: function (cards) {
        var ret=[0,0,0,0];
        for(var chairIndex=0 in cards){
            var indexInClient=this.convertSIndexToCIndex(parseInt(chairIndex),true);
            ret[indexInClient]=cards[parseInt(chairIndex)];
        }

        // var ret = [0, 0, 0, 0];
        // for (var chairIndex = 0 in cards) {
        //     var indexInClient = this.convertSIndexToCIndex(parseInt(chairIndex));
        //     ret[indexInClient] = cards[parseInt(chairIndex)];
        // }
        //this.mjCardCountArray[indexInClient]=eastCount;
        //this.mjCardCountArray[((indexInClient+1)%4)]=eastCount+2;
        //this.mjCardCountArray[((indexInClient+2)%4)]=eastCount;
        //this.mjCardCountArray[((indexInClient+3)%4)]=eastCount+2;
        return ret;
    },

    getTable2D: function () {
        return this.table2d;
    },

    movePointer: function (vec2Pos) {
        if (!this.pointer) {
            //this.pointer=new cc.Sprite(ngc.game.pngRes.pointer);
            //this.addChild(this.pointer);
            //var mv1=cc.moveBy(1.0,cc.p(0,20));
            //var mv2=mv1.reverse();
            //var seq=cc.sequence(mv1,mv2);
            //this.pointer.runAction(cc.repeatForever(seq));

            this.pointer = new jsb.Sprite3D(ngc.game.objRes.jianTou);
            this.pointer.setCameraMask(cc.CameraFlag.USER1);
            this.pointer.setLightMask(cc.LightFlag.LIGHT0);
            this.addChild(this.pointer);
        }
        this.pointer.setVisible(true);
        this.pointer.setPosition3D(vec2Pos);

        this.pointer.stopAllActions();
        var mv1 = cc.moveBy(1.0, cc.math.vec3(0, 16, 0));
        var mv2 = cc.moveBy(1.0, cc.math.vec3(0, -16, 0));
        var seq = cc.sequence(mv1, mv2);
        this.pointer.runAction(cc.repeatForever(seq));
    },
    hidePointer: function () {
        if (this.pointer) this.pointer.setVisible(false);
    },

    addNet: function (layerNet, gameData, loginData) {
        this.tableRound = gameData.totalRound || 0;  //牌局数
        this.ip = loginData["ip"];
        if (gameData.tableNum)
            this.tableNum = gameData.tableNum;
        this.addNetDelegate(layerNet);
        if (loginData["userState"] == 1) {//正常入座
            this.joinTableAction(gameData);
        } else if (gameData.creating) {//非正常入座
            var loadInfo = ngc.uiUtils.loadJson(this, ngc.game.jsonRes.paijuInfo);
            this.addChild(loadInfo.node);
            this.paijuInfo = loadInfo.node;
        }
    },

    onPaiJuClose: function () {
        if (this.paijuInfo) {
            this.paijuInfo.removeFromParent(true);
        }
    },

    addNetDelegate: function (netDelegate) {
        this.addChild(netDelegate);
        this.net = netDelegate;
        this.net.changeCallBack(this.onNetMessage, this);
        this.net.reset();
        this.net.setConnectFailedCallBack(this.connectedFailed, this);
        this.net.setReconnectingCallBack(this.connecting, this);
    },

    connectedFailed: function () {
        if (this._reconnectLayer) {
            this._reconnectLayer.removeMyLayer();
            this._reconnectLayer = null;
        }
        var commonLayer = new ngc.game.layer.commonBombBoxLayer(1, true, true);
        this.addChild(commonLayer);

        this.scheduleOnce(function () {
            var mainScene = new ngc.game.scene.HallScene();
            cc.director.runScene(mainScene);
        }, 3);
    },

    connecting: function () {
        var commonLayer = new ngc.game.layer.commonBombBoxLayer(0, true, false);
        this.addChild(commonLayer);
        this._reconnectLayer = commonLayer;
    },

    rmReconnectingLayer: function () {
        if (this._reconnectLayer) {
            this._reconnectLayer.removeMyLayer();
            this._reconnectLayer = null;
        }
    },

    /**
     * 加入牌局
     * @param isFind 是否是查找
     * @param totalRound
     */
    joinTableAction: function (gameData) {
        var pack = new game_pack_template_send.SIT();
        if (gameData.hasOwnProperty("vipRoomType")) {
            pack.vipRoomType = gameData.vipRoomType;
        } else {
            pack.vipRoomType = 3;
        }
        if (gameData.isFind != 0) {//加入牌局
            pack.isFind = 1;
            pack.tableNum = gameData.tableNum;
        } else {//创建牌局
            pack.isFind = 0;
            pack.totalRound = gameData.totalRound;
            pack.isChunJia = gameData.isChunJia;
            pack.isLaizi = gameData.isLaizi;
            pack.isGuaDaFeng = gameData.isGuaDaFeng;
            pack.isSanQiJia = gameData.isSanQiJia;
            pack.isDanDiaoJia = gameData.isDanDiaoJia;
            pack.isZhiDuiJia = gameData.isZhiDuiJia;
            pack.isZhanLiHu = gameData.isZhanLiHu;
            pack.isMenQing = gameData.isMenQing;
            pack.isAnKe = gameData.isAnKe;
            pack.isKaiPaiZha = gameData.isKaiPaiZha;
            pack.isBaoZhongBao = gameData.isBaoZhongBao;
            pack.isHEBorDQ = gameData.isHEBorDQ;
        }
        ngc.log.info("pack = " + JSON.stringify(pack));
        this.net.sendData(pack);
    },
    readyAction: function () {
        var pack = new game_pack_template_send.READY();
        this.net.sendData(pack);
    },
    dealCard: function (pack) {
        var index1 = this.convertSIndexToCIndex(pack.bankerP);
        var index2 = this.convertSIndexToCIndex(pack.startP);

        for (var key = 0 in this._players) {
            if (this._players[key]) {
                this._players[key].setUnBanker();
            }
        }

        var banker = this.getPlayerBySIndex(pack.bankerP);
        banker.setBanker();
        this.table2d.setNormalCount(3, banker.getPlayerIndex());

        this.table3d.setDicePoint(index1, index2, pack.dice0, pack.dice1);
        var allCards = this.initCardCount(pack.wallCount);
        var leftCards = this.initCardCount(pack.leftWallCount);
        this.table3d.initMJCards(allCards, leftCards);
        //设置自己的暗牌
        var player = this.getPlayerByCIndex(0);
        //打乱顺序
        pack.cards.sort(function (a, b) {
            return 0.5 - Math.random()
        });
        player.updateCards(pack.cards, 0, false);
        //开灯
        this.turnOnSelfLight();

        //设置其他玩家的暗牌
        for (var key = 0 in this._players) {
            var playerOther = this._players[key];
            if(playerOther){
                if (playerOther != player) {
                    var cards = [];
                    if (key == index1)
                        cards.length = 14;
                    else
                        cards.length = 13;

                    playerOther.updateCards(cards, 0, false);
                }
            }
        }

        //打骰子动画部分
        this.scheduleOnce(function () {
            //this.dealCardAni(1);
            // this.table3d.showBeginAni(this.dealCardAni, this, pack);

            if(this._maJiangRenShu == 4)
            {
                this.table3d.showBeginAni(this.dealCardAni,this,pack);  //测试使用
            }
            else if(this._maJiangRenShu == 2){
                this.table3d.showBeginAni(this.dealCardAniErRen,this,pack);  //测试使用

            }else if(this._maJiangRenShu == 3)
            {
                this.table3d.showBeginAni(this.dealCardAniSanRen,this,pack);  //测试使用
            }

        }, 0.8);

        this.table2d.setNormalCount(3, this.convertSIndexToCIndex(pack.bankerP), true);
        this.table2d.setTingStateVis();
    },


    dealCardAniErRen:function(firstIndex)
    {
        var initFirstIndex=firstIndex;
        for(var key=0 in this._players){
            if(this._players[key] == null)continue;
            this._players[key].refreshCardsInfo();
            var allDarkCards=this._players[key].getDarkCard(0);
            for(var key2=0 in allDarkCards){
                allDarkCards[key2].setVisible(false);
            }
        }

        var i=1;
        this.schedule(function(){
            if(i < 8){
                if(i == 7)
                    this.table3d.minusMJCardByNum(2);
                else
                    this.table3d.minusMJCardByNum(4);
            }
            var player;
            do {
                player = this.getPlayerByCIndex(firstIndex);
                firstIndex--;
                if(firstIndex<0)firstIndex=2;
            }while (player == undefined);
            if(i>6){
                player.receiveDealMjAni(4,true);
            }else {
                player.receiveDealMjAni(4,false);
            }
            i++;
        },0.1,7);

        //最后一张牌
        this.scheduleOnce(function(){
            var player=this.getPlayerByCIndex(initFirstIndex);
            var lastCard=player.getDarkCard(13,1);
            if(lastCard!=null&&lastCard.length>0) lastCard[0].removeFromParent(true);
            player.grabOneCardAni();
            this.table3d.minusMJCardByNum(1);
            // this.table3d.minusMJCardByNum(1, true);
        },3.8);

    },

    dealCardAniSanRen:function(firstIndex)
    {
        var initFirstIndex=firstIndex;
        for(var key=0 in this._players){
            if(this._players[key] == null)continue;
            this._players[key].refreshCardsInfo();
            var allDarkCards=this._players[key].getDarkCard(0);
            for(var key2=0 in allDarkCards){
                allDarkCards[key2].setVisible(false);
            }
        }

        var i=1;
        this.schedule(function(){
            if(i < 11) {
                if (i == 10)
                    this.table3d.minusMJCardByNum(3);
                else
                    this.table3d.minusMJCardByNum(4);
            }
            var player;
            do {
                player = this.getPlayerByCIndex(firstIndex);
                firstIndex--;
                if(firstIndex<0)firstIndex=3;
            }while (player == undefined);
            if(i > 9){
                player.receiveDealMjAni(4,true);
            }else {
                player.receiveDealMjAni(4,false);
            }
            i++;
        },0.1,11);

        //最后一张牌
        this.scheduleOnce(function(){
            var player=this.getPlayerByCIndex(initFirstIndex);
            var lastCard=player.getDarkCard(13,1);
            if(lastCard!=null&&lastCard.length>0) lastCard[0].removeFromParent(true);
            player.grabOneCardAni();
            this.table3d.minusMJCardByNum(1);
            // this.table3d.minusMJCardByNum(1, true);
        },3.8);

    },


    //发牌动画
    dealCardAni: function (firstIndex) {
        var initFirstIndex = firstIndex;

        for (var key = 0 in this._players) {
            if(this._players[key]){
                this._players[key].refreshCardsInfo();
                var allDarkCards = this._players[key].getDarkCard(0);
                for (var key2 = 0 in allDarkCards) {
                    allDarkCards[key2].setVisible(false);
                }
            }
        }

        var i = 1;
        this.schedule(function () {
            var num=4;
            if(i>12){
                num=1;
            }
            this.table3d.minusMJCardByNum(num);

            var player=this.getPlayerByCIndex(firstIndex);
            player.receiveDealMjAni(num);
            firstIndex--;
            if(firstIndex<0)firstIndex=3;
            i++;
        }, 0.1, 15);

        //最后一张牌
        this.scheduleOnce(function () {
            var player = this.getPlayerByCIndex(initFirstIndex);
            var lastCard = player.getDarkCard(13, 1);
            if (lastCard != null && lastCard.length > 0) lastCard[0].removeFromParent(true);
            player.grabOneCardAni();
            this.table3d.minusMJCardByNum(1);
        }, 3.8);
    },

    /**
     * 从服务端恢复桌子所有信息
     * @param pack
     */
    recoverTable: function (pack) {
        this._maJiangRenShu = pack.peopleNum;
        var index1 = this.convertSIndexToCIndex(pack.bankerP);
        var index2 = this.convertSIndexToCIndex(pack.startP);
        var banker = this.getPlayerBySIndex(pack.bankerP);
        banker.setBanker();

        this.table3d.setDicePoint(index1, index2, pack.dice0, pack.dice1);
        var allCardsNum = 0;
        for (var key = 0 in pack.wallCount) {
            allCardsNum += pack.wallCount[key];
        }

        var allCards = this.initCardCount(pack.wallCount);
        var leftCards = this.initCardCount(pack.leftWallCount);
        this.table3d.initMJCards(allCards, leftCards);

        var leftAllCardsNum = 0;
        for (var key = 0 in pack.leftWallCount) {
            leftAllCardsNum += pack.leftWallCount[key];
        }
        this.table3d.minusMJCardByNum(allCardsNum - leftAllCardsNum);

        //设置自己的暗牌
        var playerSelf = this.getPlayerByCIndex(0);
        playerSelf.updateCards(pack.selfCards, 0, false);
        var selfIsTrust = 0;     //自己是否托管

        for(var key=0 in pack.mingPai){
            var player=this.getPlayerBySIndex(parseInt(key));
            if(player){
                var cardsData=pack.mingPai[key]["data"];
                var cards=[];
                var anGangCards=[];
                for(var i=0 in cardsData){
                    if(cardsData[i]["a"]==opServerActionCodes.mjaPeng){
                        var pengary = cardsData[i]["c"].split(',');
                        cards.push(pengary[0],pengary[0],pengary[0]);
                    }else if(cardsData[i]["a"]==opServerActionCodes.mjaChi){
                        var chiCardValues = cardsData[i]["c"].split(',');
                        cards.push(parseInt(chiCardValues[0]), parseInt(chiCardValues[1]), parseInt(chiCardValues[2]));
                    }
                    else{   //杠
                        var gangAry = cardsData[i]["c"].split(',');
                        cards.push(gangAry[0],gangAry[0],gangAry[0],gangAry[0]);
                        if(cardsData[i]["a"]==opServerActionCodes.mjaAnGang){
                            anGangCards.push(gangAry[0],gangAry[0],gangAry[0]);
                        }
                    }
                    cards.push(-1);
                }
                player.updateCards(cards,1,false);
                player.updateCards(anGangCards,4,false);
            }
        }


        //显示打出去的牌信息
        for (var key = 0 in pack.zhuoPai) {
            var player=this.getPlayerBySIndex(parseInt(key));
            if(player){
                player.updateCards(pack.zhuoPai[key]["data"], 3, false);
            }
        }

        //if(this._maJiangRenShu == 2){
        //    pack.users = [{cardCount:14},{cardCount:14},{cardCount:14},{cardCount:14}]
        //}
        //
        //if(this._maJiangRenShu == 3) {
        //    pack.users = [{cardCount:13},{cardCount:13},{cardCount:13},{cardCount:13}]
        //}

        //显示胡牌信息
        for (var key = 0 in pack.users) {
            var player = this.getPlayerBySIndex(parseInt(key))
            if(player){
                //player.updateCards(pack.users[key]["huPai"], 2, false);
                //if (pack.users[key]["hasTing"]) {
                //    player.setTingState(true);
                //}
                if (player.getPlayerIndex() == 0) {//自己
                    //selfIsTrust = pack.users[key]["isTrust"];
                }
                else {
                    var cards = [];
                    cards.length = pack.users[key]["cardCount"];
                    player.updateCards(cards, 0, false);
                }
            }
        }
        //渲染牌
        for (var key = 0 in this._players) {
            if(this._players[key]){
                this._players[key].refreshCardsInfo();
                //检查听牌玩家
                if (this._players[key].getTingState()) {
                    this._players[key].layerPart3d.selfTingPaiShow();
                }
            }
        }
        //整理牌
        playerSelf.layerPart3d.arrangementDarkCards(true, true);
        //移动打出的最新牌的指示
        var player = this.getPlayerBySIndex(pack.lastChuPaiPlace);
        if (player)
            player.movePointerToLastCard();

        //显示自己的操作
        var actions = [opServerActionCodes.mjaPeng, opServerActionCodes.mjaAnGang,
            opServerActionCodes.mjaDaMingGang, opServerActionCodes.mjaJiaGang,
            opServerActionCodes.mjaSpecialGang, opServerActionCodes.mjaHu,
            opServerActionCodes.mjaChi
        ];

        var hasAction = false;
        for (var key = 0 in pack.mjAction) {
            for (var i = 0 in actions) {
                if (pack.mjAction[key]["a"] == actions[i]) {
                    hasAction = true;
                    break;
                }
            }
        }
        if (hasAction)
            playerSelf.setState(new PlayerStateData(PlayerState.YAOPAIING, pack));

        this.table2d.showTrustStatus(selfIsTrust);
        //显示是否可以查看听牌
        playerSelf.layerPart2d.parseAndSetTingPai(pack.mjAction);

        //显示桌子计时
        var curPlayer = this.getPlayerBySIndex(pack.curPlace);
        if (curPlayer)
            this.table2d.setNormalCount(pack.decTimeCount, curPlayer.getPlayerIndex());


        if (curPlayer && curPlayer.getPlayerIndex() == 0) {//自己
            curPlayer.layerPart3d.curState = curPlayer.layerPart3d.curState || {};
            curPlayer.layerPart3d.curState.state = PlayerState.MOPAISHOW;

            if (pack.mjAction.length > 0 && pack.mjAction[0]["a"] == opServerActionCodes.mjaChu) {
                this.table2d.showDiscardTipDelay();
            }

            for (var k = 0 in pack.mjAction) {
                if (pack.mjAction[k]["a"] == opServerActionCodes.mjaChu) {
                    playerSelf.layerPart3d.moveLastMjToMo();
                    break;
                }
            }
        }
    },

    changeOnePlayerStateBySIndex: function (serverIndex, state) {
        var player = this.getPlayerBySIndex(serverIndex);
        if (player)
            player.setState(state);
    },

    changeAllPlayerState: function (state) {
        for (var key = 0 in this._players) {
            this._players[key].setState(state);
        }
    },

    clearTable: function () {
        this.table2d.hideAll();
        this.table3d.removeAllCards();

        this.table2d.setSelfDir(this.selfDir);
        this.table3d.setSelfDir(this.selfDir);

        for (var key = 0 in this._players) {
            if (this._players[key]) {
                this._players[key].clearCards();
                this._players[key].setTingState(false);
            }
        }
        if (this.pointer)
            this.pointer.setVisible(false);
    },

    onOperationMessage: function (data) {
        switch (data.op) {
            case opSelfAction.mjSwap:
                var pack = new game_pack_template_send.SWAP_CARD();
                pack.cards = data.cards;
                this.net.sendData(pack);
                var self = this.getPlayerByCIndex(0);
                self.putSelectedToSwap();
                this.table2d.notVibrate = true;///停止震动提示
                break;
            case opSelfAction.mjAllLackTip:
                //this.changeAllPlayerState(PlayerState.DINGQUEING);
                //this.table2d.setNormalCount(10,0);//定缺计时
                break;
            case opSelfAction.mjLack:
                var pack = new game_pack_template_send.Lack();
                pack.delSuit = data.lack;
                this.net.sendData(pack);
                var self = this.getPlayerByCIndex(0);
                self.setTempLackCardType(data.lack);
                break;
            case opSelfAction.mjDiscard:
                var pack = {};
                var selfPlayer = this.getPlayerByCIndex(0);
                ngc.log.info("data.forceDisCard = " + data.forceDisCard);
                if (data.forceDisCard) {
                    var pack = new game_pack_template_send.Discard();
                    pack.cardId = data.cardId;
                    ngc.log.info("sendData = " + JSON.stringify(pack));
                    this.net.sendData(pack);
                    return;
                }
                if (selfPlayer.getTingState() == 1) {
                    ngc.log.info("mjDiscard-hasTing");
                    var eStr = selfPlayer.layerPart3d.getTingEstr(data.cardId);
                    pack = new game_pack_template_send.MJ_ACTION();
                    pack.mjAction = opServerActionCodes.mjaTing;
                    pack.eS = eStr;
                    this.net.sendData(pack);
                    return;
                } else if (selfPlayer.getTingState() == 2) {
                    ngc.log.info("mjDiscard-hasTingChi");
                    var eStr = selfPlayer.layerPart3d.getTingEstr(data.cardId);
                    pack = new game_pack_template_send.MJ_ACTION();
                    pack.mjAction = opServerActionCodes.mjaTingChi;
                    pack.eS = eStr;
                    this.net.sendData(pack);
                    return;
                } else if (selfPlayer.getTingState() == 3) {
                    ngc.log.info("mjDiscard-hasTingPeng");
                    var eStr = selfPlayer.layerPart3d.getTingEstr(data.cardId);
                    pack = new game_pack_template_send.MJ_ACTION();
                    pack.mjAction = opServerActionCodes.mjaTingPeng;
                    pack.eS = eStr;
                    this.net.sendData(pack);
                    return;
                }
                var pack = new game_pack_template_send.Discard();
                pack.cardId = data.cardId;
                this.net.sendData(pack);
                break;
            case opSelfAction.mjTakeCard:
                var pack = new game_pack_template_send.MJ_ACTION();
                pack.mjAction = data.code;
                //if(data.code==opServerActionCodes.mjaPass)
                //    pack.eS="";
                //else
                //    pack.eS=data.eStr;
                pack.eS = data.eStr || "";
                this.net.sendData(pack);
                break;
            case opSelfAction.mjCancelTrust:
                var pack = new game_pack_template_send.TRUST();
                pack.isTrust = 0;
                this.net.sendData(pack);
                break;
            case opSelfAction.mjContinueNextRound:
                this.clearTable();
                this.readyAction();
                break;
            case opSelfAction.mjQuit:
                var pack = new game_pack_template_send.Quit();
                this.net.sendData(pack);
                break;
            case opSelfAction.mjChaTing:
                var pack = new game_pack_template_send.ChaTing();
                this.net.sendData(pack);
                break;
        }
    },

    onNetMessage: function (actionId, data) {
        if (data["action"] == game_msgId_rcv.CONSUME_SPECIAL_GOLD_NOTIFY) {     //房卡消费单独处理
            var pack = new game_pack_template_rcv.CONSUME_SPECIAL_GOLD_NOTIFY(data);
            //房卡消费
            for (var key = 0 in pack.consumeSpecialGold) {
                if (pack.consumeSpecialGold[key].userId == ngc.curUser.baseInfo.userId) {
                    if (pack.consumeSpecialGold[key]["incSpecialGold"] != 0) {
                        ngc.curUser.baseInfo.specialGold += parseInt(pack.consumeSpecialGold[key]["incSpecialGold"]);
                        break;
                    }
                }
            }
            return;
        }
        if (data["action"] == game_msgId_rcv.RESULT_NOTIFY) {//一局结束，将没有显示的包丢弃
            this._packArray = [];
            this._packArray.push(data);
        }
        if (data["action"] == 0) {//重新连接上
            this.afterReConnected();
        }
        else {
            if (data["action"] == game_msgId_rcv.RESULT_NOTIFY) {
            } else
                this._packArray.push(data);
        }
    },

    update: function (dt) {
        this._audio.update();
        if (!this._packDealing && this._packArray.length > 0) {
            var data = this._packArray.shift();
            try {
                this.beginDealPack(data);
            }
            catch (ex) {
                this._packDealing = false;
                ngc.log.info(ex.message + "&&&&&" + ex.name + "&&&" + JSON.stringify(data));
            }
        }
        return;
    },

    beginDealPack: function (data) {
        ngc.log.info("---" + JSON.stringify(data));
        var actionId = data["action"];
        switch (actionId) {
            case game_msgId_rcv.LOGIN_RESP:
                if (data["code"] != 0) {
                    ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                    var mainScene = new ngc.game.scene.HallScene(data.msg);
                    cc.director.runScene(mainScene);
                }
                else if (data["userState"] == 1) {//桌子已经解散
                    ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                    var mainScene = new ngc.game.scene.HallScene("您长时间离开，已经退出房间");
                    cc.director.runScene(mainScene);
                }
                else {
                    this.ip = data["ip"];
                }
                break;
            case game_msgId_rcv.SIT_RESP:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.SET_RES(data);
                if (pack.code == 0) {
                    //this.table2d.showPareLoading(false);
                }
                else {//退出
                    ngc.log.info(data); ///登录失败
                    ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                    var mainScene = new ngc.game.scene.HallScene(data.msg);
                    cc.director.runScene(mainScene);
                }
                this._packDealing = false;
                break;
            case game_msgId_rcv.LEAVE_RESP:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.LEAVE_RESP(data);
                if (pack.code == 0 || pack.code == 2) {
                    this._packArray = [];
                    //this.net.closeWs();
                    if (pack.code == 0) {
                        ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                    }
                    var mainScene = new ngc.game.scene.HallScene();
                    cc.director.runScene(mainScene);
                }
                else {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, pack.msg);
                    this.addChild(commonLayer);
                }
                this.table2d.onQuitTipClose();
                this._packDealing = false;
                break;
            case game_msgId_rcv.CHATING_RESP:
                var pack = new game_pack_template_rcv.CHATING_RESP(data);
                if (pack.code == 0) {
                    var tingPaiData = {};
                    var hupais = pack.tingInfo.split(",");
                    for (var i = 0 in hupais) {
                        var one = hupais[i].split("^");
                        tingPaiData[0] = tingPaiData[0] || [];
                        tingPaiData[0].push({"hu": one[0], "fan": one[1], "lnum": one[2]});
                    }
                    this.removeChildByTag(133244);
                    var layer = new ngc.game.hupaiprompt();
                    layer.myInit();
                    this.addChild(layer, 0, 133244);
                    layer.setData(tingPaiData);
                    layer.showHuPai(0);
                    layer.repositionAndEvent();
                }
                else {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, pack.msg);
                    this.addChild(commonLayer);
                }
                break;
            case game_msgId_rcv.READY_RESP:
                var pack = new game_pack_template_rcv.READY_RESP(data);
                if (pack.code != 0) {
                    ngc.log.info(pack.msg);
                }
                break;
            case game_msgId_rcv.OTHER_READY_NOTIFY:
                var pack = new game_pack_template_rcv.OTHER_READY_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.userId);
                if (player.getPlayerIndex() == 0) {
                    this.table2d.removeResultOne();
                    this.table2d.removeRoundResult();
                    this.clearTable();
                }
                break;
            case game_msgId_rcv.OTHER_STATE_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.OTHER_STATE_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.place);
                if (player) {
                    this.table2d.showOfflineTip(player.getPlayerIndex(), pack.tuserState);
                }
                this._packDealing = false;
                break;
            case game_msgId_rcv.OTHER_LEAVE_NOTIFY:
                var pack = new game_pack_template_rcv.OTHER_LEAVE_NOTIFY(data);
                this.removePlayerBySIndex(pack.place);
                break;
            case game_msgId_rcv.BEGIN_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.BEGIN_NOTIFY(data);
                this.tableNum = data.tableNum;
                if (this.tableNum)
                    this.table2d._roomIdTxt.string = this.tableNum;

                this._maJiangRenShu = pack.userCount;

                this.huNo3Suit = pack.huNo3Suit;
                this.specialGang = pack.specialGang;
                this.jiaFan = pack.jiaFan;

                this.tableRound = pack.maxRound;
                this.curRound = pack.curRound;
                this.table2d.setPlayTypeText(pack);
                this.table2d.setRoundInfo(this.curRound, this.tableRound);

                this.setDir(pack.eastP, pack.chairIndex);
                this.addPlayer(pack.chairIndex, ngc.curUser.baseInfo, true, pack.ZScore, this.ip);
                this.readyAction();
                this._packDealing = false;
                break;
            case game_msgId_rcv.OTHER_ENTER_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.OTHER_ENTER_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.chairIndex);
                if (!player)
                    this.addPlayer(pack.chairIndex, pack.baseInfo, false, pack.ZScore, pack.ip);
                var indexIndex = this.convertSIndexToCIndex(pack.chairIndex);
                this.table2d.showOfflineTip(indexIndex, pack.tuserState);
                this._packDealing = false;
                break;
            case game_msgId_rcv.MSGID_CLIENT_G_TING_NOTIFY:
                this._packDealing = true;
                var self = this.getPlayerByCIndex(0);
                var pack1 = new game_pack_template_rcv.CHU_PAI_NOTIFY(data);

                if (data.tingType)
                    pack1.tingType = data.tingType;

                if (pack1.tingType == 1) {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "飘听", false);
                    this.addChild(commonLayer);
                } else if (pack1.tingType == 2) {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "清一色听", false);
                    this.addChild(commonLayer);
                } else if (pack1.tingType == 3) {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "混一色听", false);
                    this.addChild(commonLayer);
                } else if (pack1.tingType == 4) {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "飘清一色听", false);
                    this.addChild(commonLayer);
                } else if (pack1.tingType == 5) {
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "混清一色听", false);
                    this.addChild(commonLayer);
                }

                //听牌展示
                var tingplace = pack1.pos;
                var clientPlace = this.convertSIndexToCIndex(tingplace);
                var playerOther = this.getPlayerByCIndex(clientPlace);
                pack1.hasServerTing = true;

                this.changeOnePlayerStateBySIndex(pack1.pos, new PlayerStateData(PlayerState.CHUPAISHOW, pack1));
                if (playerOther) {
                    playerOther.layerPart3d.selfTingPaiShow(clientPlace);
                    playerOther.layerPart3d.removeClickEvent();
                    //播放吃碰音效
                    playerOther.layerPart3d.playChiPengHuEffect(opServerActionCodes.mjaTing);
                    var table2d = this.table2d;
                    table2d.showOPRSAni(this.convertSIndexToCIndex(tingplace), opServerActionCodes.mjaTing);
                }
                if (self.getPlayerIndex() == 0 && this._selfTip) {
                    var temp = this._selfTip;
                    this._selfTip = null;
                    temp.removeFromParent(true);
                }
                break;
            case game_msgId_rcv.SYN_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.SYN_NOTIFY(data);
                this.recoverTable(pack);

                this._tableRunning = true;
                //开局游戏开始隐藏掉邀请好友按钮
                this.table2d.hideInviteTip();

                this._packDealing = false;
                break;
            case game_msgId_rcv.DEALCARD_NOTIFY:
                this._packDealing = true;
                this.table2d.showPareLoading(false);
                var pack = new game_pack_template_rcv.DEALCARD_NOTIFY(data);
                this.dealCard(pack);
                this._tableRunning = true;
                //开局游戏开始隐藏掉邀请好友按钮
                this.table2d.hideInviteTip();
                //显示牌局信息
                this.tableRound = pack.maxRound;
                this.curRound = pack.curRound;
                this.table2d.setRoundInfo(this.curRound, this.tableRound);
                break;
            case game_msgId_rcv.MO_BAO_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.MO_BAO_NOTIFY(data);
                this.table3d.minusMJCardByNum(1);
                this.table3d.moBaoAction(pack);
                //this.changeAllPlayerState(new PlayerStateData(PlayerState.XUANPAIING,pack));
                //this.table2d.setNormalCount(pack.decTimeCount,0);

                this._packDealing = false;
                break;
            case game_msgId_rcv.SWAP_CARDRS_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.SWAP_CARDRS_NOTIFY(data);
                var self = this.getPlayerByCIndex(0);
                self.updateCards(pack.cards, 0, true);
                var addCards = pack.addCards.concat();
                self.setAddedCards(addCards);
                this.changeAllPlayerState(new PlayerStateData(PlayerState.XUANPAISHOW, pack));
                this.table2d.showSwapDes(pack.swapDirction, pack.delCards);
                break;
            case game_msgId_rcv.Lack_RES:
                //var self=this.getPlayerByCIndex(0);
                //self.setState(PlayerState.DINGQUESHOW);
                break;
            case game_msgId_rcv.LackRS_NOTIFY:
                var pack = new game_pack_template_rcv.LackRS_NOTIFY(data);
                //this.changeAllPlayerState(PlayerState.DINGQUESHOW);
                if (pack.pos != undefined) {
                    var player = this.getPlayerBySIndex(pack.pos);
                    if (player) {
                        this.table2d.setNormalCount(pack.decTimeCount, player.getPlayerIndex());
                        player.layerPart2d.setState(new PlayerStateData(PlayerState.MOPAISHOW, pack));
                        player.layerPart3d.curState = player.layerPart3d.curState || {};
                        player.layerPart3d.curState.state = PlayerState.MOPAISHOW;
                        if (player.getPlayerIndex() == 0) {//自己
                            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, false, "该您出牌了", false);
                            this.addChild(commonLayer);
                            this._selfTip = commonLayer;

                            this.table2d.showDiscardTipDelay();
                        }
                    }
                }
                break;
            case game_msgId_rcv.MO_PAI_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.MO_PAI_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.MOPAISHOW, pack));
                }

                this.table2d.setNormalCount(pack.decTimeCount, player.getPlayerIndex());
                this.table3d.minusMJCardByNum(1);
                break;
            case game_msgId_rcv.DISCARD_RESP:
                var pack = new game_pack_template_rcv.DISCARD_RESP(data);
                break;
            case game_msgId_rcv.CHU_PAI_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.CHU_PAI_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    ngc.log.info("打出去的牌记录1: " + pack.card);

                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.CHUPAISHOW, pack));
                    if (player.getPlayerIndex() == 0 && this._selfTip) {
                        var temp = this._selfTip;
                        this._selfTip = null;
                        temp.removeFromParent(true);
                    }


                }
                if (pack.clockSt == 2) {//等待动作,停止震动
                    this.table2d.notVibrate = true;
                }
                break;
            case game_msgId_rcv.PENG_GANG_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.PENG_GANG_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack));
                }

                // fix bug: 当自己不是碰杠玩家，可是自己手上有动作时导致按钮显示不出来的问题，
                //          比如其他玩家加杠，自己可以抢杠胡
                if ((player.playerIndex != 0) && this.hasCanOptAction(pack.mjAction)) {
                    var playerSelf = this.getPlayerByCIndex(0);
                    playerSelf.layerPart2d.removeOpSelectionSelf();
                    playerSelf.layerPart2d.showOpSelectionSelf(pack.mjAction);
                }
                ngc.log.info("PENG_GANG_NOTIFY pack.action--------------------------" + pack.action);
                if (pack.action == opServerActionCodes.mjaPeng || pack.action == opServerActionCodes.mjaDaMingGang) {
                    ngc.log.info("PENG_GANG_NOTIFY pack.action--------------------------" + pack.action);
                    var player = this.getPlayerBySIndex(pack.lpos);
                    if (player) {
                        ngc.log.info("PENG_GANG_NOTIFY finish");
                        player.removeLastDiscard(pack.card);
                        this.hidePointer();
                    }
                }

                var cplayer = this.getPlayerBySIndex(pack.cpos);
                if (cplayer)
                    this.table2d.setNormalCount(pack.decTimeCount, cplayer.getPlayerIndex());
                break;
            case game_msgId_rcv.CHI_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.CHI_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack));
                }
                if ((player.playerIndex != 0) && this.hasCanOptAction(pack.mjAction)) {
                    var playerSelf = this.getPlayerByCIndex(0);
                    playerSelf.layerPart2d.removeOpSelectionSelf();
                    playerSelf.layerPart2d.showOpSelectionSelf(pack.mjAction);
                }
                if (pack.action == opServerActionCodes.mjaChi) {
                    var player = this.getPlayerBySIndex(pack.lpos);
                    if (player) {
                        player.removeLastDiscard(pack.card);
                        this.hidePointer();
                    }
                }
                break;
            case game_msgId_rcv.TING_CHI_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.TING_CHI_NOTIFY(data);
                var pack1 = new game_pack_template_rcv.CHU_PAI_NOTIFY(data);
                var pack2 = new game_pack_template_rcv.CHI_NOTIFY(data);

                pack1.card = pack.chuCard;
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack1.pos, new PlayerStateData(PlayerState.CHUPAISHOW, pack1));
                }
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack2.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack2));
                }

                var tingplace = pack.pos;
                var clientPlace = this.convertSIndexToCIndex(tingplace);
                var playerOther = this.getPlayerByCIndex(clientPlace);
                pack1.hasServerTing = true;

                if (playerOther) {
                    playerOther.layerPart3d.selfTingPaiShow(clientPlace);
                    playerOther.layerPart3d.removeClickEvent();
                    //播放吃碰音效
                    playerOther.layerPart3d.playChiPengHuEffect(opServerActionCodes.mjaTing);
                    var table2d = this.table2d;
                    table2d.showOPRSAni(this.convertSIndexToCIndex(tingplace), opServerActionCodes.mjaTing);
                }
                if (player.getPlayerIndex() == 0 && this._selfTip) {
                    var temp = this._selfTip;
                    this._selfTip = null;
                    temp.removeFromParent(true);
                }

                break;
            case game_msgId_rcv.TING_PENG_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.TING_CHI_NOTIFY(data);
                var pack1 = new game_pack_template_rcv.CHU_PAI_NOTIFY(data);
                var pack2 = new game_pack_template_rcv.PENG_GANG_NOTIFY(data);
                pack1.card = pack.chuCard;
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack1.pos, new PlayerStateData(PlayerState.CHUPAISHOW, pack1));
                }
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack2.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack2));
                }

                var tingplace = pack.pos;
                var clientPlace = this.convertSIndexToCIndex(tingplace);
                var playerOther = this.getPlayerByCIndex(clientPlace);
                pack1.hasServerTing = true;

                if (playerOther) {
                    playerOther.layerPart3d.selfTingPaiShow(clientPlace);
                    playerOther.layerPart3d.removeClickEvent();
                    //播放吃碰音效
                    playerOther.layerPart3d.playChiPengHuEffect(opServerActionCodes.mjaTing);
                    var table2d = this.table2d;
                    table2d.showOPRSAni(this.convertSIndexToCIndex(tingplace), opServerActionCodes.mjaTing);
                }
                if (player.getPlayerIndex() == 0 && this._selfTip) {
                    var temp = this._selfTip;
                    this._selfTip = null;
                    temp.removeFromParent(true);
                }
                break;
            case game_msgId_rcv.SPECIAL_GANG_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.SPECIAL_GANG_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack));
                }
                if ((player.playerIndex != 0) && this.hasCanOptAction(pack.mjAction)) {
                    var playerSelf = this.getPlayerByCIndex(0);
                    playerSelf.layerPart2d.removeOpSelectionSelf();
                    playerSelf.layerPart2d.showOpSelectionSelf(pack.mjAction);
                }
                break;
            case game_msgId_rcv.HU_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.HU_NOTIFY(data);
                var player = this.getPlayerBySIndex(pack.pos);

                if (pack.scores && pack.scores.length > 0) {
                    for (var key = 0 in pack.scores) {
                        var player = this.getPlayerBySIndex(parseInt(key));
                        if (player) {
                            var nowScore = pack.scores[key];
                            player.pushToRefresh(nowScore);
                        }
                    }
                }
                if (player) {
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.HUPAISHOW, pack));
                }
                if (pack.isQiangGang == 1) {
                    // 如果是抢杠胡牌的话，要把加杠的数据变为碰
                    var chuPaiPlayer = this.getPlayerBySIndex(pack.lpos);
                    if (chuPaiPlayer) {
                        chuPaiPlayer.layerPart3d.mdfJiaGang2Peng(pack.card);
                    }

                }
                break;
            case game_msgId_rcv.TRUST_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.TRUST_NOTIFY(data);
                if (pack.userId == ngc.curUser.baseInfo.userId) {
                    this.table2d.showTrustStatus(pack.isTrust);
                }
                this._packDealing = false;
                break;
            case game_msgId_rcv.TRUST_RES:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.TRUST_RES(data);
                if (pack.code == 0) {
                    this.table2d.showTrustStatus(pack.isTrust);
                }
                this._packDealing = false;
                break;
            case game_msgId_rcv.RESULT_NOTIFY:
                this._packDealing = true;
                this._tableRunning = false;
                var pack = new game_pack_template_rcv.RESULT_NOTIFY(data);
                for (var key = 0 in pack.scores) {
                    var player = this.getPlayerBySIndex(parseInt(key));
                    if (player) {
                        player.setScore(pack.scores[key]["ZScore"]);
                        player.clearToRefresh();
                    }
                }
                var layerqq = this.table2d.showResultOne(pack);
                layerqq.mySetVisibleFalse();
                this.scheduleOnce(function () {
                    layerqq.mySetVisibleTrue();
                    this.table2d.stopCount();
                }, 1);
                this._packDealing = false;
                //this.clearTable();
                break;
            case game_msgId_rcv.TINGGANG_NOTIFY:
                this._packDealing = true;
                var pack = new game_pack_template_rcv.TINGGANG_NOTIFY(data);
                pack.action = 12;
                pack.card = -1;
                var player = this.getPlayerBySIndex(pack.pos);
                if (player) {
                    player.setTingState(true);
                    this.changeOnePlayerStateBySIndex(pack.pos, new PlayerStateData(PlayerState.YAPPAISHOW, pack));
                }
                if (player._playerIndex == 0) {
                    if (pack.tingType == 1) {
                        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "飘听", false);
                        this.addChild(commonLayer);
                    } else if (pack.tingType == 2) {
                        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "清一色听", false);
                        this.addChild(commonLayer);
                    } else if (pack.tingType == 3) {
                        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "混一色听", false);
                        this.addChild(commonLayer);
                    } else if (pack.tingType == 4) {
                        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "飘清一色听", false);
                        this.addChild(commonLayer);
                    } else if (pack.tingType == 5) {
                        var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "混清一色听", false);
                        this.addChild(commonLayer);
                    }
                }

                if (player) {
                    player.layerPart3d.selfTingPaiShow(player._playerIndex);
                    player.layerPart3d.removeClickEvent();
                    //播放吃碰音效
                    player.layerPart3d.playChiPengHuEffect(opServerActionCodes.mjaTingGang);
                    var table2d = this.table2d;
                    table2d.showOPRSAni(this.convertSIndexToCIndex(pack.pos), opServerActionCodes.mjaTingGang);
                }

                if ((player.playerIndex != 0) && this.hasCanOptAction(pack.mjAction)) {
                    var playerSelf = this.getPlayerByCIndex(0);
                    playerSelf.layerPart2d.removeOpSelectionSelf();
                }
                this.endDealPack();
                break;
            case game_msgId_rcv.END_ROUND:
                this._packDealing = true;
                this._tableRunning = false;
                var pack = new game_pack_template_rcv.END_ROUND(data);
                this.table2d.setRoundData(pack);
                if (!pack.isForceLeave) {
                    this.net.changeCallBack(null, null);
                    this._packArray = [];
                    this.net.closeWs();
                    this.net.unscheduleUpdate();
                    this.net.unscheduleAllCallbacks();
                }
                if (!pack.needShow) {//直接退出
                    var mainScene = new ngc.game.scene.HallScene("桌子已经解散");
                    cc.director.runScene(mainScene);
                }
                ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                this._packDealing = false;
                break;
            case game_msgId_rcv.CHAT_RESP:
                this.rcvPackChatResult(data);
                break;
            case game_msgId_rcv.OTHER_CHAT:
                this.rcvPackOtherChatNotify(data);
                break;
            case game_msgId_rcv.CLIENT_QUEST_CTRL_TABLE_RESP:
                if (data.code != 0) {
                    if (this._clearTableLayer) {
                        this._clearTableLayer.removeFromParent(true);
                        this._clearTableLayer = null;
                    }
                    var msg = data.msg;
                    var Msg = "";
                    if (msg.length > 7) {
                        var beforeStr = msg.substr(0, 7);
                        var endStr = msg.substr(7, msg.length);
                    }
                    Msg = beforeStr + "\n" + endStr;
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, Msg);
                    this.addChild(commonLayer);
                }
                break;
            case game_msgId_rcv.CLIENT_DISBAND_TABLE_NOTIFY:
                var curUserName = '';
                var offset = null;
                var userNameAry = this._userNameAry;
                //创建散桌层
                if (!this._clearTableLayer) {
                    var clearTableLayer = new ngc.game.clearTableLayer();
                    this.addChild(clearTableLayer, 100);
                    clearTableLayer.myInit(false, data.decTimeCount);
                    this._clearTableLayer = clearTableLayer;
                }
                for (var k = 0 in userNameAry) {
                    var userInfo = userNameAry[k];
                    if (userInfo.userID == data.userId) {
                        curUserName = userInfo.userName;
                        offset = parseInt(k);
                        this._clearTableLayer.initView(curUserName, data.ctrlCode, data.isAgree, offset);
                    }
                }
                //展示解散桌子界面
                //this.table2d.onRecvCtrlNotify(curUserName, data.ctrlCode, data.isAgree);
                break;
            case game_msgId_rcv.CLIENT_FORCE_LEAVE_NOTIFY:
                var msg = data.msg;
                var code = data.code;


                var Msg = "";
                if (msg.length > 7) {
                    var beforeStr = msg.substr(0, 7);
                    var endStr = msg.substr(7, msg.length);
                }
                Msg = beforeStr + "\n" + endStr;
                var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, Msg);
                this.addChild(commonLayer);
                if (this._clearTableLayer) {
                    this._clearTableLayer.removeFromParent(true);
                    this._clearTableLayer = null;
                }

                //散桌成功的时候清空 本地缓存的Ip
                this.table2d.showRoundResult();
                ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                this.net.closeWs();
                break;
        }
    },

    endDealPack: function () {
        this._packDealing = false;
    },

    rcvPackOtherChatNotify: function (json) {
        ngc.log.info(cc.formatStr("rcvPackOtherChatNotify fromId=%d len=%d", json["userId"], json["chatMsg"].length));
        this.showChatMsg(json);
    },

    rcvPackChatResult: function (json) {
        if (json["code"] !== 0) {
            //ngc.g_mainScene.showLayerHint("聊天消息失败");
            ngc.log.info("聊天消息失败");
            return;
        }

        json["userId"] = ngc.curUser.baseInfo.userId;
        this.showChatMsg(json);
    },

    showChatMsg: function (json) {
        var chatType = json["chatType"];
        switch (chatType) {
            case game_sound_type.voice:
                this._soundCache.playVoice(json["userId"], json["chatMsg"]);
                ngc.g_mainScene.getSoundCache().myPlay();
                break;
            case game_chat_type.emotion:
                var headImageAry = this.table2d._imageHeadAry;
                var userIdAry = this._userIdAry;
                for (var k = 0, length = userIdAry.length; k < length; ++k) {
                    if (userIdAry[k] && (userIdAry[k] === json["userId"])) {
                        var headImage = headImageAry[k];
                        var emotion = new cc.Sprite();
                        emotion.setPosition(headImage._getWidth() / 2, headImage._getHeight() / 2);
                        headImage.addChild(emotion);
                        var animation = cc.animationCache.getAnimation("chatEmotion_" + json["chatMsg"]);
                        if (animation) {
                            var delay = cc.delayTime(0.3);
                            var animate = cc.animate(animation);
                            emotion.runAction(cc.sequence(animate.repeat(4), delay, cc.removeSelf()));
                        }
                        break;
                    }
                }
                break;
            case game_chat_type.text:
                this.sayChatMsg(json);
                break;
            case game_chat_type.fixedSound:
                var tag = parseInt(json["chatMsg"]);
                var userSexAry = this._userSex;
                json["chatMsg"] = fixedSound_text[tag];
                this.sayChatMsg(json);
                var userIdAry = this._userIdAry;
                for (var k = 0, length = userIdAry.length; k < length; ++k) {
                    if (userIdAry[k] && (userIdAry[k] === json["userId"])) {
                        if (ngc.flag.SOUND_FLAG)
                            ngc.g_mainScene.getAudio().playGameSound("res/g/mjBloody/audio/chat/chat_" + (tag + 1) + this._soundCache.getSexSuffix(userSexAry[k]) + ".ogg");
                        break;
                    }
                }
                break;
            case game_chat_type.image:
                break;
            default :
                console.log("没有对应的聊天类型");
                break;
        }
    },
    //文字聊天儿
    sayChatMsg: function (json) {
        ngc.log.info("sayChatMsg");
        if (!json)
            return 0;
        var userId = json["userId"];
        var msg = json["chatMsg"];
        ngc.log.info("msg" + msg);
        var userIdAry = this._userIdAry;
        var headImageAry = this.table2d._imageHeadAry;
        for (var k = 0, length = userIdAry.length; k < length; ++k) {
            if (userIdAry[k] && (userIdAry[k] === json["userId"])) {
                var headImage = headImageAry[k];
                var chatNode = new ngc.game.layer.chatNode(4, msg);
                if (k == 1) {
                    chatNode.setJsonStr(ngc.game.jsonRes.layerChatNodeItem);
                    chatNode.setPosition(headImage._getWidth(), headImage._getHeight() * 2 + 60);
                } else if (k == 2) {
                    chatNode.setJsonStr(ngc.game.jsonRes.layerChatNodeItem);
                    chatNode.setPosition(headImage._getWidth() - 40, headImage._getHeight() - 40);
                } else if (k == 3) {
                    chatNode.setJsonStr(ngc.game.jsonRes.layerChatNodeItem2);
                    chatNode.setPosition(-80, headImage._getHeight() * 2 - 20);
                } else {
                    chatNode.setJsonStr(ngc.game.jsonRes.layerChatNodeItem);
                    chatNode.setPosition(headImage._getWidth() + 20, headImage._getHeight() * 2 + 40);
                }
                headImage.addChild(chatNode, 10);
                break;
            }
        }
    },

    loginGame: function () {
        var loginPack = new game_pack_template_send.LOGIN();
        loginPack.accessToken = ngc.curUser.access_token;
        loginPack.mac = "AA-BB";
        loginPack.whereFrom = 2;
        loginPack.version = 1;
        this.net.sendData(loginPack);
    },

    afterReConnected: function () {
        var net = this.net;
        this.net = null;
        net.retain();
        net.removeFromParent();
        var scene = new ngc.game.scene.main(true);
        //scene._audio=this._audio;
        cc.director.runScene(scene);
        scene.addNetDelegate(net);
        scene.loginGame();          //重新登录
        net.release();
    },

    hasCanOptAction: function (mjActionList) {
        if (mjActionList.length <= 0)
            return false;
        for (var key = 0 in mjActionList) {
            var mjaAciton = mjActionList[key]["a"];
            if ((mjaAciton == opServerActionCodes.mjaChi) || (mjaAciton == opServerActionCodes.mjaPeng) ||
                (mjaAciton == opServerActionCodes.mjaDaMingGang) || (mjaAciton == opServerActionCodes.mjaAnGang) ||
                (mjaAciton == opServerActionCodes.mjaJiaGang) || (mjaAciton == opServerActionCodes.mjaHu) || (mjaAciton == opServerActionCodes.mjaTingGang)) {
                return true;
            }
        }
    },

    hasCanTingChiPengAction: function (mjActionList) {
        if (mjActionList.length <= 0)
            return false;
        for (var key = 0 in mjActionList) {
            var mjaAciton = mjActionList[key]["a"];
            if ((mjaAciton == opServerActionCodes.mjaTingChi) || (mjaAciton == opServerActionCodes.mjaTingPeng)) {
                return true;
            }
        }
    }
});
