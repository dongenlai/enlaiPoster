
ngc.game.recorder=ngc.game.recorder||{};
ngc.game.recorder.layer = ngc.game.recorder.layer||{};
ngc.game.layer.recorder = ngc.game.layer.recorder ||{};

ngc.game.recorder.package = (function(){
    return {
        chairIndex : -1,
        json : null
    }
});

ngc.game.scene.tablePalyerScene=  ngc.game.scene.main.extend({
    preTime:0,
    // 回放时的控制
    _isDealCard:false,//保证UI交互只触发一次
    _isSwapedCard:false,

    _chatBtn:null,
    _voiceBtn:null,
    lReplayControl:null,
    _localFiles:null,
    _selfChairIndex:0,
    ctor:function(noCreateSound){
        this._super(noCreateSound);
        ngc.log.info("ctor called");

        //this.initCamera();
        //this.openGameMedia();
    },
    onExit:function(){
        this._super();
        cc.director.getScheduler().setTimeScale(1);
    },
    setLocalFiles:function(localFiles){
        this._localFiles=localFiles;
    },
    initScene:function(){
        ngc.log.info("initScene");
        var layerBake=new cc.Layer();
        this.addChild(layerBake);
        var spriteBg=new cc.Sprite(ngc.game.pngRes.mainbg);
        spriteBg.setAnchorPoint(cc.p(0,0));
        layerBake.addChild(spriteBg);
        layerBake.bake();
        layerBake.setCameraMask(cc.CameraFlag.USER3);

        var layerTable2d=new ngc.game.layer.tablePlayer2d();
        layerTable2d.myInit();
        this.addChild(layerTable2d);
        this.table2d=layerTable2d;
        var layerTable3d=new ngc.game.layer.recorder.table3d();
        this.addChild(layerTable3d);
        this.table3d=layerTable3d;
        //if(!noCreateSound){
        this._audio = ngc.audio.getInstance();//new ngcc.CNgcAudio();
        this._audio.setVolumeVoice(1.0);
        //}
        this._soundCache = new ngc.game.CSoundCache();

        this.initCamera();
        var control = new ngc.game.recorder.layer.CReplayControl();
        control.myInit();
        this.lReplayControl = control;
        this.addChild(control,9999);
    },
    openPlayerScene:function(){
        // var tablePlayer = new ngc.game.scene.tablePalyerScene();
        // cc.director.pushScene(tablePlayer);
    },
    turnOnOtherLight:function(chairIndex) {
        var player = this.getPlayerBySIndex(chairIndex);
        var mjCards=player.layerPart3d.layerCard1.getChildren();
        for(var key=0 in mjCards){
            mjCards[key].setColor(cc.color(255,255,255));
            var child=mjCards[key].getChildren()[0];
            if(!child) continue;
            var child2d=child.getChildren()[0];
            if(!child2d) continue;
            child2d.setColor(cc.color(255,255,255));
        }
    },
    update:function(dt){
        if (this._isPause) {
            return;
        }
        if(!this._hasBegined){
            return;
        }
        this._audio.update();
        if (this.preTime < 10*1/this._animateSpeed) {
            this.preTime ++;
            return;
        }
        else{
            this.preTime = 0;
        }

        if(this._packArray.length>0){//!this._packDealing&&
            var data=this._packArray.shift();
            // ngc.log.info("update："+JSON.stringify(data));
            try{
                this.beginDealPack(data);
            }
            catch (ex){
                this._packDealing=false;
                ngc.log.info(ex.message+"&&&&&"+ex.name+"&&&"+ex.fileName+"&&&"+ex.lineNumber+"&&&"+JSON.stringify(data));
            }
        }
        else {
            this.lReplayControl.onPlayOrPause();
            this._isPlaying=false;
        }
        return;
    },
    setMainScene:function () {
        // override the parent implement
    },
    dealCard:function(pack){
        var index1=this.convertSIndexToCIndex(pack.bankerP);
        var index2=this.convertSIndexToCIndex(pack.startP);
        for(var key=0 in this._players){
            if(this._players[key]){
                this._players[key].setUnBanker();
            }
        }
        var banker=this.getPlayerBySIndex(pack.bankerP);
        banker.setBanker();
        this.table2d.setNormalCount(3,banker.getPlayerIndex());
        this.table3d.setDicePoint(index1,index2,pack.dice0,pack.dice1);
        var allCards=this.initCardCount(pack.wallCount);
        var leftCards=this.initCardCount(pack.leftWallCount);
        this.table3d.initMJCards(allCards,leftCards);

        //设置自己的暗牌
        var player=this.getPlayerByCIndex(0);
        //打乱顺序
        pack.cards.sort(function(a,b){
            return 0.5 - Math.random()
        });
        player.updateCards(pack.cards,0,false);
        //开灯
        this.turnOnSelfLight();

        //打骰子动画部分
        this.scheduleOnce(function(){
            //this.dealCardAni(1);
            this.table3d.showBeginAni(this.dealCardAni,this,pack);
        },0.8);
        this.table2d.setNormalCount(3,this.convertSIndexToCIndex(pack.bankerP),true);
    },
    beginDealPack:function(packData){
        var data = packData.json;
        var chairIndex = packData.chairIndex;
        if(chairIndex==1)
        ngc.log.info(JSON.stringify(data)) ;
        ngc.log.info("beginDealPack");
        var actionId=data["action"];
        if (chairIndex == this._selfChairIndex ) {
            switch (actionId){
                case game_msgId_rcv.BEGIN_NOTIFY:
                    this._packDealing=true;
                    var pack=new game_pack_template_rcv.BEGIN_NOTIFY(data);
                    this.tableNum = data.tableNum;
                    if(this.tableNum)
                        this.table2d._roomIdTxt.string = this.tableNum;

                    this.tableRound=pack.maxRound;
                    this.curRound=pack.curRound;
                    this.table2d.setRoundInfo(this.curRound,this.tableRound);
                    //this.table3d.showTableNum(this.tableNum);

                    this.setDir(pack.eastP,pack.chairIndex);
                    //this.initCardCount(pack.eastP,pack.eastCount);
                    this.addPlayer(pack.chairIndex,data["baseInfo"],true,pack.ZScore,this.ip);
                    //this.readyAction();
                    this._packDealing=false;
                    break;
                case game_msgId_rcv.DEALCARD_NOTIFY:
                    if (this._isDealCard == false) {
                        this._isDealCard = true;
                        this._packDealing=true;
                        this.table2d.showPareLoading(false);
                        var pack=new game_pack_template_rcv.DEALCARD_NOTIFY(data);
                        this.dealCard(pack);
                        this._tableRunning=true;
                        //开局游戏开始隐藏掉邀请好友按钮
                        this.table2d.hideInviteTip();

                        //显示牌局信息
                        this.tableRound=pack.maxRound;
                        this.curRound=pack.curRound;
                        this.table2d.setRoundInfo(this.curRound,this.tableRound);
                    }

                    break;
                case game_msgId_rcv.SWAP_CARDRS_NOTIFY:
                    if (this._isSwapedCard == false) {
                        this._isSwapedCard = true;
                        this._packDealing = true;
                        var pack = new game_pack_template_rcv.SWAP_CARDRS_NOTIFY(data);
                        var self = this.getPlayerByCIndex(0);
                        self.updateCards(pack.cards, 0, true);
                        var addCards = pack.addCards.concat();
                        self.setAddedCards(addCards);
                        this.changeAllPlayerState(new PlayerStateData(PlayerState.XUANPAISHOW, pack));
                        this.table2d.showSwapDes(pack.swapDirction, pack.delCards);
                    }
                    break;
                default:
                    this._super(data);
                    break;
            }

        }
        else {
            switch(actionId) {
                case game_msgId_rcv.SWAP_CARDRS_NOTIFY:
                    this._packDealing = true;
                    var pack = new game_pack_template_rcv.SWAP_CARDRS_NOTIFY(data);
                    var self = this.getPlayerBySIndex(chairIndex);
                    self.updateCards(pack.cards, 0, true);
                    var addCards = pack.addCards.concat();
                    self.setAddedCards(addCards);
                    self.layerPart3d.resetDarkCardNum();
                    self.layerPart3d.resetDarkCardValue();

                    var children=self.layerPart3d.layerCard1.getChildren();
                    for(var key=0 in children){
                        children[key].setVisible(true);
                    }

                    //this.changeAllPlayerState(new PlayerStateData(PlayerState.XUANPAISHOW, pack));
                    //this.table2d.showSwapDes(pack.swapDirction, pack.delCards);
                    break;
                case game_msgId_rcv.DEALCARD_NOTIFY:
                    this._packDealing = true;
                    var pack = new game_pack_template_rcv.DEALCARD_NOTIFY(data);
                    var self = this.getPlayerBySIndex(chairIndex);
                    this.dealOtherCard(chairIndex,pack);
                    this._packDealing = false;
                    break;
            }
        }
    },
    dealOtherCard:function(chairIndex,pack){
        //设置自己的暗牌
        ngc.log.info("dealOtherCard");
        var player=this.getPlayerBySIndex(chairIndex);
        player.updateCards(pack.cards,0,false);
        //开灯
        this.turnOnOtherLight(chairIndex);
    },
    addPlayer:function(chairIndexInServer,userInfo,isSelf,ZScore,ip){
        ngc.log.info("addPlayer"+userInfo);
        var dir=this.chairIndexToDir[chairIndexInServer];
        if(isSelf){
            var indexInClient=0;
        }
        else{
            var indexInClient=this.convertSIndexToCIndex(chairIndexInServer);
        }
        if (this._players[indexInClient]) {
            return;
        }
        var player=new ngc.game.recorder.player(this,dir,userInfo,ZScore,ip);

        player.addToCamera(2);
        player.setPlayerIndex(indexInClient);
        this._players[indexInClient]=player;
        this._userIdAry[indexInClient] = userInfo.userId;
        this._userSex[indexInClient] = userInfo.sex;
        //可以根据userID 找到用户名字  根据 userName 找到 userID
        this._userNameAry[indexInClient + ""].userID = userInfo.userId;
        this._userNameAry[indexInClient + ""].userName = userInfo.nickName;
        this.table2d.showHead(indexInClient,userInfo,ZScore,ip);
        this.checkSameIp(ip);
    },

    utf8ToUtf16:function(utf8Array) {
        var len = utf8Array.length;
        var ret =[];
        for (var i = 0;i< len;i++) {
            var codes = [];
            codes.push(utf8Array[i]);
            if(((codes[0] >> 7) & 0xff) == 0x0 ) { //
                ret.push(String.fromCharCode(codes[0]));
            }
            else if (((codes[0] >> 5) & 0xf) == 0x6) {
                codes.push(utf8Array[++i]);
                var bytes = [];
                bytes.push(codes[0] &0x1f);
                bytes.push(codes[1] & 0x3f);
                ret.push(String.fromCharCode(bytes[0]<<6|bytes[1]));
            }
            else if (((codes[0] >> 4) & 0xf) == 0xe) {
                codes.push(utf8Array[++i]);
                codes.push(utf8Array[++i]);
                bytes = [];
                bytes.push((codes[0] << 4)|((codes[1] >>2) & 0xf));
                bytes.push(((codes[1] & 0x3)<< 6)| (codes[2] & 0x3f));
                ret.push(String.fromCharCode((bytes[0] << 8)|bytes[1]));
            }
        }
        return ret.join('');
    },
    // migo: 开始读取录制文件内容
    openGameMedia:function(url) {
        var me = this;
        console.log("获取脚本：");
        var data = null;//cc.sys.localStorage.getItem(this._serialNum);
        if (data != null){
            this._packArray = JSON.parse(data);
        }
        else{ // connect to recorder server and get the records
            console.log("从本地获取脚本："+url);//"res/518_008518_1_0_1_2_3.bin"
            cc._binaryLoader.load(url,null,null,function(errorInfo,byteArray) {
                if (errorInfo != null) {
                    console.log("获取脚本数据失败：" + errorInfo);
                }
                else {
                    console.log("解析脚本：" + byteArray.length);
                    var packReadPos = 0;
                    while (packReadPos < byteArray.length) {
                        var packLen = byteArray[packReadPos] + byteArray[packReadPos + 1] * Math.pow(2, 8)
                            + byteArray[packReadPos + 2] * Math.pow(2, 16)
                            + byteArray[packReadPos + 3] * Math.pow(2, 24);
                        var begin = 0;
                        if (packLen - 5 <= 129) {
                            begin = packReadPos + 7;
                        }
                        else {
                            begin = packReadPos + 9;
                        }
                        var chairIndex = byteArray[packReadPos + 4];
                        var packageData = byteArray.subarray(begin, packReadPos + packLen);
                        //console.log("转换成JSON");
                        try {
                            var str = me.utf8ToUtf16(packageData);
                            //console.log("转换成JSON成功");
                            //console.log("package:" + str);
                            var json = ngc.pubUtils.string2Obj(str);
                            var action = json["action"];
                            var packData = new ngc.game.recorder.package();
                            packData.chairIndex = chairIndex;
                            packData.json = json;
                            if (action != undefined) {
                                //me.onNetMessage(action, json);
                                if(json["action"]==game_msgId_rcv.BEGIN_NOTIFY){    //检查自己
                                    if(json["baseInfo"]&&json["baseInfo"]["userId"].toString()==ngc.curUser.baseInfo.userId.toString()){//自己
                                        me._selfChairIndex=chairIndex;
                                    }
                                }
                                me._packArray.push(packData);
                            }
                            else {
                                ngc.log.error("error package");
                            }
                        }
                        catch (e) {
                            console.log(e.message);
                        }

                        packReadPos += packLen;
                    }
                }
            })
        }
    },
    // replay callback
    _isPause:false,
    _isPlaying:false,
    _hasBegined:false,
    _animateSpeed:1.0,
    onPlay:function(){
        if(this._isPlaying) {
            if(this._isPause) {
                this._isPause = false;
                return true;
            }
        }
        else if(!this._hasBegined) {
            if(this._localFiles.length>0){
                var file=this._localFiles.shift();
                this.openGameMedia(file);
                this._isPlaying = true;
                this._isPause = false;
            }
            if(!this._hasBegined) this._hasBegined=true;
            return true;
        }
        else if(this._hasBegined){
            if(this._localFiles.length>0){
                var tablePlayer = new ngc.game.scene.tablePalyerScene();
                tablePlayer.setLocalFiles(this._localFiles);
                tablePlayer.lReplayControl.onPlayOrPause();
                cc.director.runScene(tablePlayer);
            }
            return true;
        }
        return false;
    },
    onPause:function(){
        if (this._isPlaying) {
            if(!this._isPause){
                this._isPause = true;
                return true;
            }
        }
    },
    onStop:function() {
        if (this._isPlaying) {
            this._isPlaying = false;
            this._isPause = true;
            this.clearTable();
            this.resetData();
        }
        return true;
    },
    onFast:function(){
        var speed  = 1/++this._animateSpeed;
        if (this._animateSpeed > 5){
            this._animateSpeed = 1.0;
        }
        cc.director.getScheduler().setTimeScale(this._animateSpeed);
        return this._animateSpeed;
    },
    onBack:function(){
        cc.director.popScene();
    },
    resetData:function(){
        this.pointer=null;
        this._isDealCard = false;
        this._isSwapedCard = false;
        this._packArray=[];
        this._packDealing=false;
        this._selfTip=null;
    }


});

