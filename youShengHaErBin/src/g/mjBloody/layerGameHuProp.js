ngc.game.hupaiprompt=ngc.CLayerBase.extend({
    _imgCon:null,
    _tingData:null,
    _directorLayer:null,

    _cardImg:null,
    _fanLable:null,
    _numLabel:null,

    ctor:function(){
        this._super();
        var layer=new cc.Layer();
        this.addChild(layer);
        this._directorLayer=layer;
    },
    myInit:function(){
        this._super(ngc.game.jsonRes.layerPrompt);
        this.mySetVisibleTrue();

        this._imgCon.setVisible(false);
    },
    setData:function(data){
        this._tingData=data;
    },
    //显示箭头
    showDirector:function(cards,children3D,sence){
        if(this._tingData){
            this.setVisible(true);
            this._imgCon.setVisible(false);
            this._directorLayer.removeAllChildren();
            this._directorLayer.setVisible(true);
            for(var key=0 in cards){
                if(this._tingData[cards[key]]){//打出后可以胡牌
                    var sprite=new cc.Sprite(ngc.game.pngRes.huDirector);
                    sprite.setAnchorPoint(0.5,0);
                    var glPos=this.convertSelfCard3dPosTo2dGLPos(children3D[key].getPosition3D(),sence);
                    sprite.setPosition(glPos);
                    this._directorLayer.addChild(sprite);
                }
            }
        }
    },
    //检查是否有胡牌
    hasHuPai:function(){
        if(this._tingData!=null&&this._directorLayer.isVisible()){
            return true;
        }
        return false;
    },
    //显示胡的牌
    showHuPai:function(cardValue,mjCard,sence){
        this._imgCon.setVisible(false);
        if(this._tingData){
            this.setVisible(true);
            var children=this._imgCon.getChildren();
            for(var key=0 in children){
                if(parseInt(key)>0){
                    children[key].removeFromParent(true);
                }
            }
            var nowSize =cc.size(100,180);
            this._imgCon.setContentSize(nowSize);
            if(this._tingData[cardValue]){
                for(var key=0 in this._tingData[cardValue]){
                    this._imgCon.setVisible(true);
                    var one=this._tingData[cardValue][key];
                    var loadInfo = ngc.uiUtils.loadJson(this, ngc.game.jsonRes.layerPromptPart);
                    this._cardImg.loadTexture(getCardLocalResByValue(one["hu"]),ccui.Widget.LOCAL_TEXTURE);
                    this._fanLable.setString(one["fan"]);
                    this._numLabel.setString(one["lnum"]);
                    if(parseInt(one["lnum"])<=0)
                        this._cardImg.setColor(cc.color(30,30,30));

                    var gap=20;
                    var children=this._imgCon.getChildren();
                    var lastChild=children[children.length-1];
                    var posx=lastChild.getPositionX()+lastChild.getContentSize().width+gap;
                    var posy=lastChild.getPositionY();
                    loadInfo.node.setAnchorPoint(0,0.5);
                    loadInfo.node.ignoreAnchorPointForPosition(false);
                    loadInfo.node.setPosition(posx,posy);
                    this._imgCon.addChild(loadInfo.node);

                    nowSize=this._imgCon.getContentSize();
                    nowSize.width+=loadInfo.node.getContentSize().width+gap;
                    this._imgCon.setContentSize(nowSize);
                }
            }
            if(mjCard&&sence){
                var glPos=this.convertSelfCard3dPosTo2dGLPos(mjCard.getPosition3D(),sence);
                if(glPos.x-nowSize.width/2<20)
                    glPos.x=nowSize.width/2+20;
                if(glPos.x+nowSize.width/2>cc.winSize.width-20)
                    glPos.x=cc.winSize.width-20-nowSize.width/2;
                glPos.y+=140;
                this._imgCon.setPosition(glPos);
            }
        }
    },
    repositionAndEvent:function(){
        this._imgCon.setPosition(cc.p(cc.winSize.width-this._imgCon.getContentSize().width/2-80,290));

        var me=this;
        var listener = cc.EventListener.create({
            event: cc.EventListener.TOUCH_ONE_BY_ONE,
            swallowTouches: false,
            onTouchBegan: function (touch, event) {
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
                    if(!cc.rectContainsPoint(me._imgCon.getBoundingBoxToWorld(),location)){
                        me.removeFromParent(true);
                    }
                }
            }
        });
        cc.eventManager.addListener(listener, this);
    },
    //将3d坐标转为2dgl坐标
    convertSelfCard3dPosTo2dGLPos:function(pos,sence){
        var retPos=sence.getSelfCardCamera().projectGL(pos);
        retPos.y+=40;
        return retPos;
    },
    clearInfo:function(){
        this._tingData=null;
        this._directorLayer.removeAllChildren();
        var children=this._imgCon.getChildren();
        for(var key=0 in children){
            if(parseInt(key)>0){
                children[key].removeFromParent(true);
            }
        }
    }
});