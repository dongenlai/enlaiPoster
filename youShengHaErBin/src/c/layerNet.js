ngc.game.maxTimeoutSec = 9;

ngc.game.net=cc.Layer.extend({
    _ws:null,
    _callBack:null,
    _target:null,

    _reconnectingCallBack:null,
    _reconnectingTarget:null,

    _connectFailedCallBack:null,
    _connectFailedTarget:null,

    _curSecTick: 0,
    _curFrameTick: 0,
    _reconnectedNum:0,
    _MaxreconnectedNum:3,

    _hasConnectedNum:0,

    ctor:function(callBack,target){
        this._super();

        this._callBack=callBack;
        this._target=target;

        this._curSecTick = ngc.pubUtils.addTick(this._curSecTick);
        this._curFrameTick = ngc.pubUtils.addTick(this._curFrameTick);

        this._MaxreconnectedNum=3;

        this.scheduleUpdate();
        this.schedule(this.pRunTime1Sec, 1);
    },
    reset:function(){
        this._curSecTick=0;
        this._curFrameTick=0;
        this.unscheduleUpdate();
        this.scheduleUpdate();
        this.schedule(this.pRunTime1Sec, 1);
    },
    setMaxReconnectedNum:function(num){
        this._MaxreconnectedNum=num;
    },
    changeCallBack:function(callBack,target){
        this._callBack=callBack;
        this._target=target;
    },
    setReconnectingCallBack:function(callBack,target){
        this._reconnectingCallBack=callBack;
        this._reconnectingTarget=target;
    },
    setConnectFailedCallBack:function(callBack,target){
        this._connectFailedCallBack=callBack;
        this._connectFailedTarget=target;
    },
    onEnter:function(){
        this._super();
    },
    pRunTime1Sec: function(dt){
        this._curSecTick = ngc.pubUtils.addTick(this._curSecTick);
        if(this._curSecTick % 4 === 0){
            if(this._ws){
                this._ws.sendPackOnTick();
            }
        }
        if(this._ws){
            var lastSec = this._ws.getLastOnTickSec();
            var diff = ngc.pubUtils.getTickDiff(lastSec, this._curSecTick);
            if(diff > ngc.game.maxTimeoutSec){
                this.reConnectWs();
            }
        }
    },
    getCurSecTick: function(){
        return this._curSecTick;
    },

    getCurFrameTick: function(){
        return this._curFrameTick;
    },
    update: function(dt){
        this._curFrameTick = ngc.pubUtils.addTick(this._curFrameTick);
        this.onFrameTick(this._curFrameTick);
    },
    onFrameTick: function(curFrame){
        if(this._ws){
            this._ws.callBack();
        }
    },

    closeWs: function(){
        if(this._ws){
            this._ws.myFinal();
            this._ws = null;
        }
    },

    connectWs: function(){
        this.closeWs();
        this._ws = new ngc.game.CWs();
        this._ws.myInit(cc.formatStr("ws://%s:%d", ngc.cfg.GAME_ADRRESS, ngc.cfg.GAME_PORT),
            this.onReceivePack, this,this);
        this._ws.open();
    },

    reConnectWs: function(){
        if(this._reconnectedNum >= this._MaxreconnectedNum){
            this.closeWs();
            //连接||重连失败
            if(this._connectFailedCallBack)
                this._connectFailedCallBack.call(this._connectFailedTarget);
        }
        else{
            this._reconnectedNum++;
            this.connectWs();
            if(this._reconnectedNum==1&&this._hasConnectedNum>0&&this._reconnectingCallBack){
                this._reconnectingCallBack.call(this._reconnectingTarget);
            }

        }
    },

    //发送散桌请求
    sendPackClearTable:function(ctrlCode, isAgree){
        if(this._ws){
            this._ws.sendPackClearTable(ctrlCode, isAgree);
        }
    },

    sendPackChat: function(chatType, chatMsg){
        if(this._ws){
            this._ws.sendPackChat(chatType, chatMsg);
        }
    },

    onReceivePack:function(status, msgArray){
        if(status === ngc_ws_status.opened) {
            if(ngc.g_mainScene)
                ngc.g_mainScene.getSoundCache().myClear();
            for (var i = 0; i < msgArray.length; ++i) {
                try {
                    var json = msgArray[i];
                    if(json["action"] == 0){
                        this._reconnectedNum=0;
                        this._hasConnectedNum++;
                    }
                    if (this._callBack) {
                        this._callBack.call(this._target, json["action"], json);
                    }
                } catch (e) {
                    ngc.log.error(cc.formatStr("onReceivePack exception name=%s, msg=%s", e.name, e.message));
                }
            }
            //if(ngc.g_mainScene)
            //  ngc.g_mainScene.getSoundCache().myPlay();
        }else if(status === ngc_ws_status.none){
            this.reConnectWs();
        }
    },
    sendData:function(data){
        if(this._ws){
            this._ws.sendPack(data);
        }
    }
});