//part3d(有改动的地方都重写)
ngc.game.recorder.playerpart3d=ngc.game.playerpart3d.extend({
    initCards:function(){
        this.cards=[
            [],            //暗牌[0,1,2,3,4,5,9],
            [],           //明牌 [12,12,12,6,7,8],
            [],         //胡牌 [6,19,19,19,19,20],
            [],   //打出去的牌 [4,5,6,15,16,17,20,21,22,23,24,25,26]
            [],  //暗杠
            [],  // 交换的牌
        ]
    },
    getAnimateSpeed:function(){
        if(this.scene && this.scene._animateSpeed){
            return this.scene._animateSpeed;
        }
        return 1.0;
    },
    generateOneMJCard: function (cardValue, mjcardclass) {
        var sprite = ngc.game.createPlayerMj(this._playerIndex, mjcardclass);
        if (cardValue >= 0) {
            this.changeMJCardValue(cardValue, sprite, mjcardclass);
        }
        return sprite;
    },
    discardOneCardAni:function(packData){
        //if(this._playerIndex==0)
        this.removeFromSelf(packData);
        // else
        //     this.randomRemoveOneCard();

        this.refreshCards4();

        this.showDicardHandAni();

        this.scheduleOnce(function(){
            this.showArrangeCardHandAni();
        },2);
    },
    putSelectedToSwap:function(){
        if(this.layerCard5.getChildren().length>0) return;

        if(this._playerIndex==0){
            var selectedCards=this.getSelectedCards();
            for(var key=0 in selectedCards){
                selectedCards[key].removeFromParent(true);
                if(key>=2) break;
            }
        }
        else{
            var darkCards=this.layerCard1.getChildren();
            for(var i=0;i<3;i++){
                darkCards[i].removeFromParent(true);
            }
        }
        this.arrangementDarkCards();

        var pos=ngc.game.mjpos[this._playerIndex][MJCardClass.HUAN];
        var mjCardParent=this.generateOneMJCard(this.cards[5][0],MJCardClass.HUAN);
        mjCardParent.setPosition3D(pos);

        for(var i=1;i<=2;i++){
            var mjCard=this.generateOneMJCard(this.cards[5][i],MJCardClass.HUAN);
            if(i==1)
                mjCard.setPositionX(-ngc.game.mjModelWidth*2);
            else
                mjCard.setPositionX(ngc.game.mjModelWidth*2);
            mjCard.setScale(1.0);
            mjCard.setScaleZ(1.0);
            mjCard.setRotation3D(cc.math.vec3(0,0,0));
            mjCardParent.addChild(mjCard);
        }
        mjCardParent.setCameraMask(2);
        this.layerCard5.addChild(mjCardParent);

        this.showSwapHandAni();
    },
    arrangementDarkCards:function(all,notEndDeal){
        var mjCardsDark=this.layerCard1.getChildren();  //所有的暗牌
        if(mjCardsDark.length>0){
            var initPos1=ngc.game.mjpos[this._playerIndex][MJCardClass.SHOU];//手牌起始位置
            var len=14;
            if(this._playerIndex%2==0){
                len-=(Math.round(this.cards[1].length/3*1.8));
                //if(len<mjCardsDark.length) len=mjCardsDark.length;
            }

            if(this._playerIndex%2==0){
                var startPos=cc.math.vec3(initPos1.x+(this._playerIndex==0?this._mjWidthSelf:-ngc.game.mjModelWidth)*(len-mjCardsDark.length)/2,initPos1.y,initPos1.z);
                var gapPos=cc.math.vec3(this._playerIndex==0?this._mjWidthSelf:-ngc.game.mjModelWidth,0,0);
            }
            else{
                var startPos=cc.math.vec3(initPos1.x,initPos1.y,initPos1.z+(this._playerIndex==1?ngc.game.mjModelWidth:-ngc.game.mjModelWidth)*(14-mjCardsDark.length)/2);
                var gapPos=cc.math.vec3(0,0,this._playerIndex==1?ngc.game.mjModelWidth:-ngc.game.mjModelWidth);
            }
            for(var key=0 in mjCardsDark){
                if(key>0)
                    startPos=cc.math.vec3Add(startPos,gapPos);
                if(!all){
                    var nowPos=mjCardsDark[key].getPosition3D();
                    startPos.y=nowPos.y;
                }
                mjCardsDark[key].setPosition3D(startPos);
                // migo
                // if(ngc.game.mjRecordPlayerRotations[this._playerIndex][MJCardClass.SHOU])
                //     mjCardsDark[key].setRotation3D(ngc.game.mjrotations[this._playerIndex][MJCardClass.SHOU]);
            }
        }
        if(!notEndDeal)
            this.endPackDeal();
    },
    moveNewCardAni:function(){
        var children=this.layerCard1.getChildren();
        if(children.length<2){
            this.arrangementDarkCards(undefined,true);
            this.endState();
            return;
        }
        var pos1=children[children.length-2].getPosition3D();
        var pos2=children[children.length-1].getPosition3D();
        var gapPos=cc.math.vec3Sub(pos2,pos1);

        //if(this._playerIndex==0){
        var moveCardValue=this.cards[0][this.cards[0].length-1];
        this.sortDardCard();

        var moveToIndex=this.cards.length-1;
        for(var key=this.cards[0].length-1;key>=0;key--){
            if(this.cards[0][key]==moveCardValue){
                moveToIndex=parseInt(key);
                break;
            }
        }

        cc.moveByDelegate=cc.moveBy;
        // }
        // else{
        //     var moveToIndex=Math.round(Math.random()*(children.length-2));
        //     cc.moveByDelegate=cc.moveByPull3DObj;
        // }

        //缺口处的索引
        var compareNum=this._playerIndex==0?this._mjWidthSelf:ngc.game.mjModelWidth;
        var gapIndex=0;
        for(var key=0 in children){
            if(children[key-1]){
                var pos1=children[key-1].getPosition3D();
                var pos2=children[key].getPosition3D();
                if(this._playerIndex%2==0&&Math.abs(pos2.x-pos1.x)>=compareNum*2){
                    gapIndex=parseInt(key);
                    break;
                }
                else if(this._playerIndex%2==1&&Math.abs(pos2.z-pos1.z)>=compareNum*2){
                    gapIndex=parseInt(key);
                    break;
                }
            }
        }

        var moveByPos=cc.math.vec3(0,0,0);
        var moveByPos2=cc.math.vec3(0,0,0);
        if(this._playerIndex%2==0){
            moveByPos.x=(this._playerIndex==0?this._mjWidthSelf:-ngc.game.mjModelWidth)*((gapIndex-moveToIndex)/Math.abs(gapIndex-moveToIndex));
            moveByPos2.x=(this._playerIndex==0?-this._mjWidthSelf:ngc.game.mjModelWidth);
        }
        else{
            moveByPos.z=(this._playerIndex==1?ngc.game.mjModelWidth:-ngc.game.mjModelWidth)*((gapIndex-moveToIndex)/Math.abs(gapIndex-moveToIndex));
            moveByPos2.z=(this._playerIndex==1?-ngc.game.mjModelWidth:ngc.game.mjModelWidth);
        }

        var temp=cc.math.vec3Mod(cc.math.vec3Add(gapPos,moveByPos2),this._playerIndex==0?this._mjWidthSelf:ngc.game.mjModelWidth);
        var moveCount=1;
        if(gapIndex<moveToIndex){
            moveCount=Math.abs(children.length-moveToIndex);
            var moveByPos2=cc.math.vec3Ride(moveByPos2,moveCount);
            var moveChildren=children.slice(gapIndex,moveToIndex);
        }
        else{
            moveCount=Math.abs(children.length-moveToIndex);
            var moveByPos2=cc.math.vec3Ride(moveByPos2,moveCount);
            var moveChildren=children.slice(moveToIndex,gapIndex);
        }
        moveByPos2=cc.math.vec3Sub(moveByPos2,temp);

        var lastChild=children[children.length-1];
        var delay=0;
        if(moveToIndex==children.length-1){//不用飞
            lastChild.runAction(cc.sequence(cc.moveBy(0.16,moveByPos2),cc.callFunc(function(){
                this.endState();
            },this)));
        }
        else{
            if(this._playerIndex%2==0)
                var rotation=cc.math.vec3(0,0,this._playerIndex==0?30:-30);
            else
                var rotation=cc.math.vec3(0,-30,0);

            var delay=0.01*moveCount;
            if(delay<0.26) delay=0.26;

            var rt1=cc.rotateBy(0,rotation);
            var moveHeight=this._playerIndex==0?120:ngc.game.mjModelLength+6;
            var mv1=cc.moveByDelegate(0,cc.math.vec3(0,moveHeight,0),undefined,lastChild,this._handObj);
            var mv2=cc.moveByDelegate(delay,moveByPos2,undefined,lastChild,this._handObj);
            var rt2=cc.rotateBy(0.06,cc.math.vec3Ride(rotation,-1));
            var mv3=cc.moveByDelegate(0.1,cc.math.vec3(0,-moveHeight,0),undefined,lastChild,this._handObj);
            var cb2=cc.callFunc(function(){
                if(this._playerIndex==0) return;
                var animation = new jsb.Animation3D(this._handObjRes);
                if(this._playerIndex==3)
                    var animate3 = jsb.Animate3D.createWithFrames(animation,this._handAnis.arrangecard2[0],this._handAnis.arrangecard2[1],60);
                else
                    var animate3 = jsb.Animate3D.createWithFrames(animation,this._handAnis.arrangecard2[0],this._handAnis.arrangecard2[1],60);
                this._handObj.runAction(cc.spawn(cc.moveBy(0.1,cc.math.vec3(0,20,0)),cc.sequence(animate3,cc.hide())));
            },this);
            var dl=cc.delayTime(0.1);
            var cb=cc.callFunc(function(){
                this.moveCardIndex(children.length-1,moveToIndex);
                this.endState();
            },this);
            lastChild.runAction(cc.sequence(rt1,mv1,mv2,rt2,mv3,cb2,dl,cb));
        }

        for(var key=0 in moveChildren){
            if(delay>0)
                moveChildren[key].runAction(cc.sequence(cc.delayTime(delay),cc.moveBy(0.1,moveByPos)));
            else
                moveChildren[key].runAction(cc.moveBy(0.1,moveByPos));
        }
    },
    moveDarkCardToOpendCardOther:function(action,cardValue){
        var rmLen=0;
        var maxNum=2;
        if(action!=opServerActionCodes.mjaPeng){
            maxNum=14;
        }
        var children=this.layerCard1.getChildren();
        switch (action){
            case opServerActionCodes.mjaPeng:
                this.cards[1].push(cardValue,cardValue,cardValue);
                rmLen=2;
                break;
            case opServerActionCodes.mjaDaMingGang:
                this.cards[1].push(cardValue,cardValue,cardValue,cardValue);
                rmLen=3;
                break;
            case opServerActionCodes.mjaAnGang:
                this.cards[1].push(cardValue,cardValue,cardValue,cardValue);
                this.cards[4].push(cardValue,cardValue,cardValue);
                rmLen=4;
                break;
            case opServerActionCodes.mjaJiaGang:
                for(var key=0 in this.cards[1]){
                    if(this.cards[1][key]==cardValue){
                        this.cards[1].splice(key,0,cardValue);
                        break;
                    }
                }
                rmLen=1;
                this.layerCard2.removeAllChildren(true);
                break;
        }
        // for(var i=0;i<rmLen;i++){
        //     if(children[i])
        //         children[i].removeFromParent(true);
        // }
        //this.refreshCards2();
        //this.arrangementDarkCards();
        var children=this.layerCard1.getChildren();
        for(var key=0;key<this.cards[0].length;key++){
            if(this.cards[0][key]==cardValue){
                //this.insertToOpenCard(this.cards[0].splice(key,1));
                this.cards[0].splice(key,1);
                var rm=children.splice(key,1);
                rm[0].removeFromParent(false);
                key--;
                rmLen--;
                if(rmLen<=0) break;
                children=this.layerCard1.getChildren();
            }
        }
        this.showPengGangHandAni(cardValue);
    }
});


