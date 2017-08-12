/**
 * Created by admin on 2016/12/8.
 */
ngc.game.layer.Share = ngc.CLayerBase.extend({
    shareventname : "shareeventName",
    myInit : function(){
        this._super(ngc.hall.jsonRes.layerShare,true);
        this.mySetVisibleTrue();
        if(!this.eventListener){
            var self = this;
            this.eventListener = cc.EventListener.create({
                event : cc.EventListener.CUSTOM,
                eventName : self.shareventname,
                callback : function(event){
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this.eventListener,1);
        }
    },

    onBtnShareClick : function(sender){
        var self = this;
        var tag = sender.getTag();
        ngc.log.info("++++++++" + tag);

        ShareBZ.doShare(1, 4, "", "欢乐沧州麻将", ngc.cfg.shareUrlN, "好玩的欢乐沧州麻将，大家一起来玩啊", tag, function (ar1,ar2,ar3) {
            //var data={channel:1,sharePoint:1,result:ar3};
            //ngc.http.httpPostHs("/interface/share_userResult.do",data,self.shareventname,"share");
        });
    },

    onHttpEvent : function(userData){
        if(userData.errorCode !== 0){
            this.hideLogining();
            console.log("连接服务器失败");
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        switch (userData.data){
            case "share":
                if(retJson.response==1){
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true,"分享成功，获得"+retJson.awardNum+"张房卡");
                    this.addChild(commonLayer);
                    ngc.http.httpPostHs("/interface/user_userBaseInfo.do",{userId:ngc.curUser.baseInfo.userId,property:2},"shareeventName","baseInfo");
                }else{
                    var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, retJson.msg);
                    this.addChild(commonLayer);
                }
                break;
            case "baseInfo":
                var cardNum = retJson["vo"][0]["property"]["specialGold"];
                ngc.curUser.baseInfo.specialGold = cardNum;
                if(cc.director.getRunningScene()._cardNum){
                    cc.director.getRunningScene()._cardNum.setString(ngc.curUser.baseInfo.specialGold);
                }
                break;

        }


    },

    onBtnCloseClick : function(sender){
        this.removeFromParent();
    },

    onEnter : function(){
        this._super();
    },

    onExit : function(){
        this._super();
    },

});