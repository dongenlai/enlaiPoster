/**
 * Created by Dongenlai on 2016/9/18.
 * 通用提示框
*/

/*
  图片标签下面
  0 : 正在连接中
  1 : 连接失败
  ....
*/
ngc.game.layer.commonBombBoxLayer = ngc.CLayerBase.extend({
    _Image_1:null,
    _imgArry:[],     //严格的按照上面 0 1 2 3对应
    _imageStr:null,  //弹框内容
    _isRemove:null,
    _autoLabel:null,  //自定义文字标签
    _moveTime:1.5,
    _Panel_1:null,

    /*
      @ param strType 对应内容图片
      @ isRunning 是否向上偏移
      @ isRemove  是否移除当前图层 （有的需求是后续移除）
      @ isAutoStr    是否使用自定义标签儿
    */

    ctor:function(strType, isRunning, isRemove, isAutoStr,isSwallow){
        this._super();
        this._imgArry = [];
        this._Image_1 = null;
        this._imageStr = null;
        this._isRemove = null;

        this.myInit(strType, isRunning, isRemove, isAutoStr,isSwallow);
    },

    setMoveTime:function(time){
        this._moveTime = time;
    },

    myInit:function(strType, isRunning, isRemove, isAutoStr,isSwallow){
        if(isSwallow==undefined) isSwallow=true;
        this._super(ngc.hall.jsonRes.layerReconnect, isSwallow);
        this._isRemove = isRemove;
        this.mySetVisible(true);
        this.byStrTypeConfirmContent(strType, isRunning, isRemove, isAutoStr);

        if(!isSwallow) {
            this._Panel_1.setTouchEnabled(false);
        }
    },

    byStrTypeConfirmContent:function(strType, isRunning, isRemove, isAutoStr){
        var that = this;
        //自定义图片标签得有原图
        that._imageStr = that._imgArry[strType];
        if( that._imageStr){
            that._imageStr.setVisible(true);
        }
        //自定义文字标签儿
        if(isAutoStr && cc.isString(isAutoStr)){
            that._autoLabel.setVisible(true);
            that._autoLabel.string = isAutoStr;
        }
        if(isRunning){
            that._Image_1.runAction(cc.sequence(cc.moveBy(this._moveTime, cc.p(0, 40)), cc.callFunc(function(){
                if(isRemove){
                    that.removeFromParent(true);
                }
            })));
        }else{
            that._Image_1.runAction(cc.sequence(cc.delayTime(this._moveTime), cc.callFunc(function(){
                if(isRemove){
                    that.removeFromParent(true);
                }
            })));
        }
    },

    removeMyLayer:function(){
       this.removeFromParent(true);
    },
});