//table3d
ngc.game.layer.recorder.table3d = ngc.game.layer.table3d.extend({
    ctor:function () {
        this._super();
    },
    generateOneMJCard:function(dirIndex,indexInPos){
        var sprite = ngc.game.createPlayerMj(dirIndex,MJCardClass.QIANG);
        var pos3d=this.getPosIndir(this.dirPos[dirIndex],indexInPos,dirIndex);
        sprite.setPosition3D(pos3d);
        this.addChild(sprite);
        this.mjCards.push(sprite);
    }
});

//table2d
ngc.game.layer.tablePlayer2d=ngc.game.layer.table2d.extend({
    _btExit:null,
    _btMenu:null,
    _btTing:null,

    myInit:function(){
        this._super();
        this.initForReplay();
    },
    initForReplay:function(){
        ngc.log.info("initForReplay called");
        self = this;
        //self._btExit.setVisible(false);
        //self._voiceBtn.setVisible(false);
        //self._btTing.setVisible(false);
        //self._btMenu.setVisible(false);
        //self._chatBtn.setVisible(false);
        this._timelbl.setVisible(false);
        this._batteryLevel.setVisible(false);
        this._batteryLevelBg.setVisible(false);
    }
});



ngc.game.recorder.player= function(scene,dir,userInfo,ZScore,ip){
        this.scene=scene;
        this.dir=dir;
        this.playerIndex=0;
        this.userInfo=userInfo;
        this.score=ZScore;
        this.banker=0;
        this.ip=ip;

        this.toRefreshScoreArray=[];

        this.layerPart2d=new ngc.game.playerpart2d();
        this.layerPart3d=new ngc.game.recorder.playerpart3d();

        this.scene.addChild(this.layerPart2d);
        this.scene.addChild(this.layerPart3d);

        ngc.log.info("scene:"+this.scene);
        this.layerPart2d.setScene(this.scene);
        this.layerPart3d.setScene(this.scene);

        this.layerPart2d.setPlayer(this);
        this.layerPart3d.setPlayer(this);
    }
