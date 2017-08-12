ngc.game.opswap=ngc.CLayerBase.extend({
    myInit:function(){
        this._super(ngc.game.jsonRes.layerOPSwap);
        this.mySetVisibleTrue();
    },
    onSelectOk:function(){
        var scene=cc.director.getRunningScene();
        var self = scene.getPlayerByCIndex(0);
        var selectedCards=self.getSelectedCards(true);
        if(selectedCards.length==3){
            var data={
                op:opSelfAction.mjSwap,
                cards:selectedCards,
            };
            cc.eventManager.dispatchCustomEvent(OPEventName,data);
            this.removeFromParent(true);
        }
    }
});

ngc.game.oplack=ngc.CGameLayerBase.extend({
    _ani1:null,
    _ani2:null,
    _ani3:null,
    myInit:function(suggestedCardType){
        this._super(ngc.game.jsonRes.layerOPLack);
        this.mySetVisibleTrue();

        if(suggestedCardType!=undefined){
            if(suggestedCardType==CardType.WAN)
                this._ani1.setVisible(true);
            else if(suggestedCardType==CardType.TIAO)
                this._ani2.setVisible(true);
            else
                this._ani3.setVisible(true);
        }
        else{
            this._ani1.setVisible(true);
        }
    },
    onEnter:function(){
        this._super();
        if(this._timeLine)
            this._timeLine.play("animation0",true);
    },
    onWanClick:function(){
        this.sendOp(CardType.WAN);
    },
    onTiaoClick:function(){
        this.sendOp(CardType.TIAO);
    },
    onTongClick:function(){
        this.sendOp(CardType.TONG);
    },
    sendOp:function(cardType){
        var data={
            op:opSelfAction.mjLack,
            lack:cardType
        };
        cc.eventManager.dispatchCustomEvent(OPEventName,data);
    }
});

