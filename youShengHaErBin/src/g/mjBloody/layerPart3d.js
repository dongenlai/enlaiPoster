ngc.game.playerpart3d=cc.Layer.extend({
    curState:PlayerState.NONE,
    toState:PlayerState.NONE,

    _isSelf:false,
    _playerIndex:0,

    player:null,
    scene:null,

    layerCard1:null,

    playerMJCardsPos:null,

    toStates:null,
    dealingState:false,

    _handObj:null,
    _handObjRes:null,
    _handAnis:null,
    _handAniPros:null,

    _popGapYSelf: 35,        //自己的麻将点起的高度
    _mjWidthSelf: 80,        //自己麻将的宽度
    _popGapYOther: 11,       //其他人的麻将点起的高度
    _handSpeed: 20,
    _paiRotateSpeed:0.6,
    hasTingArry:null,

    ctor:function(){
        this._super();

        this.scene=null;
        this.player=null;
        this.toStates=[];
        this.hasTingArry = []
        this.dealingState=false;
        this._handSpeed = 20,

        this.layerCard1=new cc.Layer();
        this.addChild(this.layerCard1);

        this.layerCard2=new cc.Layer();
        this.addChild(this.layerCard2);

        this.layerCard3=new cc.Layer();
        this.addChild(this.layerCard3);

        this.layerCard4=new cc.Layer();
        this.addChild(this.layerCard4);

        this.layerCard5=new cc.Layer();
        this.addChild(this.layerCard5);

        this.initCards();
    },

    initCards:function(){
        this.cards=[
            [],            //暗牌[0,1,2,3,4,5,9],
            [],           //明牌 [12,12,12,6,7,8],
            [],         //胡牌 [6,19,19,19,19,20],
            [],   //打出去的牌 [4,5,6,15,16,17,20,21,22,23,24,25,26]
            [],  //暗杠
        ]


    },

     getCardsInfo: function () {
         return this.cards;
     },

    setScene:function(scene){
        this.scene=scene;
    },

    setState:function(state){
        this.toStates.push(state);
        this.beginState();
        return;

    },

    beginState:function(){
        if(this.toStates.length>0&&!this.dealingState) {
            var state = this.toStates.shift();
            this.curState = state;
            this.dealingState = true;

            var packData=state.packData;
            switch (state.state){
                case PlayerState.XUANPAIING:
                    if(this._playerIndex==0){
                        this.autoPopSelectedCard(0,3);
                    }
                    this.endState();
                    break;
                case PlayerState.XUANPAISHOW:
                    this.putSelectedToSwap();
                    this.showSwapAni(packData);
                    break;
                case PlayerState.MOPAISHOW:
                    if(this._playerIndex==0&&packData&&packData.card!=undefined){
                        this.resetDarkCardNum();
                        this.resetDarkCardValue();

                        this.cards[0].push(packData.card);
                    }
                    this.grabOneCardAni();
                    break;
                case PlayerState.CHUPAISHOW:
                    if(packData&&packData.card!=undefined){
                        this.cards[3].push(packData.card);
                        ngc.log.info("打出去的牌记录2: "+packData.card);
                    }
                    this.discardOneCardAni(packData);
                    break;
                case PlayerState.YAPPAISHOW:
                    if(packData && packData.card != undefined && packData.action){
                        if(this._playerIndex == 0){
                            this.moveDarkCardToOpendCardSelf(packData.action, packData.card, packData);
                        }else{
                            this.moveDarkCardToOpendCardOther(packData.action, packData.card, packData);
                        }
                        //播放吃碰音效
                        this.playChiPengHuEffect(packData.action);
                    }
                    break;
                case PlayerState.HUPAISHOW:
                    if(packData&&packData.card!=undefined){
                        this.moveToHuCard(packData.isZiMo,packData.card,packData.lpos,packData.huCount);
                        this.playChiPengHuEffect(PlayerState.HUPAISHOW);
                        if(this._playerIndex==0){
                            this.removeClickEvent();
                            this.scene.turnOffSelfLight();
                        }
                    }
                default:
                    this.dealingState=false;
                    break;
            }
        }
    },

    endState:function(){
        this.dealingState=false;
        this.beginState();
    },

    selfTingPaiShow : function(index){
        // var cardNodeAry = this.layerCard1.getChildren();
        this.scene.table2d.setTingStateVis(this._playerIndex, true);
        // for (var i = 0; i < cardNodeAry.length; i++) {
        //     cardNodeAry[i].setColor(cc.WHITE);
        // }
        // if(!index || index == undefined)
        //     index = this._playerIndex;
        // this.scene.turnOffSelfLight(index);
    },

    getTingEstr:function(cardId){
        var hasTingAry = this.hasTingArry;
        for(var k = 0 in hasTingAry){
            if(parseInt(k) == cardId){
                return  hasTingAry[k].tingPaiEs || "";
            }
        }
    },

    showTpAction:function(packData,tingState){
        var tingPaiData = {};
        this.hasTingArry = null;
        if(packData.length == 0){
            return;
        }
        for(var key = 0 in packData){
            if(packData[key]["a"] == opServerActionCodes.mjaTing){
                var paiData = packData[key]["e"].split(":");
                var chupai = paiData[0];
                tingPaiData[chupai] = tingPaiData[chupai] || {};
                tingPaiData[chupai].tingParAry = tingPaiData[chupai].tingParAry || [];
                tingPaiData[chupai].tingPaiEs = tingPaiData[chupai].tingPaiEs || "";
                var hupais = paiData[1].split(",");
                for(var i = 0 in hupais){
                    var one = hupais[i].split("^");
                    tingPaiData[chupai].tingParAry.push( one[0] );
                }
                tingPaiData[chupai].tingPaiEs = packData[key]["e"];
            }
        }
        this.hasTingArry = tingPaiData;
        //不能听牌的都变成灰色可以停牌的变成白色
        var cards = this.cards[0];
        var children = this.layerCard1.getChildren();
        for(var key = 0 in cards){
            if(tingPaiData[cards[key]]){
                children[key].setColor(cc.color(255,255,255));
                var child = children[key].getChildren()[0];
                if(!child) continue;
                var child2d = child.getChildren()[0];
                if(!child2d) continue;
                child2d.setColor(cc.color(255,255,255));
            }else{
                children[key].setColor(cc.color(150,150,150));
                var child = children[key].getChildren()[0];
                if(!child) continue;
                var child2d = child.getChildren()[0];
                if(!child2d) continue;
                child2d.setColor(cc.color(150,150,150));
            }
        }
        this.player.setTingState(tingState);
    },

    showTpChiPengAction:function(packData,tingState){
        var tingPaiData = {};
        this.hasTingArry = null;
        if(packData.length == 0){
            return;
        }
        for(var key = 0 in packData){
            if(packData[key]["a"] == opServerActionCodes.mjaTingChi || packData[key]["a"] == opServerActionCodes.mjaTingPeng){

                var paiData = packData[key]["e"].split(":");
                var chupai = paiData[1];
                ngc.log.info("chupai = " + chupai);
                tingPaiData[chupai] = tingPaiData[chupai] || {};
                tingPaiData[chupai].tingParAry = tingPaiData[chupai].tingParAry || [];
                tingPaiData[chupai].tingPaiEs = tingPaiData[chupai].tingPaiEs || "";
                var hupais = paiData[2].split(",");
                ngc.log.info("hupais = " + JSON.stringify(hupais));
                for(var i = 0 in hupais){
                    var one = hupais[i].split("^");
                    tingPaiData[chupai].tingParAry.push( one[0] );
                }
                tingPaiData[chupai].tingPaiEs = packData[key]["e"];

            }
        }
        this.hasTingArry = tingPaiData;
        //不能听牌的都变成灰色可以停牌的变成白色
        var cards = this.cards[0];
        var children = this.layerCard1.getChildren();
        for(var key = 0 in cards){
            if(tingPaiData[cards[key]]){
                children[key].setColor(cc.color(255,255,255));
                var child = children[key].getChildren()[0];
                if(!child) continue;
                var child2d = child.getChildren()[0];
                if(!child2d) continue;
                child2d.setColor(cc.color(255,255,255));
            }else{
                children[key].setColor(cc.color(150,150,150));
                var child = children[key].getChildren()[0];
                if(!child) continue;
                var child2d = child.getChildren()[0];
                if(!child2d) continue;
                child2d.setColor(cc.color(150,150,150));
            }
        }
        this.player.setTingState(tingState);
        this.player.parseAndSetTingPai(packData);
    },

    //播放吃碰胡音效
    playChiPengHuEffect:function(action){
        switch (action){
            case opServerActionCodes.mjaTing:
            case opServerActionCodes.mjaTingGang:
            case opServerActionCodes.mjaTingChi:
            case opServerActionCodes.mjaTingPeng:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_ting" : "pt_nv_ting";
                if (!ngc.hall.musicGame[_file])
                    ngc.log.info("Error : file is not found file = " + _file);
                if(ngc.flag.SOUND_FLAG)
                    ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            case opServerActionCodes.mjaJiaGang:
            case opServerActionCodes.mjaDaMingGang:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_gang" : "pt_nv_gang";
                if (!ngc.hall.musicGame[_file])
                    ngc.log.info("Error : file is not found file = " + _file);
                //cc.audioEngine.playEffect(ngc.hall.musicGame[_file], false);
                if(ngc.flag.SOUND_FLAG)
                    ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            case opServerActionCodes.mjaPeng:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_peng" : "pt_nv_peng";
                if (!ngc.hall.musicGame[_file])
                    ngc.log.info("Error : file is not found file = " + _file);
                //cc.audioEngine.playEffect(ngc.hall.musicGame[_file], false);
                if(ngc.flag.SOUND_FLAG)
                    ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            case opServerActionCodes.mjaChi:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_chi" : "pt_nv_chi";
                //var _file = "pt_nv_chi";
                ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            case opServerActionCodes.mjaAnGang:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_gang" : "pt_nv_gang";
                if (!ngc.hall.musicGame[_file])
                    ngc.log.info("Error : file is not found file = " + _file);
                //cc.audioEngine.playEffect(ngc.hall.musicGame[_file], false);
                if(ngc.flag.SOUND_FLAG)
                    ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            case PlayerState.HUPAISHOW:
                var _file = (this.player.userInfo.sex == 1) ? "pt_n_hu" : "pt_nv_hu";
                if (!ngc.hall.musicGame[_file])
                    ngc.log.info("Error : file is not found file = " + _file);
                //cc.audioEngine.playEffect(ngc.hall.musicGame[_file], false);
                if(ngc.flag.SOUND_FLAG)
                    ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
                break;
            default:
                console.log("没有对应音效");
                break;
        }
    },

    setSelf:function(){
        this._isSelf=true;
        this._playerIndex=0;
    },
    isSelf:function(){
        return this._isSelf;
    },

    setPlayer:function(player){
        this.player=player;

        if(player.userInfo.sex==1){ // 男性
            this._handObjRes=ngc.game.objRes.handMan;
            this._handAnis=ngc.game.man_anis;
            this._handAniPros=ngc.game.man_anipros;
        }
        else{   //女性
            this._handObjRes=ngc.game.objRes.handWoman;
            this._handAnis=ngc.game.woman_anis;
            this._handAniPros=ngc.game.woman_anipros;
        }
    },

    setPlayerIndex:function(index){
        this._playerIndex=index;
        if(this._playerIndex==0){
            this.addClickEvent();
            //this.initGameLogic();
        }

        //if(this._playerIndex!=1) return;

        this._handObj=new jsb.Sprite3D(this._handObjRes);
        //if(this._playerIndex==0)
        //    this._handObj.setCameraMask(cc.CameraFlag.USER4);
                //else
            this._handObj.setCameraMask(cc.CameraFlag.USER1);
        this.addChild(this._handObj);

        //this._handObj.setCullFace(gl.FRONT);
        this._handObj.setCullFaceEnabled(false);
        this._handObj.setLightMask(cc.LightFlag.LIGHT0);
        this._handObj.setVisible(false);
        //this.schedule(function(){
        //    //this.cards[3]=[11,12,13,14,14,14];
        //    //this.refreshCards4();
        //    //
        //    //this.cards[1]=[3,3,3,2,2,2,4,4,4,1,1,1];
        //    //this.refreshCards2();
        //    //
        //    //this.cards[2]=[9,10,10];
        //    //this.refreshCards3();
        //
        //    this.showArrangeCardHandAni();}
        //    ,3,100000,4);
        //
        //this.schedule(function(){
        //    this.grabOneCardAni();
        //},6,1000000,3)
        return;
        this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].arrangecard);
        var animation = new jsb.Animation3D(this._handObjRes);
        if (animation) {
            var animate = jsb.Animate3D.createWithFrames(animation,this._handAnis.arrangecard1[0],this._handAnis.arrangecard1[1],60);
            animate.setQuality(2);
            //this._handObj.runAction(cc.repeatForever(cc.sequence(animate)));
            this._handObj.runAction(animate);
            //this.layerCard1.setVisible(false);
        }
        this.scheduleOnce(function(){
            this.grabOneCardAni();
        },1)

        //this.cards[1]=[10,10,10,10,11,11,11];
        //this.refreshCards2();

        //this.cards[2]=[9,9,11,17];
        //this.refreshCards3();

        //this.cards[3]=[3,6,9,10,22,26,1,11,2,3,6,9,22,16,17,19,25,26,14,16];
        //this.refreshCards4();
        ////////////////

        var pos=ngc.game.mjpos[this._playerIndex][MJCardClass.HUAN];
        var mjCardParent=this.generateOneMJCard(undefined,MJCardClass.HUAN);
        mjCardParent.setPosition3D(pos);

        for(var i=1;i<=2;i++){
            var mjCard=this.generateOneMJCard(undefined,MJCardClass.HUAN);
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
        //////////////////////////////

        //if(this._playerIndex!=1) return;

        cc.eventManager.addListener({
            event:cc.EventListener.MOUSE,
            onMouseScroll:this.onMouseScroll.bind(this)
        }, this);

        this._itemMenu = new cc.Menu();
        this._itemMenu.setContentSize(cc.winSize);
        this._itemMenu.ignoreAnchorPointForPosition(false);
        this._itemMenu.setPosition(cc.p(0,0));
        this._itemMenu.setAnchorPoint(cc.p(0,0));

        var label = new cc.LabelTTF("旋转X", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.rotateX, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,150));

        var label = new cc.LabelTTF("旋转Y", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.rotateY, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,180));

        var label = new cc.LabelTTF("旋转Z", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.rotateZ, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,210));

        var label = new cc.LabelTTF("翻转X", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.slX, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,240));

        var label = new cc.LabelTTF("翻转Y", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.slY, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,270));

        var label = new cc.LabelTTF("翻转Z", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.slZ, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,300));

        var label = new cc.LabelTTF("移动X", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.mvX, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,330));

        var label = new cc.LabelTTF("移动Y", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.mvY, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,360));

        var label = new cc.LabelTTF("移动Z", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.mvZ, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,390));

        var label = new cc.LabelTTF("整体放大", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.zoom, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,420));

        var label = new cc.LabelTTF("复位", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.restore, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(200,450));

        this.addChild(this._itemMenu);

        var label1 = new cc.LabelTTF("坐标:", "Arial", 24);
        label1.setPosition(cc.p(200,500));
        label1.setColor(cc.color(255,255,255));
        var label2=new cc.LabelTTF("旋转:", "Arial", 24);
        label2.setPosition(cc.p(200,530));
        label2.setColor(cc.color(255,255,255));
        var label3=new cc.LabelTTF("缩放:", "Arial", 24);
        label3.setPosition(cc.p(200,560));
        label3.setColor(cc.color(255,255,255));

        this.addChild(label1);
        this.addChild(label2);
        this.addChild(label3);

        this._lable1=label1;
        this._lable2=label2;
        this._lable3=label3;

        this._type=0;
    },
    onMouseScroll:function(event){
        var gap=event.getScrollY();
        switch (this._type){
            case 0:
            case 1:
            case 2:
                var rt=this._handObj.getRotation3D();
                if(this._type==0)
                    rt.x+=gap*1;
                else if(this._type==1)
                    rt.y+=gap*1;
                else
                    rt.z+=gap*1;
                this._handObj.setRotation3D(rt);
                break;
            case 3:
                var x=this._handObj.getScaleX();
                if(gap>0) this._handObj.setScaleX(Math.abs(x));
                else this._handObj.setScaleX(-Math.abs(x));
                break;
            case 4:
                var y=this._handObj.getScaleY();
                if(gap>0) this._handObj.setScaleY(Math.abs(y));
                else this._handObj.setScaleY(-Math.abs(y));
                break;
            case 5:
                var z=this._handObj.getScaleZ();
                if(gap>0) this._handObj.setScaleZ(Math.abs(z));
                else this._handObj.setScaleZ(-Math.abs(z));
                break;
            case 6:
            case 7:
            case 8:
                var pos=this._handObj.getPosition3D();
                if(this._type==6)
                    pos.x+=gap*1;
                else if(this._type==7)
                    pos.y+=gap*1;
                else
                    pos.z+=gap*1;
                this._handObj.setPosition3D(pos);
                break;
            case 9:
                var x=this._handObj.getScaleX();
                var y=this._handObj.getScaleY();
                var z=this._handObj.getScaleZ();
                gap=gap/3;

                x=(Math.abs(x)+gap)*(Math.abs(x)/x);
                y=(Math.abs(y)+gap)*(Math.abs(y)/y);
                z=(Math.abs(z)+gap)*(Math.abs(z)/z);
                //if(Math.abs(x)+gap>0.2){
                //    x=gap;
                //}
                //if(Math.abs(y+gap)>0.2){
                //    y+=gap;
                //}
                //if(Math.abs(z+gap)>0.2){
                //    z+=gap;
                //}
                this._handObj.setScaleX(x);
                this._handObj.setScaleY(y);
                this._handObj.setScaleZ(z);
                break;

        }

        var pos=this._handObj.getPosition3D();
        this._lable1.setString("坐标： x:"+Math.round(pos.x)+", y:"+Math.round(pos.y)+", z:"+Math.round(pos.z));

        var pos=this._handObj.getRotation3D();
        this._lable2.setString("旋转： x:"+Math.round(pos.x)+", y:"+Math.round(pos.y)+", z:"+Math.round(pos.z));

        var sx=this._handObj.getScaleX();
        var sy=this._handObj.getScaleY();
        var sz=this._handObj.getScaleZ();
        this._lable3.setString("缩放： x:"+sx+", y:"+sy+", z:"+sz);
    },

    rotateX:function(){
        this._type=0;
    },
    rotateY:function(){
        this._type=1;
    },
    rotateZ:function(){
        this._type=2;
    },

    slX:function(){
        this._type=3;
    },
    slY:function(){
        this._type=4;
    },
    slZ:function(){
        this._type=5;
    },

    mvX:function(){
        this._type=6;
    },
    mvY:function(){
        this._type=7;
    },
    mvZ:function(){
        this._type=8;
    },
    zoom:function(){
        this._type=9;
    },
    restore:function(){
        this._handObj.setScale(1.0);
        this._handObj.setScaleZ(1.0);
        this._handObj.setPosition3D(cc.math.vec3(cc.winSize.width/2,cc.winSize.height/2,100));
        this._handObj.setRotation3D(cc.math.vec3(0,0,0));
        //ngc.log.info(this._handObj.getRotation3D());
    },
    setAddedCards:function(cards){
        this.addCards=cards;
    },
    update:function(dt){
        if(this.toStates.length>0) {
            this.curState=this.toStates.shift();
            var packData=this.curState.packData;
        }
    },

    endPackDeal:function(){
        cc.eventManager.dispatchCustomEvent(PackEventName);
    },

    refreshCardsInfo:function(){
        var groupPos=ngc.game.mjpos[this._playerIndex];
        var cards1=this.cards[0];
        var poss1=cc.math.vec3(groupPos[0].x,groupPos[0].y,groupPos[0].z);
        for(var i=0;i<cards1.length;i++){
            var mjCard=this.generateOneMJCard(cards1[i],MJCardClass.SHOU);
            if(mjCard){
                mjCard.setPosition3D(poss1);
                if(this._playerIndex==0){
                    poss1.x+=this._mjWidthSelf;
                    this.layerCard1.addChild(mjCard);
                }
                else{
                    if(this._playerIndex==1)
                        poss1.z+=ngc.game.mjModelWidth;
                    else if(this._playerIndex==2)
                        poss1.x-=ngc.game.mjModelWidth;
                    else
                        poss1.z-=ngc.game.mjModelWidth;
                    this.layerCard1.addChild(mjCard);
                    mjCard.setCameraMask(2);
                }
            }
        }

        this.refreshCards2();

        this.refreshCards3();

        this.refreshCards4();

        if(this._playerIndex==0)
            this.initMyCardCamera();
    },

    //明牌
    refreshCards2:function(){
        var groupPos=ngc.game.mjpos[this._playerIndex];
        var cards2 = this.cards[1];
        this.layerCard2.removeAllChildren(true);    //先删除所有底牌的sp
        var gapPos=cc.math.vec3(0,0,0);
        var anGangType = 0;
        if(this._playerIndex==0)
            gapPos.x=-ngc.game.mjModelWidth;
        else if(this._playerIndex==1)
            gapPos.z=-ngc.game.mjModelWidth;
        else if(this._playerIndex==2)
            gapPos.x=ngc.game.mjModelWidth;
        else
            gapPos.z=ngc.game.mjModelWidth;
        var poss2=cc.math.vec3(groupPos[1].x,groupPos[1].y,groupPos[1].z);
        for(var i = 0, length = cards2.length; i < length; i++){
            var isAnGang = false;
            var cardsValue1 = cc.isNumber(cards2[i]) ? cards2[i] : cards2[i].cardValue;
            //暗杠最多有三个
            if(this.checkIsInAnGang(cardsValue1)) {
                if( (anGangType == 0 || anGangType == 4 || anGangType == 8) && this._playerIndex == 0){
                    var mjCard = this.generateOneMJCard(cardsValue1, MJCardClass.MING);
                }else{
                    var mjCard = this.generateOneMJCard(cardsValue1, MJCardClass.KOU);
                }
                anGangType ++;
                isAnGang = true;
            }
            else {
                //var ralativePos = cards2[i].ralativePos;
                //if (cc.isNumber(ralativePos)) {
                //    var mjCard = this.generateOneMJCard(cardsValue1, MJCardClass.KOU);
                //    if(this._playerIndex==0){
                //        mjCard.setRotation3D(cc.math.vec3(0, 180, 0));
                //    }else  if(this._playerIndex==1){
                //        mjCard.setRotation3D(cc.math.vec3(0, 270, 0));
                //    }else if(this._playerIndex==2){
                //        mjCard.setRotation3D(cc.math.vec3(0, 180, 0));
                //    }else{
                //        mjCard.setRotation3D(cc.math.vec3(0, 270, 0));
                //    }
                //}else{
                    var mjCard = this.generateOneMJCard(cardsValue1, MJCardClass.MING);
                //}
            }
            if(mjCard){
                if(cardsValue1 == -1 ){
                    poss2 = cc.math.vec3Add(poss2, cc.math.vec3Ride(gapPos,0.3));
                    continue;
                }
                mjCard.setPosition3D(poss2);
                if(isAnGang){
                    if(this._playerIndex==0)
                        var posAnGang=cc.math.vec3(poss2.x+0,poss2.y-0,poss2.z-0);
                    if(this._playerIndex==1)
                        var posAnGang=cc.math.vec3(poss2.x-1,poss2.y+0,poss2.z-0);
                    if(this._playerIndex==2)
                        var posAnGang=cc.math.vec3(poss2.x+0,poss2.y+0,poss2.z-2);
                    if(this._playerIndex==3)
                        var posAnGang=cc.math.vec3(poss2.x+0,poss2.y+0,poss2.z+0);
                    mjCard.setPosition3D(posAnGang);
                }
                mjCard.setCameraMask(2);
                poss2=cc.math.vec3Add(poss2, gapPos);
                this.layerCard2.addChild(mjCard);
            }
        }
    },

    refreshCards3:function(){
        var groupPos=ngc.game.mjpos[this._playerIndex];
        var cards3=this.cards[2];
        if(!cards3) return;
        var poss3=cc.math.vec3(groupPos[2].x,groupPos[2].y,groupPos[2].z);
        var children=this.layerCard3.getChildren();
        if(children.length>0){
            poss3=children[children.length-1].getPosition3D();
            if(this._playerIndex==0)
                poss3.x+=ngc.game.mjModelWidth;
            else if(this._playerIndex==1)
                poss3.z+=ngc.game.mjModelWidth;
            else if(this._playerIndex==2)
                poss3.x-=ngc.game.mjModelWidth;
            else
                poss3.z-=ngc.game.mjModelWidth;
        }
        if(children.length<cards3.length){
            for(var i=children.length;i<cards3.length;i++){
                switch (this._playerIndex){
                    case 0:
                    case 2:
                        if(i>0&&i%5==0){
                            poss3.x=groupPos[2].x;
                            poss3.y+=ngc.game.mjModelHeight;
                        }
                        break;
                    case 1:
                        if(i>0&&i%4==0){
                            poss3.x=groupPos[2].x;
                            poss3.z=groupPos[2].z;
                            poss3.y+=ngc.game.mjModelHeight;
                        }
                        else if(i>0&&i%2==0){
                            poss3.z=groupPos[2].z;
                            poss3.x=groupPos[2].x-ngc.game.mjModelLength;
                        }
                        break;
                    case 3:
                        if(i>0&&i%4==0){
                            poss3.z=groupPos[2].z;
                            poss3.y+=ngc.game.mjModelHeight;
                        }
                        break;
                }
                var mjCard=this.generateOneMJCard(cards3[i],MJCardClass.HU);
                if(mjCard){
                    mjCard.setPosition3D(poss3);
                    mjCard.setCameraMask(2);

                    if(this._playerIndex==0)
                        poss3.x+=ngc.game.mjModelWidth;
                    else if(this._playerIndex==1)
                        poss3.z+=ngc.game.mjModelWidth;
                    else if(this._playerIndex==2)
                        poss3.x-=ngc.game.mjModelWidth;
                    else
                        poss3.z-=ngc.game.mjModelWidth;
                    this.layerCard3.addChild(mjCard);
                }
            }
        }
    },

    //打出去的牌
    refreshCards4:function(){
        var groupPos=ngc.game.mjpos[this._playerIndex];
        var factor=1.1;
        var cards4=this.cards[3];
        if(!cards4) return;
        var poss=cc.math.vec3(groupPos[3].x,groupPos[3].y,groupPos[3].z);
        var children=this.layerCard4.getChildren();
        if(children.length<cards4.length){
            for(var i=children.length;i<cards4.length;i++){
                if(this._playerIndex%2==0){
                    poss.x=groupPos[3].x+(this._playerIndex==0?ngc.game.mjModelWidth*factor:-ngc.game.mjModelWidth*factor)*(i%8);
                    poss.z=groupPos[3].z+(this._playerIndex==0?ngc.game.mjModelLength+1:-ngc.game.mjModelLength-1)*Math.floor(i/8);
                }
                else{
                    poss.z=groupPos[3].z+(this._playerIndex==1?ngc.game.mjModelWidth*factor:-ngc.game.mjModelWidth*factor)*(i%8);
                    poss.x=groupPos[3].x+(this._playerIndex==1?-ngc.game.mjModelLength-1:ngc.game.mjModelLength+1)*Math.floor(i/8);
                }
                ngc.log.info("打出去的牌记录3: "+cards4[i]);
                var mjCard=this.generateOneMJCard(cards4[i],MJCardClass.CHU);
                mjCard.setScaleX(mjCard.getScaleX()*factor);
                var spriteValue=mjCard.getChildByTag(223344);
                if(spriteValue)
                    spriteValue.setScaleX(spriteValue.getScaleX()/factor);
                if(mjCard){
                    mjCard.setPosition3D(poss);
                    mjCard.setCameraMask(2);
                    this.layerCard4.addChild(mjCard);
                }
            }
        }
    },

    checkIsInAnGang:function(cardValue){
        for(var key=0 in this.cards[4]){
            if(this.cards[4][key]==cardValue){
                this.cards[4].splice(key,1);
                return true;
            }

        }
        return false;
    },

    /**
     * 放出要去交换的牌
     */
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
        var mjCardParent=this.generateOneMJCard(undefined,MJCardClass.HUAN);
        mjCardParent.setPosition3D(pos);

        for(var i=1;i<=2;i++){
            var mjCard=this.generateOneMJCard(undefined,MJCardClass.HUAN);
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

    showSwapAni:function(packData){
        if(packData&&packData.swapDirction==0)  //swapDirction 0:对家，1:顺时针，2:逆时针
        {
            this.scheduleOnce(this.pickUpSwapCards,3);
            return;
        }
        if(packData){
            this.scheduleOnce(function(){
                this.layerCard5.unscheduleUpdate();
                this.layerCard5.update=this.rotateSwapCards;
                this.layerCard5.scheduleUpdate();
                this.layerCard5.center=cc.math.vec3(668,ngc.game.mjpos[this._playerIndex][MJCardClass.HUAN].y,-195);
                this.layerCard5.initAngle=packData.swapDirction==1?90:-90;
                this.layerCard5.passAngle=0;
                this.layerCard5.gapTime=0;
                this.layerCard5.part=this;
                var comIndex=packData.swapDirction==1?this._playerIndex+1:this._playerIndex-1;
                if(comIndex>3) comIndex=0;
                else if(comIndex<0) comIndex=3;
                this.layerCard5.completedCIndex=comIndex;           //旋转完后所在方向
            },1);
        }
    },

    rotateSwapCards:function(dt){
        this.gapTime+=dt;
        if(this.gapTime>=0.04){
            this.gapTime=0;

            var mjCard=this.getChildren()[0];
            var pos=mjCard.getPosition3D();

            var angle=5*(Math.abs(this.initAngle)/this.initAngle);
            this.passAngle+=angle;
            var completed=false;
            if(Math.abs(this.passAngle)>=Math.abs(this.initAngle)){
                this.unscheduleUpdate();
                if(Math.abs(this.passAngle)>Math.abs(this.initAngle))
                    angle-=(Math.abs(this.passAngle)-Math.abs(this.initAngle))*(Math.abs(this.initAngle)/this.initAngle);
                completed=true;
            }
            var radian=cc.degreesToRadians(angle);

            var center=this.center;
            var x1=(pos.x-center.x)*Math.cos(radian)-(pos.z-center.z)*Math.sin(radian)+center.x;
            var z1=(pos.x-center.x)*Math.sin(radian)+(pos.z-center.z)*Math.cos(radian)+center.z;
            var newPos=cc.math.vec3(x1,pos.y,z1);
            mjCard.setPosition3D(newPos);

            var rotation = mjCard.getRotation3D();
            rotation.y-=angle;
            mjCard.setRotation3D(rotation);

            var compareNum=angle>0?40:80;
            if(Math.abs(this.passAngle)>compareNum&&Math.abs(this.passAngle)-compareNum<=5){//改纹理
                var texture=cc.textureCache.addImage(ngc.game.mjtextures[this.completedCIndex][MJCardClass.HUAN]);
                mjCard.setTexture(texture);
                var children=mjCard.getChildren();
                for(var key=0 in children){
                    children[key].setTexture(texture);
                }
                if(angle>0&&this.completedCIndex%2==1){
                    rotation.y+=180;
                    mjCard.setRotation3D(rotation);
                }
                else if(angle<0&&this.completedCIndex%2==0){
                    rotation.y+=180;
                    mjCard.setRotation3D(rotation);
                }
            }

            if(completed) {
                this.scheduleOnce(function(){this.part.pickUpSwapCards()},1);
            }
        }
    },

    isInAddedCards:function(cardValue){
        if(this.addCards){
            for(var key=0 in this.addCards){
                if(this.addCards[key]==cardValue){
                    this.addCards.splice(key,1);
                    return true;
                }
            }
        }
        return false;
    },

    /**
     * 捡起交换的牌
     */
    pickUpSwapCards:function(){
        this.layerCard5.removeAllChildren(true);

        this.resetDarkCardNum();

        if(this._playerIndex==0){
            var children=this.layerCard1.getChildren();
            for(var key=0 in children){
                this.changeMJCardValue(this.cards[0][key],children[key]);
                if(this.isInAddedCards(this.cards[0][key]))
                    this.popOneCard(children[key]);
            }
            this.scheduleOnce(this.unSelectedCard,2);
        }
        this.arrangementDarkCards();
        this.endState();
    },

    /**
     * @param all (true:全方位(x,y,z)整理,false:水平方向(x或者z)
     */
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
                if(ngc.game.mjrotations[this._playerIndex][MJCardClass.SHOU])
                    mjCardsDark[key].setRotation3D(ngc.game.mjrotations[this._playerIndex][MJCardClass.SHOU]);
            }
        }
        if(!notEndDeal)
            this.endPackDeal();
    },

    /**
     * 将最后一张置为刚摸到的牌(只在断线重连时用)
     */
    moveLastMjToMo:function(){
        if(this._playerIndex==0){
            var mjCards=this.layerCard1.getChildren();
            if(mjCards.length>0){
                var mjCard=mjCards[mjCards.length-1];
                var pos=mjCard.getPosition3D();
                pos.x+=20;
                mjCard.setPosition3D(pos);
            }
        }
    },

    /**
     * 更新牌
     * @param cards
     * @param index (0:暗牌,1:明牌,2:胡牌,3:打出去的牌)
     */
    updateCards:function(cards,index,sort){
        if(sort)
            cards.sort(function(a,b){
                return a-b;
            });
        this.cards[index]=cards;
    },

    initMyCardCamera:function(){
        this.layerCard1.setCameraMask(cc.CameraFlag.USER2);
    },

    /**
     * 获取选中的牌的值
     */
    getSelectedCards:function(isValue){
        var ret=[];
        var children=this.layerCard1.getChildren();
        for(var key=0 in children){
            if(children[key].getPositionY()>ngc.game.mjpos[0][0].y){
                if(isValue){
                    if(this.cards[0][key]!=undefined)
                        ret.push(this.cards[0][key]);
                }
                else
                    ret.push(children[key]);
            }
        }
        return ret;
    },

    /**
     * 自动弹出换牌
     * @param index
     * @param length
     */
    autoPopSelectedCard:function(index,length){
        var children=this.layerCard1.getChildren();
        if(length>0){
            var cardTypeNum=[0,0,0];
            for(var key=0 in this.cards[0]){
                var type=Math.floor(this.cards[0][key]/9);
                cardTypeNum[type]++;
            }
            var fromCardType=0;
            var minNum=-1;
            for(var key=0 in cardTypeNum){
                if(cardTypeNum[key]>=3){
                    if((minNum==-1)||cardTypeNum[key]<minNum){
                        minNum=cardTypeNum[key];
                        fromCardType=key;
                    }
                }
            }

            var childrenToPop=[];
            for(var key=0 in this.cards[0]){
                if(Math.floor(this.cards[0][key]/9)==fromCardType&&childrenToPop.length<3){
                    childrenToPop.push(children[key]);
                    if(children[key])
                        this.popOneCard(children[key]);
                }
            }
        }
    },

    unSelectedCard:function(){
        var children=this.layerCard1.getChildren();
        for(var key=0 in children){
            if(children[key].getPositionY()>ngc.game.mjpos[0][0].y){
                children[key].setPositionY(ngc.game.mjpos[0][0].y);
            }
        }

        //所有玩家进入选确状态
        this.scheduleOnce(function(){
            var data={
                op:opSelfAction.mjAllLackTip
            };
            cc.eventManager.dispatchCustomEvent(OPEventName,data);
        },0.6);
    },

    popOneCard:function(mjCard){
        if(this._playerIndex==0)
            mjCard.setPositionY(ngc.game.mjpos[0][0].y+this._popGapYSelf);
        else
            mjCard.setPositionY(ngc.game.mjpos[0][0].y+this._popGapYOther);
    },

    getDarkCard:function(index,length){
        var children=this.layerCard1.getChildren();
        if(length>0)
            return children.slice(index,index+length);
        else
            return children;
    },

    getCardsByIndex:function(index){
        return this.cards[index];
    },

    generateOneMJCard:function(cardValue,mjcardclass){
        var sprite = ngc.game.createMj(this._playerIndex,mjcardclass);
        if(cardValue>=0){
            this.changeMJCardValue(cardValue,sprite,mjcardclass);
        }
        return sprite;
    },

    generateOneMJCardIn2D:function(cardValue){
        var sprite=new cc.Sprite(ngc.game.pngRes.mjBg);
        if(cardValue>=0){
            var sprite2=new cc.Sprite();
            sprite2.initWithSpriteFrameName(getCardResByValue(cardValue));
            sprite2.setPosition(cc.p(sprite.getContentSize().width/2,sprite.getContentSize().height/2-4));
            sprite2.setScale(0.8)
            sprite.addChild(sprite2);
            sprite.setScale(0.8);
        }
        return sprite;
    },

    changeMJCardValue:function(newCardValue,mjCard,mjcardclass){
        //牌面
        cc.spriteFrameCache.addSpriteFrames("res/g/mjBloody/card/cards.plist");

        if(newCardValue>=0&&mjCard){
            if(!mjCard.getChildByTag(223344)){
                var spriteCardMesh3D = new jsb.Sprite3D();
                var sprite=cc.Sprite.create();
                var res=getCardResByValue(newCardValue);
                if(cc.spriteFrameCache.getSpriteFrame(res))
                    sprite.initWithSpriteFrameName(res);

                spriteCardMesh3D.addChild(sprite,0,112233);

                spriteCardMesh3D.setPosition3D(cc.math.vec3(0,-11,0));
                if((this._playerIndex==0||this._playerIndex==3)&&(mjcardclass==MJCardClass.CHU||mjcardclass==MJCardClass.HU||mjcardclass==MJCardClass.MING))
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90,0,0));
                else if(this._playerIndex==0&&mjcardclass==MJCardClass.SHOU)
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90,0,0));
                else
                    spriteCardMesh3D.setRotation3D(cc.math.vec3(90,180,0));

                spriteCardMesh3D.setScale(0.33);
                spriteCardMesh3D.setScaleZ(0.33);

                mjCard.addChild(spriteCardMesh3D,0,223344);
            }
            else{
                var spriteCardMesh3D = mjCard.getChildByTag(223344);
                var sprite=spriteCardMesh3D.getChildByTag(112233);
                if(sprite){
                    var res=getCardResByValue(newCardValue);
                    var frame=cc.spriteFrameCache.getSpriteFrame(res);
                    if(frame)
                        sprite.setSpriteFrame(frame);
                }
            }
        }
    },

    resetDarkCardNum:function(){
        var children=this.layerCard1.getChildren();
        var lastChild=children[children.length-1];
        var cards=this.cards[0];

        if(children.length>cards.length) {
            for(var i=cards.length;i<children.length;i++){
                children[i].removeFromParent(true);
            }
        }
        else if(children.length<cards.length){
            var gapPos=cc.math.vec3(0,0,0);
            if(this._playerIndex%2==0)
                gapPos.x=this._playerIndex==0?this._mjWidthSelf:-ngc.game.mjModelWidth;
            else
                gapPos.z=this._playerIndex==1?ngc.game.mjModelWidth:-ngc.game.mjModelWidth;
            for(var i=children.length;i<cards.length;i++){
                var mjCard=this.generateOneMJCard(cards[i],MJCardClass.SHOU);
                mjCard.setRotation3D(lastChild.getRotation3D());
                mjCard.setPosition3D(cc.math.vec3Add(lastChild.getPosition3D(),gapPos));
                if(this._playerIndex==0){
                    mjCard.setCameraMask(cc.CameraFlag.USER2);
                }
                else{
                    mjCard.setCameraMask(cc.CameraFlag.USER1);
                }
                this.layerCard1.addChild(mjCard);
                lastChild=mjCard;
            }
        }
    },

    resetDarkCardValue:function(){
        var children=this.layerCard1.getChildren();
        var cards=this.cards[0];
        for(var key=0 in children){
            if(cards[key]!=undefined)
                this.changeMJCardValue(cards[key],children[key]);
        }
    },

    receiveDealMjAni:function(num, isLastCard){
        var _sFlag = 0;
        var children=this.layerCard1.getChildren();
        var startIndex=0;
        for(startIndex;startIndex<children.length;startIndex++) {
            if (!children[startIndex].isVisible())
                break;
        }
        var toAniChildren=children.slice(startIndex,startIndex+num);
        for(var key=0 in toAniChildren){
            toAniChildren[key].setVisible(true);
            var initRotation=toAniChildren[key].getRotation3D();
            if(this._playerIndex==0){
                initRotation.x+=130;
                toAniChildren[key].setRotation3D(initRotation);
                toAniChildren[key].runAction(cc.sequence(cc.callFunc(function () {
                    if (_sFlag == 0) {
                        if (!ngc.hall.musicGame.mapai)
                            ngc.log.info("Error : file is not found file = mapai");
                        if(ngc.flag.SOUND_FLAG) {
                            ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame.mapai);
                        }
                    }
                    _sFlag++;
                }, this), cc.rotateBy(this._paiRotateSpeed,cc.math.vec3(-130,0,0))));

            }
            else {
                if(this._playerIndex==2){
                    initRotation.x-=90;
                    var rby=cc.math.vec3(90,0,0);
                }
                else if(this._playerIndex==1){
                    initRotation.z-=90;
                    var rby=cc.math.vec3(0,0,90);
                }
                else if(this._playerIndex==3){
                    initRotation.z+=90;
                    var rby=cc.math.vec3(0,0,-90);
                }
                toAniChildren[key].setRotation3D(initRotation);
                toAniChildren[key].runAction(cc.rotateBy(this._paiRotateSpeed,rby));
            }
        }

        if(this._playerIndex==0&&isLastCard){
            toAniChildren[0].runAction(cc.sequence(cc.delayTime(0.6),cc.callFunc(this.sortDarkCardAni,this)));
        }
    },


    /*receiveDealMjAni:function(num){
        var children=this.layerCard1.getChildren();
        var startIndex=0;
        for(startIndex;startIndex<children.length;startIndex++) {
            if (!children[startIndex].isVisible())
                break;
        }
        var toAniChildren=children.slice(startIndex,startIndex+num);
        for(var key=0 in toAniChildren){
            toAniChildren[key].setVisible(true);
            var initRotation=toAniChildren[key].getRotation3D();
            if(this._playerIndex==0){
                initRotation.x+=130;
                toAniChildren[key].setRotation3D(initRotation);
                if(this._playerIndex==0&&num==1){
                    toAniChildren[key].runAction(cc.sequence(cc.rotateBy(0.6,cc.math.vec3(-130,0,0)),cc.callFunc(this.sortDarkCardAni,this)));
                }
                else{
                    toAniChildren[key].runAction(cc.rotateBy(0.6,cc.math.vec3(-130,0,0)));
                }
            }
            else {
                if(this._playerIndex==2){
                    initRotation.x-=90;
                    var rby=cc.math.vec3(90,0,0);
                }
                else if(this._playerIndex==1){
                    initRotation.z-=90;
                    var rby=cc.math.vec3(0,0,90);
                }
                else if(this._playerIndex==3){
                    initRotation.z+=90;
                    var rby=cc.math.vec3(0,0,-90);
                }
                toAniChildren[key].setRotation3D(initRotation);
                toAniChildren[key].runAction(cc.rotateBy(0.6,rby));
            }
        }
    },*/

    sortDardCard:function(){
        this.cards[0].sort(function(a,b){return a-b;});
    },

    sortDarkCardAni:function(){
        this.sortDardCard();

        var children=this.layerCard1.getChildren();
        for(var i=0;i<children.length;i++){
            var one=children[i];
            var r1 = cc.rotateBy(0.3,cc.math.vec3(120,0,0));
            var cb = cc.callFunc(function(){
                for(var key=0 in children){
                    this.changeMJCardValue(this.cards[0][key],children[key]);
                }
            },this);
            var d1=cc.delayTime(0.1);
            var r2=cc.rotateBy(0.3,cc.math.vec3(-120,0,0));
            var seq=cc.sequence(r1,cb,d1,r2);
            one.runAction(seq);
        }
    },

    /**
     * 抓一张牌的动画
     * @param endDeal 是否结束处理
     */
    grabOneCardAni:function(endDeal){
        var gap1=this._playerIndex==0?100:ngc.game.mjModelLength;
        var gap2=20;
        var gap3=this._playerIndex==0?this._mjWidthSelf+20:ngc.game.mjModelWidth+5;
        var time1=0.0888;
        var time2=0.16666;

        var children=this.layerCard1.getChildren();
        var darkCards=this.cards[0];

        var lastCardPos=children[children.length-1].getPosition3D();
        lastCardPos.y+=gap1;

        var rotation=children[children.length-1].getRotation3D();
        if(this._playerIndex%2==0){
            lastCardPos.x+=-1*(this._playerIndex-1)*gap3;
            var r1=cc.rotateTo(time1,rotation);//cc.math.vec3(0,0,gap2)
            rotation.z-=gap2;
        }
        else if(this._playerIndex%2==1){
            lastCardPos.z+=-1*(this._playerIndex-2)*gap3;
            var r1=cc.rotateTo(time1,rotation);//cc.math.vec3(0,-gap2,0)
            rotation.y+=gap2;
        }

        var newCardValue=darkCards[darkCards.length-1];
        var mjCard=this.generateOneMJCard(newCardValue,MJCardClass.SHOU);
        this.layerCard1.addChild(mjCard);
        if(this._playerIndex==0){
            mjCard.setCameraMask(cc.CameraFlag.USER2);
        }
        else{
            mjCard.setCameraMask(cc.CameraFlag.USER1);
        }
        mjCard.setPosition3D(lastCardPos);
        mjCard.setRotation3D(rotation);
        lastCardPos.y=ngc.game.mjpos[this._playerIndex][MJCardClass.SHOU].y;
        var mv=cc.moveTo(time2,lastCardPos);
        var cb=cc.callFunc(function(){
            this.setMJIsMoveing(mjCard,false);
            this.endPackDeal();
            this.endState();
        },this);
        mjCard.runAction(cc.sequence(r1,mv,cc.delayTime(0.4),cb));
        this.setMJIsMoveing(mjCard,true);
    },

    checkIsMoveing:function(mjCard){
        if(mjCard.ismoveing) return true;
        return false;
    },
    setMJIsMoveing:function(mjCard,moveing){
        mjCard.ismoveing=moveing;
    },

    showSuggestedDiscard:function(){
        if(this._gameLogic){
            this._gameLogic.reset(this.cards[0]);
            this._gameLogic.parseCards();
            var suggested=this._gameLogic.getSuggestedCards();
            ngc.log.info(suggested);
        }
    },

    //出一张牌的动画
    discardOneCardAni:function(packData){
        if(this._playerIndex==0)
            this.removeFromSelf(packData);
        else
            this.randomRemoveOneCard();

        this.refreshCards4();

        this.showDicardHandAni();

        this.scheduleOnce(function(){
            this.showArrangeCardHandAni();
        },2);
    },

    //移动新抓的牌
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

        if(this._playerIndex==0){
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
        }
        else{
            var moveToIndex=Math.round(Math.random()*(children.length-2));
            cc.moveByDelegate=cc.moveByPull3DObj;
        }

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

    moveCardIndex:function(fromIndex,moveToIndex){
        var children=this.layerCard1.getChildren();
        if(fromIndex>=children.length||moveToIndex>=children.length) return;
        if(fromIndex<0||moveToIndex<0) return;

        var moveChildren=children.slice(Math.min(moveToIndex,fromIndex));
        for(var key=0 in moveChildren){
            moveChildren[key].retain();
            moveChildren[key].removeFromParent(false);
        }
        this.layerCard1.addChild(children[fromIndex]);
        for(var key=0 in moveChildren){
            if(moveChildren[key]!=children[fromIndex])
                this.layerCard1.addChild(moveChildren[key]);
            moveChildren[key].release();
        }
        if(this._playerIndex==0){
            this.resetDarkCardNum();
            this.resetDarkCardValue();
        }
        this.arrangementDarkCards(true,true);
    },

    //碰、杠移动暗牌到明牌
    //碰、杠移动暗牌到明牌
    moveDarkCardToOpendCardSelf:function(action,cardValue,packdate){
        var maxNum=2;
        if(action!=opServerActionCodes.mjaPeng && action!=opServerActionCodes.mjaChi){
            maxNum=14;
        }
        var children = this.layerCard1.getChildren();
        if(action == opServerActionCodes.mjaChi ||action == opServerActionCodes.mjaTingChi){
            var chiAry = [];
            var otherChiArry = this.getChiPais(cardValue, packdate.order); //获取手牌里面两个吃的牌
            for(var key = 0, length = this.cards[0].length; key < length; key++){
                for(var k = otherChiArry.length - 1; k > -1; k--){
                    var cardOtherValue = otherChiArry[k];
                    if(this.cards[0][key] == cardOtherValue){
                        this.cards[0].splice(key, 1)
                        var rm = children.splice(key, 1);
                        rm[0].removeFromParent(false);
                        chiAry.push(otherChiArry[k]);
                        otherChiArry.splice(k, 1);
                        key--;
                        maxNum--;
                        if(maxNum<=0)  break;
                        children=this.layerCard1.getChildren();
                    }
                }
            }
        }
        else if(action == opServerActionCodes.mjaSpecialGang || action == opServerActionCodes.mjaTingGang){
            ngc.log.info("deleteShouPai: " + JSON.stringify(packdate.gangCards)); // log
            var gangAry = packdate.gangCards;
            for(var key = 0, length = this.cards[0].length; key < length; key++){
                for(var k = gangAry.length - 1; k > -1; k--){
                    var cardOtherValue = gangAry[k];
                    if(this.cards[0][key] == cardOtherValue){
                        if(action == opServerActionCodes.mjaTingGang){
                            this.cards[0].splice(key, 1)
                        }else{
                            this.insertToOpenCard(this.cards[0].splice(key, 1));
                        }
                        var rm = children.splice(key, 1);
                        rm[0].removeFromParent(false);
                        key--;
                        maxNum--;
                        if(maxNum<=0)  break;
                        children = this.layerCard1.getChildren();
                    }
                }
            }
        }else {
            for (var key = 0; key < this.cards[0].length; key++) {
                if (this.cards[0][key] == cardValue) {
                    this.insertToOpenCard(this.cards[0].splice(key, 1));
                    var rm = children.splice(key, 1);
                    rm[0].removeFromParent(false);
                    key--;
                    maxNum--;
                    if (maxNum <= 0) break;
                    children = this.layerCard1.getChildren();
                }
            }
        }
        if(action == opServerActionCodes.mjaDaMingGang || action==opServerActionCodes.mjaPeng || action==opServerActionCodes.mjaTingPeng){
            this.insertToOpenCard([cardValue], packdate);// 从打出的玩家中拿过一个
        }
        else if(action==opServerActionCodes.mjaJiaGang){
            this.layerCard2.removeAllChildren(true);
        }else if(action==opServerActionCodes.mjaAnGang){
            this.cards[4].push(cardValue,cardValue,cardValue);
        }else if(action == opServerActionCodes.mjaTingGang){
            if(packdate.gangCards[0] == packdate.gangCards[1]){
                for(var k = 0; k < packdate.gangCards.length ; ++k ){
                    this.cards[1].push(packdate.gangCards[k]);
                    this.cards[4].push(packdate.gangCards[k]);
                }
                ngc.log.info("----------------")
            }else{
                for(var k = 0; k < packdate.gangCards.length ; ++k ){
                    this.cards[1].push(packdate.gangCards[k]);
                }
            }
        }else if(action == opServerActionCodes.mjaChi ||action == opServerActionCodes.mjaTingChi) {
            chiAry.splice(1, 0, cardValue);
            for(var k = 0; k < chiAry.length; ++k ){
                this.cards[1].push(chiAry[k]);
            }
        }else if(action == opServerActionCodes.mjaSpecialGang){
            this.cards[4].concat(packdate.gangCards);
        }

        this.cards[1].push(-1);
        this.showPengGangHandAni(cardValue);
    },

    getChiPais:function(cardValue, order){
        if(cc.isNumber(order)){
            var cardValue_1 = null;
            var cardValue_2 = null;
            if(order === 0){
                cardValue_1 = cardValue + 1;
                cardValue_2 = cardValue + 2;
            }else if(order === 1){
                cardValue_1 = cardValue - 1;
                cardValue_2 = cardValue + 1;
            }else if(order === 2){
                cardValue_1 = cardValue - 2;
                cardValue_2 = cardValue - 1;
            }
            return [cardValue_1, cardValue_2];
        }
    },

    moveDarkCardToOpendCardOther:function(action,cardValue,data){
        var rmLen=0;
        var children=this.layerCard1.getChildren();
        switch (action){
            case opServerActionCodes.mjaPeng:
            case opServerActionCodes.mjaTingPeng:
                var ralativePos = this.getRalativePos(data["lpos"], data["cpos"]) + 1;
                var ralativePos2 = this.getRalativePos(data["lpos"], data["cpos"]);
                if (ralativePos == 2 || ralativePos == 0) {
                    ralativePos = ralativePos == 2 ? 0 : 2;
                }
                for (var q = 0; q <= 2; q++) {
                    if (q !== ralativePos) {
                        this.cards[1].push(data["card"]);
                    } else {
                        this.cards[1].push({cardValue: data["card"], ralativePos: ralativePos2});
                    }
                }
                rmLen=2;
                break;
            case opServerActionCodes.mjaDaMingGang:
                var ralativePos = this.getRalativePos(data["lpos"], data["cpos"]) + 1;
                var ralativePos2 = this.getRalativePos(data["lpos"], data["cpos"]);
                if (ralativePos == 2 || ralativePos == 0) {
                    ralativePos = ralativePos == 2 ? 0 : 3;
                }
                for (var q = 0; q <= 3; q++) {
                    if (q !== ralativePos) {
                        this.cards[1].push(data["card"]);
                    } else {
                        this.cards[1].push({cardValue: data["card"], ralativePos: ralativePos2});
                    }
                }
                rmLen=3;
                break;
            case opServerActionCodes.mjaAnGang:
                this.cards[1].push(cardValue,cardValue,cardValue,cardValue);
                this.cards[4].push(cardValue,cardValue,cardValue);
                rmLen=4;
                break;
            case opServerActionCodes.mjaSpecialGang:
                if(data.gangCards.length && data.gangCards.length > 0){
                    for(var k = 0; k < data.gangCards.length ; ++k ){
                        this.cards[1].push(data.gangCards[k]);
                        //if(k > 0)
                            //this.cards[4].push(data.gangCards[k]);
                    }
                }
                rmLen = 4;
                break;
            case opServerActionCodes.mjaTingGang:
                if(data.gangCards.length && data.gangCards.length > 0){
                    if(data.gangCards[0] == data.gangCards[1]){
                        for(var k = 0; k < data.gangCards.length ; ++k ){
                            this.cards[1].push(data.gangCards[k]);
                            if(k > 0)
                                this.cards[4].push(data.gangCards[k]);
                        }
                    }else{
                        for(var k = 0; k < data.gangCards.length ; ++k ){
                            this.cards[1].push(data.gangCards[k]);
                        }
                    }
                }
                rmLen = 4;
                break;
            case opServerActionCodes.mjaChi:
            case opServerActionCodes.mjaTingChi:
                var order = data.order;
                var cardValueArry = this.getChiPais(cardValue, order);
                this.cards[1].push(cardValueArry[0], cardValue, cardValueArry[1]);
                rmLen = 2;
                break;
            case opServerActionCodes.mjaJiaGang:
                for(var key=0 in this.cards[1]){
                    if(this.cards[1][key]==cardValue){
                        this.cards[1].splice(key,0,cardValue);
                        break;
                    }
                }
                rmLen = 1;
                this.layerCard2.removeAllChildren(true);
                break;
        }
        for(var i=0;i<rmLen;i++){
            if(children[i])
                children[i].removeFromParent(true);
        }
        this.cards[1].push(-1);
        this.showPengGangHandAni(cardValue);
    },

    getRalativePos: function (lp, cp) {
        var diffValue = lp - cp;
        if (Math.abs(diffValue) == 2) {
            return 0;
        } else if (Math.abs(diffValue) == 1) {
            if (diffValue > 0)
                return 1;
            else
                return -1;
        } else {
            if (diffValue > 0)
                return -1;
            else
                return 1;
        }
    },

    // 加杠数据变为碰， 如果被加杠胡牌，则自己的加杠不成功，要还原成碰
    mdfJiaGang2Peng: function (cardId) {
        var len = this.cards[1].length;
        var children = this.layerCard2.getChildren();
        if(len>0&&children.length>0) {
            if (cardId >= 0 && this.cards[1][len - 1] != cardId)
                return;

            var hasNum=0;
            for(var key=0 in this.cards[1]){
                if(this.cards[1][key]==cardId){
                    hasNum++;
                }
            }
            if(hasNum>3){
                this.cards[1].pop();
                var lastChild = children[children.length - 1];
                lastChild.removeFromParent(true);
            }
        }
        else
        {
            this.layerCard2.removeAllChildren(true);
            this.refreshCards2();
        }
    },

    //删除最后打出的一张牌
    removeLastDiscard:function(card){
        var len = this.cards[3].length;
        var children = this.layerCard4.getChildren();
        if(len>0&&children.length>0) {
            if (card >= 0 && this.cards[3][len - 1] != card)
                return;

            this.cards[3].pop();
            var lastChild = children[children.length - 1];
            lastChild.removeFromParent(true);
        }
    },
    /**
     * 查看给定的值是不是最后一张
     * @param card
     */
    getLastDiscardByValue:function(card){
        var children = this.layerCard4.getChildren();
        if(card>=0&&this.cards[3].length>0&&children.length>0){
            var len = this.cards[3].length;
            if (this.cards[3][len - 1] == card){
                return children[children.length-1];
            }
        }
    },

    insertToOpenCard: function (cardvalues, packdata) {
        if (cardvalues.length <= 0)
            return;
        do{
            if(!packdata){
                for(var key=0 in this.cards[1]){
                    if(this.cards[1][key]==cardvalues[0]){
                        this.cards[1].splice(key,0,cardvalues[0]);
                        return;
                    }
                }
                this.cards[1].push(cardvalues[0]);
                break;
            }
            if(packdata && packdata.action == opServerActionCodes.mjaJiaGang){
                this.cards[1].push({cardValue: cardvalues[0], isJiaGang: true});
                break;
            }
            if(packdata && packdata.action == opServerActionCodes.mjaAnGang){
                this.cards[1].push(cardvalues[0]);
                break;
            }

            if(packdata && (packdata.action == opServerActionCodes.mjaDaMingGang ||packdata.action == opServerActionCodes.mjaPeng  || packdata.action==opServerActionCodes.mjaTingPeng )){
                var ralativePos = 0;
                var cardValue = cardvalues[0];
                ralativePos = this.getRalativePos(packdata.lpos, packdata.cpos) + 1;
                cardValue = {cardValue: cardvalues[0], ralativePos: ralativePos - 1};
                if (ralativePos == 2 || ralativePos == 0) {
                    ralativePos = ralativePos == 2 ? 0 : 2;
                }
                if (packdata.action == opServerActionCodes.mjaDaMingGang) {
                    if (ralativePos == 2)
                        ralativePos = 3;
                }
                for (var key = 0 in this.cards[1]) {
                    if (this.cards[1][key] == cardvalues[0]) {
                        var value = parseInt(key) + parseInt(ralativePos);
                        this.cards[1].splice(value, 0, cardValue);
                        ngc.log.info("card1" + JSON.stringify(this.cards[1]));
                        return;
                    }
                }
                break;
            }
        }while (false);
    },

    //胡牌
    moveToHuCard:function(isZimo,cardValue,lpos,huCount){
        if(isZimo){
            var children=this.layerCard1.getChildren();
            if(children[children.length-1])
                children[children.length-1].removeFromParent(true);

            this.cards[0].pop();
        }
        if(!this.cards[2]){
            this.cards[2] = [];
        }
        this.cards[2].push(cardValue);
        if(!isZimo&&lpos>=0){
            var player=this.scene.getPlayerBySIndex(lpos);
            if(player&&player.getPlayerIndex()!=this._playerIndex){//显示点炮效果
                var mjCard=player.getLastDiscardByValue(cardValue);
                if(mjCard){
                    var gl2DPos=this.convert3dPosTo2dGLPos(mjCard);
                    this.scene.table2d.showLuoLei(player.getPlayerIndex(),gl2DPos,function(){
                        player.removeLastDiscard(cardValue);
                        this.refreshCards3();
                        if(huCount>1)
                            this.opacityLastHuPai(cardValue);
                        this.showHuPaiHandAni();
                    },this);
                    return;
                }
            }
        }

        this.refreshCards3();
        /*if(huCount>1)
            this.opacityLastHuPai(cardValue);*/
        this.showHuPaiHandAni();
    },

    opacityLastHuPai:function(cardValue){
        var children=this.layerCard3.getChildren();
        var cards=this.cards[2];
        if(children.length>0&&children.length==cards.length&&cardValue==cards[cards.length-1]){
            //children[children.length-1].setColor(cc.color(255,255,0));
        }
    },

    sendDiscardAction:function(index){
        ngc.log.info("this.curState.state = "+this.curState.state);
        if(this.curState.state == PlayerState.MOPAISHOW || this.curState.state == PlayerState.YAPPAISHOW){
            this.setTempDiscardedCardIndex(index);
            if(this.cards[0][index]!=undefined){
                var data={
                    op:opSelfAction.mjDiscard,
                    cardId:this.cards[0][index]
                };
                ngc.log.info("data =" + JSON.stringify(data));
                cc.eventManager.dispatchCustomEvent(OPEventName,data);
            }
        }
    },

    setTempDiscardedCardIndex:function(index){
        this.tempDiscardedCardIndex=index;
    },

    getTempDiscardedCardIndex:function(){
        if(this.tempDiscardedCardIndex){
            var temp=this.tempDiscardedCardIndex;
            delete this.tempDiscardedCardIndex;
            return temp;
        }
    },

    randomRemoveOneCard:function(){
        var children = this.layerCard1.getChildren();
        // var player = this.scene.getPlayerByCIndex(this._playerIndex);
        // if(player.getTingState()){
        //     var index = children.length - 1;
        //     this.scene.turnOffSelfLight(this._playerIndex);
        // }else{
            var index = Math.round(Math.random() * (children.length - 1));
        // }
        if(children[index])
            children[index].removeFromParent(true);

        this.cards[0].splice(0, 1);
    },

    removeFromSelf:function(packData){
        var discardIndex=this.getTempDiscardedCardIndex();
        if(discardIndex>=0&&this.cards[0][discardIndex]!=packData.card){
            discardIndex=undefined;
        }
        if(discardIndex==undefined&&packData&&packData.card!=undefined){
            for(var i=this.cards[0].length-1;i>=0;i--){
                if(this.cards[0][i]==packData.card){
                    discardIndex=i;
                    break;
                }
            }
        }
        if(discardIndex!=undefined){
            this.cards[0].splice(discardIndex,1);
            var children=this.layerCard1.getChildren();
            if(children[discardIndex]) children[discardIndex].removeFromParent(true);
        }
    },

    onExit:function(){
        this._super();
    },

    initGameLogic:function(){
        var gameLogic=new ngc.game.gameLogic([]);
        this._gameLogic=gameLogic;
    },

    removeClickEvent:function(){
        cc.eventManager.removeListener(this.layerCard1);
    },

    addClickEvent:function(){
        cc.eventManager.removeListener(this.layerCard1);
        var me=this;
        var listener = cc.EventListener.create({
            event: cc.EventListener.TOUCH_ONE_BY_ONE,
            swallowTouches: false,
            onTouchBegan: function (touch, event) {
                if(me._movedSprite){
                    var temp=me._movedSprite;
                    me._movedSprite=null;
                    temp.removeFromParent(true);
                }
                me._movedY=0;
                me._movedKey=-1;
                me._movedSprite=null;
                return true;
            },
            onTouchEnded:function(touch, event){
                if(me._movedSprite){
                    var temp=me._movedSprite;
                    me._movedSprite=null;
                    temp.removeFromParent(true);
                }
                if(me._movedY>=30&&me._movedKey>=0){
                    me.sendDiscardAction(me._movedKey);
                }
                else{
                    var location = touch.getLocation();
                    var ray=location;//var ray = me.calculateRayByLocationInView(location);
                    me.checkDarkCardTouch(ray);
                }
            },
            onTouchMoved:function(touch,event){
                var delta = touch.getDelta();
                me._movedY+=delta.y;
                me.checkDarkCardMoved(delta,touch.getLocation(),touch.getLocationInView(),me._movedKey);
            },
            onTouchCancelled:function(){
                if(me._movedSprite){
                    var temp=me._movedSprite;
                    me._movedSprite=null;
                    temp.removeFromParent(true);
                }
            }
        });
        cc.eventManager.addListener(listener, this.layerCard1);
    },
    checkDarkCardTouch:function(ray){
        if(this.curState.state==PlayerState.XUANPAIING){
            this.checkDarkCardTouchSelect(ray);
        }
        else{
            this.checkDarkCardTouchNormal(ray);
        }
    },

    checkDarkCardTouchSelect:function(ray){
        var mjCards=this.layerCard1.getChildren();
        var selectedCards=this.getSelectedCards(true);

        for(var key=0 in mjCards){
            var boundingBox=mjCards[key].getBoundingBox();
            boundingBox.width+=1;                           //中间空的一像素
            if(cc.rectContainsPoint(boundingBox,ray)){           //cc.math.rayIntersectsObb(ray,obb)
                var posY=mjCards[key].getPositionY();
                if(posY>=ngc.game.mjpos[0][0].y+this._popGapYSelf){
                    mjCards[key].setPositionY(ngc.game.mjpos[0][0].y);
                }
                else if(this.cards[0][key]!=undefined){
                    if(selectedCards.length<=0||(Math.floor(this.cards[0][key]/9) != Math.floor(selectedCards[0]/9))){//不同花色
                        var selectedMJCards=this.getSelectedCards();
                        for(var k=0 in selectedMJCards){
                            selectedMJCards[k].setPositionY(ngc.game.mjpos[0][0].y);
                        }
                        this.popOneCard(mjCards[key]);
                    }
                    else if(selectedCards.length<3){//同花色
                        this.popOneCard(mjCards[key]);
                    }
                }
                return;
            }
        }
    },

    checkDarkCardTouchNormal:function(ray){
        var mjCards=this.layerCard1.getChildren();
        var hasPoped=false; //防止一次选中两个
        for(var key=0 in mjCards){
            var boundingBox=mjCards[key].getBoundingBox();
            boundingBox.width+=1;                           //中间空的一像素
            if(!hasPoped&&cc.rectContainsPoint(boundingBox,ray)){
                if(mjCards[key].getPositionY()<=ngc.game.mjpos[0][0].y){
                    this.popOneCard(mjCards[key]);
                    hasPoped=true;
                    this.player.layerPart2d.showHuPaiCon(this.cards[0][key],mjCards[key]);
                } else {
                    /*mjCards[key].setPositionY(ngc.game.mjpos[0][0].y);
                    hasPoped=true;*/
                    this.sendDiscardAction(key);   //出牌
                    this.player.layerPart2d.showHuPaiCon(-1);
                    break;
                }
            } else {
                if (!this.checkIsMoveing(mjCards[key]))
                    mjCards[key].setPositionY(ngc.game.mjpos[0][0].y);
            }
        }

        if (!hasPoped) {
            this.player.layerPart2d.showHuPaiCon(-1);
        }
    },

    checkDarkCardMoved:function(delta,nowPos,posInView,movedKey){
        if(this.curState.state!=PlayerState.MOPAISHOW&&this.curState.state!=PlayerState.YAPPAISHOW){
            return;
        }

        if(!this._movedSprite){
            if(movedKey<0){//第一次移动
                var ray = nowPos;//this.calculateRayByLocationInView(posInView);
                var mjCards=this.layerCard1.getChildren();
                for(var key=0 in mjCards){
                    //var child=mjCards[key].getChildren()[0];
                    //var aabb=child.getAABB();
                    //var obb = cc.math.obb(aabb);
                    var boundingBox=mjCards[key].getBoundingBox();
                    if(cc.rectContainsPoint(boundingBox,ray)){
                        this._movedKey=parseInt(key);
                        movedKey=this._movedKey;
                        break;
                    }
                }
                if(this.cards[0][movedKey]!=undefined&&mjCards[movedKey]){
                    this._movedSprite=this.generateOneMJCardIn2D(this.cards[0][movedKey]);//this.generateOneMJCard(this.cards[0][movedKey]);
                    this.addChild(this._movedSprite);
                }
            }
        }
        this._movedSprite.setPosition(nowPos);
    },

    calculateRayByLocationInView:function(location){
        var camera = cc.director.getRunningScene().getSelfCardCamera();

        var src = cc.math.vec3(location.x, location.y, 1);
        var nearPoint = camera.unproject(src);
        src = cc.math.vec3(location.x, location.y, 1000);
        var farPoint = camera.unproject(src);

        var direction = cc.math.vec3(farPoint.x - nearPoint.x, farPoint.y - nearPoint.y, farPoint.z - nearPoint.z);
        direction.normalize();
        return cc.math.ray(nearPoint, direction);
    },

    //建议定缺的花色
    getSuggestedCardType:function(){
        return CardType.WAN;
    },

    //移动到最新打出的那张牌
    movePointerToLastCard:function(){
        var children=this.layerCard4.getChildren();
        if(children.length>0){
            this.scene.movePointer(this.fitPointPos(children[children.length-1]));
            //this.scene.movePointer(children[children.length-1].getPosition3D());
        }
    },

    //将3d坐标转为2dgl坐标
    convert3dPosTo2dGLPos:function(mjCard){
        var pos=mjCard.getPosition3D();
        if(this._playerIndex==0){
            pos.z-=16;
            pos.x-=1;
        }
        else if(this._playerIndex==1){
            pos.x-=5;
            pos.z-=17;
        }
        else if(this._playerIndex==2){
            pos.z-=23;
            pos.x+=1;
        }
        else if(this._playerIndex==3){
            pos.z-=20;
            pos.x+=5;
        }

        return this.scene._camera.projectGL(pos);
    },

    fitPointPos:function(mjCard){
        var pos=mjCard.getPosition3D();
        var fitGap=21;
        pos.x+=fitGap;
        pos.y+=10;
        return pos;
    },


    /////////////手的动画（对坐标和速度）

    /**
     * 初始化手模型的属性
     */
    initHandObjPros:function(handobj,pro3d){
        if(handobj){
            handobj.setPosition3D(pro3d.pos);
            handobj.setRotation3D(pro3d.rotation);
            handobj.setScaleX(pro3d.scale.x);
            handobj.setScaleY(pro3d.scale.y);
            handobj.setScaleZ(pro3d.scale.z);
        }
    },

    showDiceHandAni:function(callBack,target){
        if(this._handObj){
            this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].dice);
            this._handObj.setVisible(true);
            var animation = new jsb.Animation3D(this._handObjRes);
            var animate = jsb.Animate3D.createWithFrames(animation,this._handAnis.dice[0],this._handAnis.dice[1],60);
            animate.setSpeed(this._handSpeed);
            var call=cc.callFunc(callBack,target);
            animate.update(0.0);
            this._handObj.runAction(cc.sequence(animate,cc.hide(),cc.delayTime(1.0),call));
        }
    },

    showPengGangHandAni:function(cardValue){
        if(this._handObj){
            this.refreshCards2();
            this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].penggang);
            var children=this.layerCard2.getChildren();
            var hideChildren=[];
            if(children.length>3){
                for(var key=0 in this.cards[1]){
                    if(this.cards[1][key]==cardValue&&children[key]){
                        children[key].setVisible(false);
                        hideChildren.push(children[key]);
                    }
                }
                if(hideChildren.length>0){
                    var child3Pos=children[2].getPosition3D();
                    var lastChildPos=hideChildren[hideChildren.length-1].getPosition3D();
                    var gap=cc.math.vec3Sub(lastChildPos,child3Pos);
                    this._handObj.setPosition3D(cc.math.vec3Add(this._handObj.getPosition3D(),gap));
                }
            }

            var animation=new jsb.Animation3D(this._handObjRes);

            var animate0 = jsb.Animate3D.createWithFrames(animation,this._handAnis.penggang1[0],this._handAnis.penggang1[0],60);
            var call0=cc.callFunc(function(){this._handObj.setVisible(true);},this);
            var animate1 = jsb.Animate3D.createWithFrames(animation,this._handAnis.penggang1[0],this._handAnis.penggang1[1],60);
            var call1=cc.callFunc(function(){
                for(var key=0 in hideChildren){
                    hideChildren[key].setVisible(true);
                }
                this.arrangementDarkCards(true,true);
            },this);
            var call2=cc.callFunc(function(){
                this.endPackDeal();
                this.endState();
            },this);

            var animate2 = jsb.Animate3D.createWithFrames(animation,this._handAnis.penggang2[0],this._handAnis.penggang2[1],60);
            var hide=cc.hide();
            animate0.setSpeed(this._handSpeed);
            animate1.setSpeed(this._handSpeed);
            animate2.setSpeed(this._handSpeed);
            this._handObj.runAction(cc.sequence(animate0,call0,animate1,call1,cc.delayTime(0.2),animate2,hide,call2));
        }
    },

    showSwapHandAni:function(){
        if(this._handObj){
            this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].swap);
            this.layerCard5.setVisible(false);
            var animation = new jsb.Animation3D(this._handObjRes);
            var animate0 = jsb.Animate3D.createWithFrames(animation,this._handAnis.swap1[0],this._handAnis.swap1[0],60);
            var call0=cc.callFunc(function(){this._handObj.setVisible(true);},this);
            var animate1 = jsb.Animate3D.createWithFrames(animation,this._handAnis.swap1[0],this._handAnis.swap1[1],60);
            var call=cc.callFunc(function(){this.layerCard5.setVisible(true)},this);
            var animate2 = jsb.Animate3D.createWithFrames(animation,this._handAnis.swap2[0],this._handAnis.swap2[1],60);
            this._handObj.runAction(cc.sequence(animate0,call0,animate1,call,call,animate2,cc.hide()));
        }
    },

    showHuPaiHandAni:function(){
        if(this._handObj){
            var children=this.layerCard3.getChildren();
            if(children.length>0){
                this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].hupai);
                var lastChild=children[children.length-1];
                lastChild.setVisible(false);
                var lastChildPos=lastChild.getPosition3D();
                var firstChildPos=children[0].getPosition3D();
                var gap=cc.math.vec3Sub(lastChildPos,firstChildPos);
                this._handObj.setPosition3D(cc.math.vec3Add(this._handObj.getPosition3D(),gap));

                var animation = new jsb.Animation3D(this._handObjRes);
                var animate0 = jsb.Animate3D.createWithFrames(animation,this._handAnis.hupai1[0],this._handAnis.hupai1[0],60);
                var call0=cc.callFunc(function(){this._handObj.setVisible(true);},this);
                var animate1 = jsb.Animate3D.createWithFrames(animation,this._handAnis.hupai1[0],this._handAnis.hupai1[1],60);
                var call=cc.callFunc(function(){
                    lastChild.setVisible(true);
                },this);
                var call2=cc.CallFunc(function(){
                    this.endPackDeal();
                    if(this._playerIndex==0)
                        this.player.layerPart2d.removeOpSelectionSelf();
                    this.endState();
                },this);
                var animate2 = jsb.Animate3D.createWithFrames(animation,this._handAnis.hupai2[0],this._handAnis.hupai2[1],60);
                this._handObj.runAction(cc.sequence(animate0,call0,animate1,call,animate2,cc.hide(),call2));
                animate1.setSpeed(this._handSpeed);
                animate2.setSpeed(this._handSpeed);
                animate1.setQuality(2);
                animate2.setQuality(2);
            }
        }
    },

    showDicardHandAni:function(){
        if(this._handObj) {
            var children = this.layerCard4.getChildren();
            if (children.length > 0) {
                this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].discard);
                var lastChild=children[children.length-1];
                lastChild.setVisible(false);
                var lastChildPos=lastChild.getPosition3D();
                var firstChildPos=children[0].getPosition3D();
                var gap=cc.math.vec3Sub(lastChildPos,firstChildPos);
                this._handObj.setPosition3D(cc.math.vec3Add(this._handObj.getPosition3D(),gap));

                var animation = new jsb.Animation3D(this._handObjRes);
                var animate0 = jsb.Animate3D.createWithFrames(animation,this._handAnis.discard1[0],this._handAnis.discard1[0],60);
                var call0=cc.callFunc(function(){this._handObj.setVisible(true);},this);
                var animate1 = jsb.Animate3D.createWithFrames(animation,this._handAnis.discard1[0],this._handAnis.discard1[1],60);
                animate1.setSpeed(this._handSpeed);
                var call=cc.callFunc(function(){
                    lastChild.setVisible(true);
                    this.scene.movePointer(this.fitPointPos(lastChild));
                    //this.scene.movePointer(lastChild.getPosition3D());
                    this.playSound();
                    this.endPackDeal();
                    //显示刚出的牌标识
                    //var children=this.layerCard4.getChildren();
                    //if(children.length>0){
                    //    this.scene.movePointer(this.convert3dPosTo2dGLPos(children[children.length-1]));
                    //}
                },this);
                var animate2 = jsb.Animate3D.createWithFrames(animation,this._handAnis.discard2[0],this._handAnis.discard2[1],60);
                animate2.setSpeed(this._handSpeed);
                this._handObj.runAction(cc.sequence(animate0,call0,animate1,call,cc.delayTime(0.1),animate2,cc.hide()));
            }
        }
    },

    showArrangeCardHandAni:function(){
        var children=this.layerCard1.getChildren();
        if(children.length>=2){
            var pos1=children[children.length-2].getPosition3D();
            var pos2=children[children.length-1].getPosition3D();
        }
        else {
            var pos1=cc.math.vec3(0,0,0);
            var pos2=cc.math.vec3(0,0,0);
        }
        var gapPos=cc.math.vec3Sub(pos2,pos1);
        var compareNum=this._playerIndex==0?this._mjWidthSelf:ngc.game.mjModelWidth;
        if(Math.abs(gapPos.x)<=compareNum&&Math.abs(gapPos.y)<=compareNum&&Math.abs(gapPos.z)<=compareNum){//不需要移动
            this.arrangementDarkCards(undefined,true);
            this.endState();
            return;
        }

        if(children.length<2||!this._handObj||this._playerIndex==0){
            this.moveNewCardAni();
            return;
        }


        var children = this.layerCard1.getChildren();
        if (children.length > 0) {
            this.initHandObjPros(this._handObj,this._handAniPros[this._playerIndex].arrangecard);
            if(this._playerIndex%2==0){
                var gap=cc.math.vec3(this._playerIndex==0?this._mjWidthSelf:-ngc.game.mjModelWidth,0,0);
                gap=cc.math.vec3Ride(gap,13);
                gap.x+=this._playerIndex==0?5:-5;           //抓牌时闪出的空隙
            }
            else{
                var gap=cc.math.vec3(0,0,this._playerIndex==1?ngc.game.mjModelWidth:-ngc.game.mjModelWidth);
                gap=cc.math.vec3Ride(gap,13);
                gap.z+=this._playerIndex==1?5:-5;           //抓牌时闪出的空隙
            }
            var standardPos=cc.math.vec3Add(ngc.game.mjpos[this._playerIndex][MJCardClass.SHOU],gap);

            var lastChild=children[children.length-1];
            var lastChildPos=lastChild.getPosition3D();
            gap=cc.math.vec3Sub(lastChildPos,standardPos);

            this._handObj.setPosition3D(cc.math.vec3Add(this._handObj.getPosition3D(),gap));

            var animation = new jsb.Animation3D(this._handObjRes);
            var animate0 = jsb.Animate3D.createWithFrames(animation,this._handAnis.arrangecard1[0],this._handAnis.arrangecard1[0],60);
            var call0=cc.callFunc(function(){this._handObj.setVisible(true);},this);
            var animate1 = jsb.Animate3D.createWithFrames(animation,this._handAnis.arrangecard1[0],this._handAnis.arrangecard1[1],60);
            var call=cc.callFunc(function(){
                this.moveNewCardAni();
            },this);
            this._handObj.runAction(cc.sequence(animate0,call0,animate1,call));
        }
    },

    playSound:function() {
        var cards=this.cards[3];
        var num = cards[cards.length-1];
        var _file = (this.player.userInfo.sex == 1) ? "pt_n_" : "pt_nv_";
        _file += num;
        if (ngc.hall.musicGame[_file]) {
            //cc.audioEngine.playEffect(ngc.hall.musicGame[_file], false);
            if(ngc.flag.SOUND_FLAG)
                ngc.g_mainScene.getAudio().playGameSound(ngc.hall.musicGame[_file]);
        } else {
            ngc.log.info("Error : file is not found file = " + _file);
        }
    },


    ////////////////////////////////

    clearCards:function(){
        this.toStates=[];
        this.dealingState=false;
        //this.curState.state=PlayerState.NONE;

        this.initCards();

        this._handObj.setVisible(false);

        this.layerCard1.removeAllChildren();
        this.layerCard2.removeAllChildren();
        this.layerCard3.removeAllChildren();
        this.layerCard4.removeAllChildren();
        this.layerCard5.removeAllChildren();

        // 清空数据
        this.cards[0].splice(0, this.cards[0].length);
        this.cards[1].splice(0, this.cards[1].length);
        this.cards[2].splice(0, this.cards[2].length);
        this.cards[3].splice(0, this.cards[3].length);
        this.cards[4].splice(0, this.cards[4].length);


    }
});