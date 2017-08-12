/**
 * Created by Dongenlai on 2016/9/20.
 * 聊天 外侧对话框
 */


ngc.game.layer.chatNode = ngc.CNodeBase.extend({
    _jsonStr:null,
    _delay:null,
    _msgText:null, //对话内容

    _chatNode:null,
    _chatText:null, //聊天内容

    ctor:function(delay, msgText){
     this._super();
     this._delay = delay;
     this._msgText = msgText;
    },

    setJsonStr:function(jsonStr){
        this.myInit(jsonStr);
    },

    myInit:function(jsonStr){
        this._super(jsonStr, true);
        this.mySetVisibleTrue();
        this.animationFunc();
    },
    
    animationFunc:function(){
        this._chatText.setString(this._msgText);
        var width = this._chatText.getContentSize().width;
        var Twidth = width + 20;
        if(width < 58){
            Twidth = width + 62;
        }
        this._chatNode.setScale(2.0);
        this._chatNode.setSize(cc.size(Twidth, this._chatNode.getSize().height));
        if(width < 58){
            this._chatText.setPosition(Twidth/2 - 15, this._chatNode.getSize().height - 30);
        }
        this.runAction(cc.sequence(cc.delayTime(2), cc.CallFunc(function(target){
            target.removeFromParent(true);
        })));
    },


});