ngc.game.opaction=ngc.CLayerBase.extend({
    _img0:null,
    _img1:null,
    _img2:null,
    _img3:null,
    _img4:null,
    _img5:null,
    _img6:null,
    _img7:null,
    _aniBg:null,
    _chiArray : null,
    _gangType: opServerActionCodes.mjaDaMingGang,
    _gangArray: null,
    delegate:null,

    myInit:function(actions){
        this._super(ngc.game.jsonRes.layerActions);
        this.mySetVisibleTrue();
        this._gangArray=[];
        this._chiArray = [];
        this._chiArray.length = 0;
        var hasAction = false;
        ngc.log.info("actions = " +JSON.stringify(actions));
        for(var key=0 in actions){
            switch (actions[key]["a"]){
                case opServerActionCodes.mjaSpecialGang:
                    //this._img0.setVisible(true);
                    //hasAction = true;
                    this._img3.specialGangState = true;
                    this._img3.setVisible(true);
                    this._gangArray.push(actions[key]);
                    hasAction=true;
                    break;
                case opServerActionCodes.mjaTing:
                    this._img0.setVisible(true);
                    this._img0.optionE = actions;
                    hasAction = true;
                    break;
                case opServerActionCodes.mjaTingGang:
                    //this._img0.setVisible(true);
                    //this._img0.optionE = actions;
                    this._img3.setVisible(true);
                    this._chiArray.push(actions[key]);
                    hasAction = true;
                    break;
                case opServerActionCodes.mjaTingChi:
                    this._img6.setVisible(true);
                    this._img6.optionE = actions;
                    this._chiArray.push(actions[key]);
                    hasAction = true;
                    break;
                case opServerActionCodes.mjaTingPeng:
                    this._img7.setVisible(true);
                    this._img7.optionE = actions;
                    hasAction = true;
                    break;
                case opServerActionCodes.mjaChi:
                    this._img1.setVisible(true);
                    this._chiArray.push(actions[key]);
                    hasAction=true;
                    break;
                case opServerActionCodes.mjaPeng:
                    this._img2.setVisible(true);
                    this._img2.optionE=actions[key]["e"];
                    hasAction=true;
                    break;
                case opServerActionCodes.mjaJiaGang:
                case opServerActionCodes.mjaDaMingGang:
                case opServerActionCodes.mjaAnGang:
                    this._img3.setVisible(true);
                    this._gangArray.push(actions[key]);
                    hasAction=true;
                    break;
                case opServerActionCodes.mjaHu:
                    this._img4.setVisible(true);
                    this._img4.optionE=actions[key]["e"];
                    hasAction=true;
                    break;
                default:
                    this.removeFromParent();
                    break;
            }
        }
        if(!hasAction) return false;

        try{
        ngc.log.info("start sort pos");
        for(var i = 7,j=0; i >= 0; i--){
            var obj=eval("this._img" + i);
            if(obj.isVisible() && obj!=this._img5){
                obj.x =this._img5.x - (170 * (++j));
                this.playCircleAnimation(i);
            }
        }
            ngc.log.info("end sort pos");
        }catch(e){
            ngc.log.info(e);
        }
        return true;
    },

    playCircleAnimation:function(tag){
        var aniBg = eval("this._aniBg" + tag);
        if(aniBg){
            aniBg.runAction(cc.rotateBy(1, 360).repeatForever());
        }
    },

    onEnter:function(){
        this._super();
        if(this._timeLine)
            this._timeLine.play("animation0",true);
    },

    //亮杠
    onLiangClick: function() {
        var _gangLayer = new ngc.game.layer.GangLayer();
        var scene = cc.director.getRunningScene();
        scene.addChild(_gangLayer, 100);
    },

    //胡
    onWinTouch:function(sender){
        this.sendOp(opServerActionCodes.mjaHu,sender.optionE);
    },

    setDelegate:function(obj){
        this.delegate = obj;
    },


    onTingTouch:function(sender){
        var actionKeyEs = sender.optionE;
        var part3D = this.delegate.player.layerPart3d;
        if(part3D){
            part3D.showTpAction(actionKeyEs,1);
        }
        //sender.setVisible(false);
        //点击听牌的时候是可以点击过的
        this.removeFromParent();
    },

    //杠
    onBarTouch:function(sender){
        //如果是花杠或者 中华白杠的时候
        if(sender.specialGangState){
            this.removeChildByTag(1123);
            var layer = new ngc.game.opselectSpecialGang();
            layer.myInit(this._gangArray);
            this.addChild(layer, 0, 1123);

            return;
        }
        if(this._gangArray.length<=1){
            ngc.log.info("------------------" + JSON.stringify(this._gangArray))
            this.sendOp(this._gangArray[0]["a"],this._gangArray[0]["e"]);
        } else {   //多个杠
            this.removeChildByTag(1111);
            var layer=new ngc.game.opselectgang();
            layer.myInit(this._gangArray);
            this.addChild(layer,0,1111);
        }
    },

    //碰
    onCollideTouch:function(sender){
        this.sendOp(opServerActionCodes.mjaPeng,sender.optionE);
    },

    //听碰
    onTingPengTouch:function(sender){
        var actionKeyEs = sender.optionE;
        var part3D = this.delegate.player.layerPart3d;
        if(part3D){
            part3D.showTpChiPengAction(actionKeyEs,3);
        }
        this.delegate.player.layerPart3d.curState.state =PlayerState.YAPPAISHOW;
        //player.setState(new PlayerStateData(PlayerState.YAPPAISHOW,actionKeyEs));
        //this.sendOp(opServerActionCodes.mjaTingPeng,sender.optionE);
        this.removeFromParent();
    },

    //吃
    onEatTouch:function(){
        if (this._chiArray.length <= 1) {
            this.sendOp( this._chiArray[0]["a"], this._chiArray[0]["e"]);
        } else {
            this.removeChildByTag(2222);
            var layer = new ngc.game.opselectchi();
            layer.myInit(this._chiArray);
            this.addChild(layer, 0, 2222);
        }
    },

    //听吃
    onTingChiTouch:function(sender){
        var actionKeyEs = sender.optionE;
        var part3D = this.delegate.player.layerPart3d;
        if(part3D){
            part3D.showTpChiPengAction(actionKeyEs,2);
        }
        this.delegate.player.layerPart3d.curState.state =PlayerState.YAPPAISHOW;
        this.removeFromParent();
        //if (this._chiArray.length <= 1) {
        //    this.sendOp( this._chiArray[0]["a"], this._chiArray[0]["e"]);
        //} else {
        //    this.removeChildByTag(2222);
        //    var layer = new ngc.game.opselectchi();
        //    layer.myInit(this._chiArray);
        //    this.addChild(layer, 0, 2222);
        //}
    },

    //过
    onPassTouch:function(){
        if(this._img3.isVisible()&&this._gangArray.length>0&&this.delegate.player.layerPart3d.scene.getPlayerByCIndex(0).getTingState() > 0){//已经听牌
            for(var i in this._gangArray){
                var item = this._gangArray[i];
                if(item["a"] == opServerActionCodes.mjaAnGang){
                    var data={
                        op:opSelfAction.mjDiscard,
                        cardId:parseInt(item["e"]),
                        forceDisCard:true
                    };
                    ngc.log.info("data =" + JSON.stringify(data));
                    cc.eventManager.dispatchCustomEvent(OPEventName,data);
                    return;
                }
            }
            this.sendOp(opServerActionCodes.mjaPass);
        }else{
            this.sendOp(opServerActionCodes.mjaPass);
        }
    },

    sendOp:function(actionCode,optionE){
        var data={
            op:opSelfAction.mjTakeCard,
            code:actionCode,
            eStr:optionE
        };
        cc.eventManager.dispatchCustomEvent(OPEventName, data);
        this.removeFromParent(true);
        ngc.log.info("-------------111------ " + JSON.stringify(data));
    }
});

