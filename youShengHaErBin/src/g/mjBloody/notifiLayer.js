/**
 * Created by Dongenlai on 2016/9/18.
 * 滚动条
 */

var myData ={
    _target:null,
    setTarget:function(target){
        this._target = target
    },

    getTarget:function(){
        return this._target;
    },

    clrearData:function(){
        this._target = null;
    }
};

ngc.game.layer.notifiLayer = ngc.CLayerBase.extend({
    _jsonData : null,
    _jsonDataLenth : null,
    _roomId : null,
    _jsonText : null,


    _showText : null,
    _showBG : null,
    _myPos : null,

    myInit : function(romId){
        this._super(ngc.game.jsonRes.layerGongGao, true);
        this.mySetVisible(true);
        var size = cc.winSize;
        this._showBG.setPosition(cc.p(0, size.height/2));
        this._myPos = this._showText.getPosition();
        this._roomId = romId;
        myData.setTarget(this);
        ngc.http.httpGet(ngc.cfg.urlHs+"/interface/base_getnotifcation.do?gameRoomId="+romId, this.initJsonText);
    },

    initJsonText : function(ar1,ar2,ar3){
        var json = JSON.parse(ar3);
        var self = myData.getTarget();
        self._jsonData = json;
        var roomIdStr = self._roomId.toString();
        var num1 =  parseInt(json[roomIdStr+"time"].match(/\d{2}/));
        var num2 =  parseInt(json[roomIdStr+"time"].match(/\d{2}$/));
        var jsonTime = 3// (num1+num2)/2;
        self.schedule(self.reflashJsonText, jsonTime);
    },

    reflashJsonText : function(){
        if(!this._jsonDataLenth) {
            var length = 0;
            for (var key in this._jsonData) {
                length++;
            }
            this._jsonDataLenth = length-2;
        }
        var numss = Math.floor(Math.random()*this._jsonDataLenth+1);
        var num = null;
        if(numss < 10)
            num = this._roomId+"000"+numss;
        else if(numss>=10 && numss <100)
            num = this._roomId+"00"+numss;
        else
            num = this._roomId+"0"+numss;
        this._jsonText = this._jsonData[num.toString()];
        this.startSliderShowText();
    },

    startSliderShowText : function(){
        var self = this;
        this.setLayerVisible(true);
        var action = cc.moveBy(5, -1334, 0);
        if(this._jsonText)
            this._showText.setString(this._jsonText);
        else {
            this._showBG.setVisible(false);
            return;
        }

        this._showText.runAction(cc.sequence(action,cc.callFunc(function(){
            self.setLayerVisible(false);
            self.reSetPos();
        })));
    },

    setLayerVisible : function(bool){
        this._showBG.setVisible(bool);
    },

    reSetPos : function(){
        this._showText.setPosition(this._myPos);
    },

    onExit:function(){
        this._super();
        myData.clrearData();
    }
});