ngc.game.recorder.player.prototype=ngc.game.player.prototype;

/*
 *  播放控制ui
 * */
ngc.game.jsonRes.layerReplayer="res/g_layer_game_replayer.json";
ngc.game.recorder.layer.CReplayControl = ngc.CLayerBase.extend({
    // buttons
    _btStop:null,
    _btPlayOrPause:null,
    _btFast:null,
    _btBack:null,
    _bg:null,

    isPlay:false,
    onEnter:function () {
        ngc.log.info("control onEnter called");
        this._super();
        this.showControl();
    },
    showControl:function(){
        if (this._timeLine) {
            this._timeLine.play("_show_control",false);
        }
    },
    hideControl:function(){
        if (this._timeLine) {
            this._timeLine.play("_hide_control",false);
        }
    },
    myInit:function(){
        this._super(ngc.game.jsonRes.layerReplayer,true);
        this._btPlayOrPause.loadTextures("res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png",ccui.Widget.LOCAL_TEXTURE);
        this._btFast.setTitleText("1X");
        this.mySetVisibleTrue();
    },
    onStop:function(){
        self = this;
        if (self.getParent()&& self.getParent().onStop) {
            if (self.getParent().onStop() == true) {
                self.stop();
            }
        }
        else {
            self.stop()
        }
    },
    stop:function() {
        this._btFast.setTitleText("1X");
        this._btPlayOrPause.loadTextures("res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png",ccui.Widget.LOCAL_TEXTURE);
        this.isPlay = false;
    },
    onPlayOrPause:function(){
        self = this;
        if (self.isPlay) {
            if (self.getParent() && self.getParent().onPause) {
                if (self.getParent().onPause() == true) {
                    self.pause();

                }
            }
        }
        else{
            if(self.getParent() && self.getParent().onPlay) {
                if (self.getParent().onPlay() == true){
                    self.play();
                }
            }
        }
    },
    pause:function(){
        this._btPlayOrPause.loadTextures("res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png","res/g/mjBloody/recorder/play.png",ccui.Widget.LOCAL_TEXTURE);
        self.isPlay= false;
    },
    play:function () {
        this._btPlayOrPause.loadTextures("res/g/mjBloody/recorder/pause.png","res/g/mjBloody/recorder/pause.png","res/g/mjBloody/recorder/pause.png",ccui.Widget.LOCAL_TEXTURE);
        self.isPlay= true;
    },
    onFast:function(){
        self = this;
        if(self.getParent() && self.getParent().onFast){
            rate = self.getParent().onFast();
            if (rate >=1) {
                self._btFast.setTitleText(rate+"X");
            }
        }
    },
    onBack:function(){
        self = this;
        if(self.getParent() && self.getParent().onBack) {
            self.getParent().onBack();
        }
    }

});