ngc.game.opcanceltrust=ngc.CLayerBase.extend({
    myInit:function(){
        this._super(ngc.game.jsonRes.layerOPCancelTrust,false);
        this.mySetVisibleTrue();
    },
    onCancelTrust:function(){
        var data={
            op:opSelfAction.mjCancelTrust,
        };
        cc.eventManager.dispatchCustomEvent(OPEventName,data);
    }
});

ngc.game.opselectchi = ngc.CLayerBase.extend({
    _selCardBtn1:null,
    _selCardBtn2:null,
    _selCardBtn3:null,

    _Panel_1:null,
    _Panel_2:null,
    _Panel_3:null,

    _selCardBtn:null,
    _chiActions:null,
    _tagIndex:0,

    ctor:function(){
        this._super();
        this._selCardBtn=[];
    },

    myInit:function(chiActions){
        this._selCardBtn1 = [];
        this._selCardBtn2 = [];
        this._selCardBtn3 = [];
        this._tagIndex  = 0;
        this._super(ngc.game.jsonRes.layerOPSelectChi, false);
        this.mySetVisibleTrue();
        this._chiActions = chiActions;
        var length = chiActions.length;
        var panelBg = eval("this._Panel_" + length);
        panelBg.setVisible(true);
        panelBg.setLocalZOrder(5);
        this._selCardBtn = eval("this._selCardBtn" + length) ;

        for(var i = 0, length = chiActions.length; i < length; ++i){
            var eArry = chiActions[i]["e"].split(",");
            var mjCards = this.getChiPais(parseInt(eArry[0]),  parseInt(eArry[1]));
            for(var k = 0, lengths = mjCards.length ; k < lengths; ++k){
                if(this._selCardBtn[this._tagIndex]){
                    var conSize = this._selCardBtn[this._tagIndex].getContentSize();
                    var cardSrpite = this.generateOneMJCardIn2D( parseInt(mjCards[k])  );
                    cardSrpite.setPosition(cc.p(conSize.width/2, conSize.height/2 - 4));
                    cardSrpite.setScale(0.8);
                    this._selCardBtn[this._tagIndex].addChild(cardSrpite);
                    this._selCardBtn[this._tagIndex].actionCode  = this._chiActions[i]["a"];
                    this._selCardBtn[this._tagIndex].optionE = this._chiActions[i]["e"];
                    this._tagIndex ++;
                }
            }
        }
    },
    /*
     获取吃牌的列表
     cardValue  牌值
     order 的含义，再说一下， 如果吃  5万， order==0表示 567万， order==1表示456万， order==2表示345万
     */
    getChiPais:function(cardValue, order){
        var cardValue_1 = null;
        var cardValue_2 = null;

        if(order === 0){
            cardValue_1 = cardValue + 1;
            cardValue_2 = cardValue + 2;
            return [cardValue, cardValue_1, cardValue_2];
        }else if(order === 1){
            cardValue_1 = cardValue - 1;
            cardValue_2 = cardValue + 1;
            return [cardValue_1, cardValue, cardValue_2];
        }else if(order === 2){
            cardValue_1 = cardValue - 2;
            cardValue_2 = cardValue - 1;
            return [cardValue_1, cardValue_2, cardValue];
        }

        return "";
    },

    generateOneMJCardIn2D:function(cardValue){
        if(cardValue >= 0){
            var sprite = new cc.Sprite(getCardLocalResByValue(cardValue));
            return sprite;
        }
        else{
            return new cc.Sprite();
        }
    },

    onCardSelected:function(sender){
        var tag = sender.getTag();
        var cardBtn = this._selCardBtn[tag];
        this.sendOp(cardBtn.actionCode, cardBtn.optionE);
        this.removeFromParent(true);
    },

    sendOp:function(actionCode, optionE){
        var data = {
            op:opSelfAction.mjTakeCard,
            code:actionCode,
            eStr:optionE
        };
        ngc.log.info("-------多吃-----" + JSON.stringify(data));
        cc.eventManager.dispatchCustomEvent(OPEventName, data);
    }
});

