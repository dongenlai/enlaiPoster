ngc.game.resultone=ngc.CGameLayerBase.extend({
    _bankmk:[],
    _head:[],
    _nameLabel:[],
    _conLabel:[],
    _mjMode:[],
    _listView:[],
    _scoreLable:[],
    _huMk:[],
    _uiBg:null,
    _layerMain:null,
    _rsImg:null,
    _btnContinue : null,
    _btnAll : null,
    _playType : null,
    _huValue: [],
    _huCard: [],
    _cellBg0:null,
    _cellBg1:null,
    _cellBg2:null,
    _cellBg3:null,

    myInit:function(){
        this._huValue = [];
        this._huCard = [];
        this._bankmk = [];
        this._head = [];
        this._nameLabel = [];
        this._conLabel = [];
        this._mjMode = [];
        this._listView = [];
        this._scoreLable = [];
        this._huMk = [];

        this._super(ngc.game.jsonRes.layerResultOne);
        this.mySetVisibleTrue();

        var scene = ngc.g_mainScene;

        if(scene._maJiangRenShu == 2){
            this._cellBg2.setVisible(false);
            this._cellBg3.setVisible(false);
        }

        if(scene._maJiangRenShu == 3){
            this._cellBg3.setVisible(false);
        }

        this.bascTimesType = [
            {name:"平胡",res:"res/g/mjBloody/ui/fff3.png"},
            {name:"摸宝",res:"res/g/mjBloody/ui/fff7.png"},
            {name:"摸红中",res:"res/g/mjBloody/ui/fff3.png"},
            {name:"刮大风",res:"res/g/mjBloody/ui/fff10.png"},
            {name:"宝中宝",res:"res/g/mjBloody/ui/fff10.png"},
        ];

        this.timesType = [
            {name:" 基本胡", res:""},
            {name:" 上听", res:""},
            {name:" 点炮", res:""},
            {name:" 开门", res:""},
            {name:" 自摸", res:""},
            {name:" 门清", res:""},
            {name:" 暗刻", res:""},
            {name:" 平胡", res:""},
            {name:" 夹胡", res:""},
            {name:" 自摸", res:""},
            {name:" 摸宝", res:""},
            {name:" 门清", res:""},
            {name:" 宝中宝", res:""},
            {name:" 庄家", res:""},
        ];
    },

    setData: function(data) {
        var selfTimesNum = 0;
        var scene = ngc.g_mainScene;
        for (var i = 0; i < data.scores.length; ++i) {
            var info = data.scores[i];
            var userInfo = info.userInfo;
            var player = scene.getPlayerBySIndex(i);
            this._nameLabel[i].setString(userInfo.nickName);
            var faceUrl = userInfo.faceUrl;
            if (this._head[i] && faceUrl) {
                var scene = cc.director.getRunningScene();
                var _table2d = scene.table2d;
                if (_table2d) {
                    _table2d.onChangeIcon(this._head[i], faceUrl);
                }
            }

            if (!info.isBanker) {
                this._bankmk[i].setVisible(false);
            }

            var _allSc = info.sumFans > 0 ? ("+" + info.sumFans) : info.sumFans;
            this._scoreLable[i].setString(_allSc);
            if (userInfo.userId == ngc.curUser.baseInfo.userId)
                selfTimesNum = info.sumFans;

            var processCon = this.generateDetailScoreStr(data, i);
            var posX = this._nameLabel[i].getPositionX() + this._nameLabel[i].getContentSize().width;
            this._conLabel[i].setPositionX(posX + 14);
            if(player.getTingState()){
                processCon += "已听牌，";
            }
            this._conLabel[i].setString(processCon);
        }

        if (selfTimesNum <= 0){
            this._rsImg.loadTexture("res/g/mjBloody/ui/r22.png", ccui.Widget.LOCAL_TEXTURE);
        }
    },

    generateDetailScoreStr: function(data, index) {
        var processCon = "";
        var resultInfo = data["result" + index];
        var cardInfo = data["cards" + index];
        if(!resultInfo && !cardInfo) return;
        this._mjMode[index].setVisible(false);
        var pos = this._mjMode[index].getParent().convertToNodeSpace(this._mjMode[index].getPosition());
        for (var m = 0; m < cardInfo.length; ++m){
            var _cardV = cardInfo[m];

            if (typeof(_cardV) == "object") {
                _cardV = _cardV.cardValue;
            }

            if (_cardV != -1) {
                var sprite = this.generateOneCard(_cardV);
                sprite.setPosition (pos);
                this.addChild(sprite);
                pos.x += 45;
            } else {
                pos.x += 25;
            }
        }

        for (var i = 0; i < resultInfo.length; ++i) {
            var rInfo = resultInfo[i];
            var scores = rInfo.scores;
            var fanZhong = rInfo.fanZhong;
            var _fIdx = fanZhong[0];
            var isWinner = rInfo.isWinner;

            for(var k = 1; k < fanZhong.length; ++k) {
                if (fanZhong[k] > 0){
                    processCon += this.timesType[k].name;
                }
            }
            processCon += this.bascTimesType[_fIdx].name;
            if (isWinner) {
                var _file = getCardLocalResByValue(data.scores[index].huPai[0]);
                this._huValue[index].setTexture(_file);
                this._huCard[index].setVisible(true);
                this._huMk[index].setVisible(true);
            }


            processCon += scores > 0 ? "+" + scores : scores;
        }

        return processCon;
    },

    generateOneCard:function(cardValue){
        var sprite=new cc.Sprite("res/g/mjBloody/ui/mjbg.png");
        if(cardValue>=0){
            var sprite2=new cc.Sprite(getCardLocalResByValue(cardValue));
            sprite2.setPosition(cc.p(sprite.getContentSize().width/2,sprite.getContentSize().height/2+10));
            sprite2.setScale(0.40);
            sprite.addChild(sprite2);
        }
        return sprite;
    },

    changeToLastRound:function(){
        this._btnContinue.setVisible(false);
        this._btnAll.setVisible(true);
    },

    onCloseClick:function(){
        this.removeFromParent(true);
    },

    onContinueClick:function(){
        this.removeFromParent(true);
        var data={
            op:opSelfAction.mjContinueNextRound
        };
        cc.eventManager.dispatchCustomEvent(OPEventName, data);
    },

    onAllScoreClick:function(){
        var scene=this.getParent();
        scene.table2d.showRoundResult();
        this.removeFromParent(true);
    },

    onScreenCutClick:function() {
        var winSize = cc.director.getWinSize();
        var render = new cc.RenderTexture(winSize.width, winSize.height);
        render.begin();
        this.visit();
        render.end();

        var date = new Date();
        var month = (date.getMonth() + 1) < 10 ? ("0" + (date.getMonth() + 1)) : (date.getMonth() + 1);
        var hours = (date.getHours() + 1) < 10 ? ("0" + (date.getHours() + 1)) : (date.getHours() + 1);
        var minutes = (date.getMinutes() + 1) < 10 ? ("0" + (date.getMinutes() + 1)) : (date.getMinutes() + 1);
        var seconds = (date.getSeconds() + 1) < 10 ? ("0" + (date.getSeconds() + 1)) : (date.getSeconds() + 1);
        var nameJPG = "IMG_" + date.getFullYear() + month + date.getDate() + "_" + hours + minutes + seconds + ".jpg";
        render.saveToFile(nameJPG, cc.IMAGE_FORMAT_JPEG);

        this.runAction(cc.sequence(cc.delayTime(0.5), cc.callFunc(function () {
            if (cc.sys.os == cc.sys.OS_ANDROID) {
                jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "screenShot", "(Ljava/lang/String;Ljava/lang/String;)V", jsb.fileUtils.getWritablePath(), nameJPG);
                ShareBZ.doShare(1, 4, nameJPG, "哈尔滨麻将", ngc.cfg.shareUrlN, "玩麻将~，创建私局，邀请好友一起玩。玩游戏，赢话费，秒变土豪！", 0, function () {
                    //console.log("截屏保存成功！");
                });
            } else if (cc.sys.os == cc.sys.OS_IOS) {
                jsb.reflection.callStaticMethod("RootViewController", "screenShot:withInfo:", jsb.fileUtils.getWritablePath(), nameJPG);
                ShareBZ.doShare(1, 4, nameJPG, "哈尔滨麻将", ngc.cfg.shareUrlN, "玩麻将~，创建私局，邀请好友一起玩。玩游戏，赢话费，秒变土豪！", 0, function () {
                    //console.log("截屏保存成功！");
                });
            }
        })));
    }
});

