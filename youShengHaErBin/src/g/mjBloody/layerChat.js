ngc.game.layer.chat = ngc.CLayerBase.extend({
    _layerGame: null,
    _text: null,

    _BqBtn:null,     //表情按钮
    _ChatBtn:null,   //聊天按钮
    _expressBtn:[],   //表情按钮集合

    _parentPanel:null,
    _Panel_1:null,
    _Panel_2:null,
    _pleaseInput:null,
    _listenerShield:null,

    ctor:function(){
        this._super();
        this._expressBtn = [];
        cc.spriteFrameCache.addSpriteFrames("res/g/mjBloody/chat/Expression.plist");
        this.myInit();
    },

    onEnter:function(){
        this._super();
        var that = this;
        this._listenerShield = cc.EventListener.create({
            event: cc.EventListener.TOUCH_ONE_BY_ONE,
            swallowTouches:false,
            onTouchBegan: function (touch, event) {
                var pos = touch.getLocation();
                that.callBack(pos);
                return true;
            }
        });

        cc.eventManager.addListener(this._listenerShield, this);
    },

    callBack:function(pos){
        var r = cc.rect(0, 0, this._parentPanel.width, this._parentPanel.height);
        var pos =  this._parentPanel.convertToNodeSpace(pos);
        if (!cc.rectContainsPoint(r, pos)){
            this.closeMyself();
        }
    },

    myInit: function () {
        this._super(ngc.game.jsonRes.g_mjBloody_Chat);
        this.mySetVisibleTrue(true);
        //起始默认是选择表情界面
        this.addExpressionImage();
        this._BqBtn.loadTexture("res/g/mjBloody/chat/a3.png");
        this._BqBtn.setBrightStyle(1);
        this._BqBtn.setTouchEnabled(false);
        this._Panel_2.setVisible(false);

    },

    //添加表情图片 表情动画缓存
    addExpressionImage:function(){
      var animation = new cc.Animation();
      var expressBtnAry = this._expressBtn;
        for(var k = 0, length = 20 ; k < length;  ++k) {
          var menuObj = expressBtnAry[k];
          var expressImage = this.sprintfMot("exp%02d_01.png", (k+1));
          var sp = new cc.Sprite('#' + expressImage);
          sp.setScale(0.4);
          sp.setPosition(menuObj._getWidth()/2, menuObj._getHeight()/2);
          menuObj.addChild(sp);
          var frameName = expressImage.substr(0, expressImage.length );
          var subStr = frameName.substr(0, expressImage.length - 6);
          var animation = this.asygAnimationFun(subStr + "%02d.png", 0, 5, 1/11, false);
          if(animation){
              cc.animationCache.addAnimation(animation, "chatEmotion_" + k);
          }
                                            
                                            
      }
      animation.setDelayPerUnit(1/20);
      animation.setRestoreOriginalFrame(false);
    },

    sprintfMot:function() {
        var as = [].slice.call(arguments), fmt = as.shift(), i = 0;
        return fmt.replace(/%(\w)?(\d)?([dfsx])/ig, function (_, a, b, c) {
            var s = b ? new Array(b - 0 + 1).join(a || '') : '';
            if (c == 'd') s += parseInt(as[i++]);
            return b ? s.slice(b * -1) : s;
        })
    },

    //缓存动画
    asygAnimationFun:function(str, beginIndex, endIndex, delayUnit, state){
        var animation = new cc.Animation();
        for (var i = beginIndex; i <= endIndex; i++) {
            var frameName = this.sprintfMot(str, i) ||null;
            var spriteFrame = cc.spriteFrameCache.getSpriteFrame(frameName);
            if(spriteFrame){
                animation.addSpriteFrame(spriteFrame);
            }else{
                var texture = cc.textureCache.getTextureForKey(frameName);
                if(texture){
                    var rect = cc.rect(0, 0, texture.getContentSize().width, texture.getContentSize().height);
                    var spriteFrame = cc.SpriteFrame.create(texture, rect);
                    cc.spriteFrameCache.addSpriteFrame(spriteFrame, frameName);
                    animation.addSpriteFrame(spriteFrame);
                }
            }
        }
        animation.setDelayPerUnit(delayUnit);
        animation.setRestoreOriginalFrame(state);

        return animation;
    },

    showExpressPanel:function(sender, type){
        this.hideTextExpPanel();
        this._Panel_1.setVisible(true);
        this._BqBtn.setBrightStyle(1);
        this._BqBtn.setTouchEnabled(false);
        this._ChatBtn.setTouchEnabled(true);
        this._BqBtn.loadTexture("res/g/mjBloody/chat/a3.png");
        this._ChatBtn.loadTexture("res/g/mjBloody/chat/a4.png");
    },

    hideExpressPanel:function(){
        this._Panel_1.setVisible(false);
    },

    showTextExpPanel:function(sender, type){
        this.hideExpressPanel();
        this._Panel_2.setVisible(true);
        this._BqBtn.setTouchEnabled(true);
        this._ChatBtn.setBrightStyle(1);
        this._ChatBtn.setTouchEnabled(false);
        this._ChatBtn.loadTexture("res/g/mjBloody/chat/a3.png");
        this._BqBtn.loadTexture("res/g/mjBloody/chat/a4.png");
    },

    hideTextExpPanel:function(){
        this._Panel_2.setVisible(false);
    },

    onBtnSendClick: function (sender) {
        if (this._text && this._text.getString() != null && this._text.getString() != "") {
            ngc.g_mainScene.net.sendPackChat(game_chat_type.text,  this._text.getString());
            this.closeMyself(sender);
        }
    },

    onBtnTextClick: function (sender) {
        var tag = sender.getTag();
        ngc.log.info("tag = " + tag);
        if(tag < 6){
           ngc.g_mainScene.net.sendPackChat(game_chat_type.fixedSound, tag);
        }
        this.closeMyself(sender);
    },

    onBtnFaceClick: function (sender) {
        var tag = sender.getTag();
        if(parseInt(tag) < 20){
            ngc.g_mainScene.net.sendPackChat(game_chat_type.emotion, tag);
        }
        this.closeMyself(sender);
    },

    closeMyself:function(){
      cc.eventManager.removeListener(this._listenerShield);
      this.removeFromParent(true);
      ngc.g_mainScene.table2d.chatLayer = null;
    },

});