ngc.game.opselectSpecialGang = ngc.CLayerBase.extend({
    _listView:null,
    _selCardBtn:null,
    _gangActions:null,
    ctor:function(){
        this._super();
        this._listView = null;
        this._selCardBtn = null;
    },

    myInit:function(gangActions){
        this._super(ngc.game.jsonRes.layerOPSelectSpecialGang,false);
        this.mySetVisibleTrue();
        this._gangActions = gangActions;

        for(var i = 0 in gangActions){
            var gangCardAry = gangActions[i]["e"].split(",");
            for(var k = 0, length = gangCardAry.length; k < length;　++k){
                var _selCardBtn = this._selCardBtn.clone();
                _selCardBtn.action =gangActions[i]["a"];
                _selCardBtn.eStr =  gangActions[i]["e"];
                this._listView.pushBackCustomItem(_selCardBtn);
                if(_selCardBtn)
                  _selCardBtn.addTouchEventListener(this.onCardSelected, this);
                var cardSrpite = this.generateOneMJCardIn2D( parseInt(gangCardAry[k] ), _selCardBtn.getContentSize());
                _selCardBtn.addChild(cardSrpite);
            }

            var lockImg = ccui.ImageView("res/g/mjBloody/ui/mjbg.png", ccui.Widget.LOCAL_TEXTURE);
            lockImg.setPosition(60, 78);
            lockImg.setVisible(false);
            this._listView.pushBackCustomItem(lockImg);

        }
    },

    generateOneMJCardIn2D:function(cardValue,conSize){
        if(cardValue>=0){
            var sprite=new cc.Sprite(getCardLocalResByValue(cardValue));
            sprite.setPosition(cc.p(conSize.width/2,conSize.height/2-4));
            sprite.setScale(0.8)
            return sprite;
        }
        else{
            return new cc.Sprite();
        }
    },

    onCardSelected:function(sender, type){
        if(type != 2) return;
        var action = sender.action;
        var eStr = sender.eStr;
        this.sendOp(action, eStr);
        this.removeFromParent(true);
    },

    sendOp:function(actionCode,optionE){
        var data={
            op:opSelfAction.mjTakeCard,
            code:actionCode,
            eStr:optionE
        };
        cc.eventManager.dispatchCustomEvent(OPEventName, data);
    }
})


ngc.game.opselectgang=ngc.CLayerBase.extend({
    _selCardBtn:[],
    _gangActions:null,
    ctor:function(){
        this._super();
        this._selCardBtn=[];
    },
    myInit:function(gangActions){
        this._super(ngc.game.jsonRes.layerOPSelectGang,false);
        this.mySetVisibleTrue();

        this._gangActions=gangActions;

        for(var i=0;i<gangActions.length;i++){
            if(this._selCardBtn[i]){
                this._selCardBtn[i].setVisible(true);
                var cardSrpite=this.generateOneMJCardIn2D(gangActions[i]["e"],this._selCardBtn[i].getContentSize());
                this._selCardBtn[i].addChild(cardSrpite);
            }
        }

        var gap=-35*(gangActions.length-2);
        for(var i=0;i<this._selCardBtn.length;i++){
            if(this._selCardBtn[i]){
                this._selCardBtn[i].setPositionX(this._selCardBtn[i].getPositionX()+gap);
            }
        }

    },
    generateOneMJCardIn2D:function(cardValue,conSize){
        if(cardValue>=0){
            var sprite=new cc.Sprite(getCardLocalResByValue(cardValue));
            sprite.setPosition(cc.p(conSize.width/2,conSize.height/2-4));
            sprite.setScale(0.8)
            return sprite;
        }
        else{
            return new cc.Sprite();
        }
    },
    onCardSelected:function(sender){
        for(var i=0;i<this._selCardBtn.length;i++){
            if(sender==this._selCardBtn[i]&&this._gangActions[i]){
                this.sendOp(this._gangActions[i]["a"],this._gangActions[i]["e"]);
                break;
            }
        }
        this.removeFromParent(true);
    },
    sendOp:function(actionCode,optionE){
        var data={
            op:opSelfAction.mjTakeCard,
            code:actionCode,
            eStr:optionE
        };
        cc.eventManager.dispatchCustomEvent(OPEventName, data);
    }
})