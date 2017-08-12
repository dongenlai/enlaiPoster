/*
 * Created by Dongenlai on 2016/9/26.
 * 散桌层
*/

ngc.game.clearTableLayer = ngc.CLayerBase.extend({
    _text_1:null,    //玩家【***】申请解散房间
    _text_2:null,    //请在300秒内进行选择，超时未做选择则默认同意.
    _textPlayer:[],  //玩家等待数组
    _cancelBtn:null,
    _sureBtn:null,
    _timeOffSet:300,
    isctrlCode:0,
    isMyState:null,
    isSetTimeState:null,

    /*
      @param isMyState 是否是自己点击触发散桌
      @param decTimeCount 时间
    */
    myInit:function(isMyState, decTimeCount){
      this._textPlayer = [];
      this._super(ngc.game.jsonRes.clearTable, true);
      this.mySetVisibleTrue();
      this.isMyState = isMyState;
      if(isMyState){
          this._cancelBtn.setVisible(false);
          this._sureBtn.setVisible(false);
          var userNameAry = ngc.g_mainScene._userNameAry;
          var userInfo = userNameAry[0];
          var userName = userInfo.userName;
          this._textPlayer[0].string = cc.formatStr("【" + '%s' +"】"+ "同意", userName);
      }
      this.setTimeOffSet(decTimeCount);
      this.setTextStr();
      this.openSchedule();
    },
    /*
      @param nameStr 玩家名字
      @param offset  对应的是_textPlayer 数组索引 （0 - 3）
    */
    initView:function(nameStr, isctrlCode, isAgree, offset){
     if(this._textPlayer[offset])
      if (isctrlCode == 0) {
         this.isctrlCode = 1;
         this._text_1.string = cc.formatStr("玩家【"+ "%s" +  "】" + "申请解散房间", nameStr);
         this._textPlayer[offset].string = cc.formatStr("【" + '%s' +"】"+ "同意", nameStr);  //申请解散的人一定是同意解散房间的
      }else if( isctrlCode == 1) {
        if(isAgree == 1){
            this._textPlayer[offset].string = cc.formatStr("【" + '%s' +"】"+ "同意", nameStr);
        }else{
            var that = this;
            this._textPlayer[offset].string = cc.formatStr("【" + '%s' +"】"+ "不同意", nameStr);
            this._cancelBtn.setTouchEnabled(false);
            this._sureBtn.setTouchEnabled(false);
            setTimeout(function(){
                that.closerMySelf();
            }, 3000);
        }
      }
    },

    setTextStr:function(){
        var userNameAry = ngc.g_mainScene._userNameAry;
        for(var k = 0 in userNameAry){
            var userInfo = userNameAry[k];
            var userName = userInfo.userName;
            var k = parseInt(k);
            if(userName){
                if(k == 0){
                    this._text_1.string = cc.formatStr("玩家【"+ "%s" +  "】" + "申请解散房间", userName);
                }else{
                    this._textPlayer[k].string = cc.formatStr("【" + '%s' +"】"+ "等待选择", userName);
                }
                if(!this.isMyState){
                    this._textPlayer[k].string = cc.formatStr("【" + '%s' +"】"+ "等待选择", userName);
                }
            }
        }
    },

    hideOrShowButton:function(state){
        this._cancelBtn.setVisible(state);
        this._sureBtn.setVisible(state);
    },

    setSchedule:function(){
        //默认玩家自己同意或者同意其他人申请散桌
        if(this._timeOffSet == 0){
            this.onSure();
            return ;
        }
        this._text_2.string = cc.formatStr("请在%d秒内进行选择，超时未做选择则默认同意.", this._timeOffSet);
        this._timeOffSet --;
    },

    openSchedule:function(){
        this.schedule(this.setSchedule, 1);
    },

    removeSchedule:function(){
       this.unschedule(this.setSchedule);
    },

    setTimeOffSet:function(time){
      this._timeOffSet = time;
    },

    getTimeOffSet:function(){
      return this._timeOffSet;
    },

    //散桌
    onScattered: function () {
        this.isctrlCode = 0;
        this._clearTableText.string = "您正在申请解散"+ "\n" + "本桌游戏，是否继续？";
        return;
    },

    onCancel: function () {
        var netlayer = ngc.g_mainScene.getNet();
        netlayer.sendPackClearTable(1, 0);
        this.closerMySelf();
        //this.hideOrShowButton(false);
    },

    onSure: function () {
        var userNameAry = ngc.g_mainScene._userNameAry;
        var userInfo = userNameAry[0];
        var userName = userInfo.userName;
        this._textPlayer[0].string = cc.formatStr("【" + '%s' +"】"+ "同意", userName);
        var netlayer = ngc.g_mainScene.getNet();
        netlayer.sendPackClearTable(this.isctrlCode,  1);
        this.isctrlCode = 0;
        this.hideOrShowButton(false);
    },

    closerMySelf:function(){
      this.removeSchedule();
      this.removeFromParent(true);
      ngc.g_mainScene._clearTableLayer = null;
    },

});