ngc.game.mjRecordPlayerRotations=[
    [
        {x:270,y:0,z:0},                                      //手牌
        {x:180,y:0,z:0},                                      //明牌
        {x:180,y:0,z:0},                                      //胡牌
        {x:180,y:0,z:0},                                      //出牌
        {x:0,y:180,z:0},                                      //换牌
        {x:0,y:180,z:0},                                    //牌墙
        {x:0,y:180,z:0}                                       // 扣牌
    ],
    [
        //{x:0,y:270,z:90},                                      //手牌
        {x:180,y:90,z:0},
        {x:180,y:90,z:0},                                      //明牌
        {x:180,y:90,z:0},                                      //胡牌
        {x:180,y:90,z:0},                                      //出牌
        {x:0,y:270,z:0},                                      //换牌
        {x:0,y:270,z:0},                                    //牌墙
        {x:0,y:270,z:0}                                       // 扣牌
    ],
    [
        //{x:90,y:0,z:0},                                      //手牌
        {x:180,y:0,z:0},
        {x:180,y:0,z:0},                                      //明牌
        {x:180,y:0,z:0},                                      //胡牌
        {x:180,y:0,z:0},                                      //出牌
        {x:0,y:180,z:0},                                      //换牌
        {x:0,y:180,z:0},                                    //牌墙
        {x:0,y:180,z:0}                                       // 扣牌
    ],
    [
        //{x:90,y:270,z:0},                                      //手牌
        {x:180,y:-90,z:0},
        {x:180,y:90,z:0},                                      //明牌
        {x:180,y:90,z:0},                                      //胡牌
        {x:180,y:90,z:0},                                      //出牌
        {x:0,y:270,z:0},                                      //换牌
        {x:0,y:270,z:0},                                    //牌墙
        {x:0,y:270,z:0}                                       //扣牌
    ]
];

