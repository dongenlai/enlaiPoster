/**
 * Created by Dongenlai on 2016/9/18.
 * 大的通用弹框
 */

/*
 0 : 拒绝不良游戏提示
 1 : 您还未同意用户协议
*/

ngc.game.layer.commonBigBombBoxLayer = ngc.CLayerBase.extend({
    _Image_1:null,
    _imgArry:[],     //严格的按照上面 0 1 2 3对应
    _imageStr:null,  //弹框内容

    /*
     @ param strType 对应内容图片
     @ isRunning 是否向上偏移
     */
    ctor:function(strType, isRunning){
        this._super();
        this._imgArry = [];
        this._Image_1 = null;
        this._imageStr = null;
        this.myInit(strType, isRunning);
    },

    myInit:function(strType, isRunning){
        this._super(ngc.hall.jsonRes.bigLayerReconnect, true);
        this.byStrTypeConfirmContent(strType, isRunning);
        this.mySetVisible(true);
    },

    byStrTypeConfirmContent:function(strType, isRunning){
        var that = this;
        that._imageStr = that._imgArry[strType];
        that._imageStr.setVisible(true);
        if(that._imageStr){
            if(isRunning){
                that._Image_1.runAction(cc.sequence(cc.moveBy(1.5, cc.p(0, 40)), cc.callFunc(function(){
                    that.removeFromParent(true);
                })));
            }else{
                that._Image_1.runAction(cc.sequence(cc.delayTime(1.5), cc.callFunc(function(){
                    that.removeFromParent(true);
                })));
            }
        }
    },
});