ngc.game.resultall=ngc.CGameLayerBase.extend({
    _lblDate:null,
    _lblTime:null,
    _lblRoom:null,
    _lblRound:null,

    _imgHead:[],
    _lblName:[],
    _lblID:[],
    _lbl_1_t:[],
    _lbl_2_t:[],
    _lbl_3_t:[],
    _lbl_4_t:[],
    _lbl_5_t:[],
    _lbl_all:[],

    _a9_5:null,
    _a9_6:null,
    _a9_7:null,
    _a9_8:null,

    _caculateState:null, //结算标志位
    _bigWinner:null,
    _ownerMark:null,

    ctor:function(){
        this._super();
        this._imgHead=[];
        this._lblName=[];
        this._lblID=[];
        this._lbl_1_t=[];
        this._lbl_2_t=[];
        this._lbl_3_t=[];
        this._lbl_4_t=[];
        this._lbl_5_t=[];
        this._lbl_all=[];
        this._bigWinner=[];
        this._ownerMark=[];
    },

    myInit:function(){
        this._super(ngc.game.jsonRes.layerResultAll);
        this.mySetVisibleTrue();

        var gameScene = ngc.g_mainScene;

        if(gameScene._maJiangRenShu == 2){
            this._a9_7.setVisible(false);
            this._a9_8.setVisible(false);
            this._a9_5.setPosition(418.77, 357.38);
            this._a9_6.setPosition(916.90, 357.38);
        }

        if(gameScene._maJiangRenShu == 3){
            this._a9_8.setVisible(false);
            this._a9_5.setPosition(235.70, 360.39);
            this._a9_6.setPosition(663.31, 360.39);
            this._a9_7.setPosition(1090.92, 360.39);
        }


        var tableNum =  gameScene.tableNum||"223308";
        var totalRound = gameScene.tableRound||"3";
        this._lblRoom.setString(tableNum.toString());
        this._lblRound.setString(totalRound.toString());

        var date = new Date();
        var month = (date.getMonth() + 1) < 10 ? ("0" + (date.getMonth() + 1)) : (date.getMonth() + 1);
        var hours = (date.getHours() ) < 10 ? ("0" + (date.getHours() )) : (date.getHours() );
        var minutes = (date.getMinutes() + 1) < 10 ? ("0" + (date.getMinutes() + 1)) : (date.getMinutes() + 1);
        var seconds = (date.getSeconds() + 1) < 10 ? ("0" + (date.getSeconds() + 1)) : (date.getSeconds() + 1);
        this._lblDate.setString(date.getFullYear() +"-"+ month+"-" + date.getDate());
        this._lblTime.setString(hours +":"+ minutes+":" + seconds);
    },
    setData:function(data){
        var scene=cc.director.getRunningScene();
        var maxScorePos={score:0,pos:0};
        for(var key=0 in data["countInfo"]){
           var one=data["countInfo"][key];
           var index=parseInt(key);
           if(one.userInfo){
               if(this._imgHead[index]&&one.userInfo.faceUrl){
                   var scene=cc.director.getRunningScene();
                   scene.table2d.onChangeIcon(this._imgHead[index],one.userInfo.faceUrl)
               }
               if(this._lblName[index])
                   this._lblName[index].setString(one.userInfo.nickName);
           }
            if(this._lblID[index])
                this._lblID[index].setString("ID:"+one.userId);

            if(this._lbl_1_t[index])
                this._lbl_1_t[index].setString(one.cntZiMoHu>0?"+"+one.cntZiMoHu:one.cntZiMoHu.toString());

            if(this._lbl_2_t[index])
                this._lbl_2_t[index].setString(one.cntZhuoPaoHu>0?"+"+one.cntZhuoPaoHu:one.cntZhuoPaoHu.toString());

            if(this._lbl_3_t[index])
                this._lbl_3_t[index].setString(one.cntDianPao>0?"+"+one.cntDianPao:one.cntDianPao.toString());

            if(this._lbl_4_t[index])
                this._lbl_4_t[index].setString(one.cntMingGang>0?"+"+one.cntMingGang:one.cntMingGang.toString());

            if(this._lbl_5_t[index])
                this._lbl_5_t[index].setString(one.cntAnGang>0?"+"+one.cntAnGang:one.cntAnGang.toString());

            if(this._lbl_all[index]){
                this._lbl_all[index].setString(one.ZScore>0?"+"+one.ZScore:one.ZScore.toString());
            }
            if(one.ZScore>maxScorePos.score){
                maxScorePos.score=one.ZScore;
                maxScorePos.pos=index;
            }
        }
        try{
            if(this._bigWinner[maxScorePos.pos]) this._bigWinner[maxScorePos.pos].setVisible(true);
            if(data.createPlace!=undefined&&this._ownerMark[parseInt(data.createPlace)])
                this._ownerMark[parseInt(data.createPlace)].setVisible(true);
        }
        catch(ex){
            ngc.log.info(ex.name+"&&&&&"+ex.message);
        }
    },

    onCloseClick:function(){
        //var scene=this.getParent();
        //scene.table2d.removeRoundResult();
        var mainScene = new ngc.game.scene.HallScene();
        cc.director.runScene(mainScene);
    },

    onScreenCutClick:function() {
        var winSize = cc.director.getWinSize();
        var render = new cc.RenderTexture(winSize.width, winSize.height);
        render.begin();
        cc.director.getRunningScene().visit();
        render.end();

        var date = new Date();
        var month = (date.getMonth() + 1) < 10 ? ("0" + (date.getMonth() + 1)) : (date.getMonth() + 1);
        var hours = (date.getHours() + 1) < 10 ? ("0" + (date.getHours() + 1)) : (date.getHours() + 1);
        var minutes = (date.getMinutes() + 1) < 10 ? ("0" + (date.getMinutes() + 1)) : (date.getMinutes() + 1);
        var seconds = (date.getSeconds() + 1) < 10 ? ("0" + (date.getSeconds() + 1)) : (date.getSeconds() + 1);
        var nameJPG = "IMG_" + date.getFullYear() + month + date.getDate() + "_" + hours + minutes + seconds + ".jpg";
        render.saveToFile(nameJPG, cc.IMAGE_FORMAT_JPEG);

        this.runAction(cc.sequence(cc.delayTime(0.5), cc.callFunc(function () {
            if (cc.sys.os == cc.sys.OS_ANDROID) {
                jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "screenShot", "(Ljava/lang/String;Ljava/lang/String;)V", jsb.fileUtils.getWritablePath(), nameJPG);
                ShareBZ.doShare(1, 4, nameJPG, "哈尔滨麻将", ngc.cfg.shareUrlN, "玩麻将~，创建私局，邀请好友一起玩。玩游戏，赢话费，秒变土豪！", 0, function () {
                    //console.log("截屏保存成功！");
                });
            } else if (cc.sys.os == cc.sys.OS_IOS) {
                jsb.reflection.callStaticMethod("RootViewController", "screenShot:withInfo:", jsb.fileUtils.getWritablePath(), nameJPG);
                ShareBZ.doShare(1, 4, nameJPG, "哈尔滨麻将", ngc.cfg.shareUrlN, "玩麻将~，创建私局，邀请好友一起玩。玩游戏，赢话费，秒变土豪！", 0, function () {
                    //console.log("截屏保存成功！");
                });
            }

        })));
    },

    onContinueClick:function() {
        var mainScene = new ngc.game.scene.HallScene();
        cc.director.runScene(mainScene);
    }
});