ngc.game.mjplayertextures=[
    [
        "res/g/mjBloody/obj/i.png",                         //手牌
        "res/g/mjBloody/obj/c.png",                         //明牌
        "res/g/mjBloody/obj/c.png",                         //胡牌
        "res/g/mjBloody/obj/c.png",                         //出牌
        "res/g/mjBloody/obj/b.png",                         //换牌
        "res/g/mjBloody/obj/b.png",                         //牌墙
        "res/g/mjBloody/obj/b.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/d.png",                         //手牌
        "res/g/mjBloody/obj/d.png",                         //明牌
        "res/g/mjBloody/obj/d.png",                         //胡牌
        "res/g/mjBloody/obj/d.png",                         //出牌
        "res/g/mjBloody/obj/g.png",                         //换牌
        "res/g/mjBloody/obj/g.png",                         //牌墙
        "res/g/mjBloody/obj/g.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/c.png",                         //手牌
        "res/g/mjBloody/obj/c.png",                         //明牌
        "res/g/mjBloody/obj/c.png",                         //胡牌
        "res/g/mjBloody/obj/c.png",                         //出牌
        "res/g/mjBloody/obj/b.png",                         //换牌
        "res/g/mjBloody/obj/b.png",                         //牌墙
        "res/g/mjBloody/obj/b.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/d.png",                         //手牌
        "res/g/mjBloody/obj/d.png",                         //明牌
        "res/g/mjBloody/obj/d.png",                         //胡牌
        "res/g/mjBloody/obj/d.png",                         //出牌
        "res/g/mjBloody/obj/a.png",                         //换牌
        "res/g/mjBloody/obj/a.png",                         //牌墙
        "res/g/mjBloody/obj/a.png",                         //扣牌
    ]
];


ngc.game.createPlayerMj=function(cIndex,mjCardClass){
    var mjModel = new jsb.Sprite3D(ngc.game.objRes.majiang);

    if(ngc.game.mjplayertextures[cIndex][mjCardClass]){
        var texture=cc.textureCache.addImage(ngc.game.mjplayertextures[cIndex][mjCardClass]);
        if(texture)
            mjModel.setTexture(texture);
    }

    var rotation=ngc.game.mjRecordPlayerRotations[cIndex][mjCardClass];
    if(rotation)
        mjModel.setRotation3D(rotation);

    if(cIndex==0&&mjCardClass==MJCardClass.SHOU){
        mjModel.setScaleX(2.42);
        mjModel.setScaleY(2.42);
        mjModel.setScaleZ(2.42);
    }
    else{
        mjModel.setScale(0.5);
        mjModel.setScaleZ(0.5);
    }

    return mjModel;
}