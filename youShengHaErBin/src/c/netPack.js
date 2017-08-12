var gameNetVersion = 1;

var game_msgId_rcv = {
    LOGIN_RESP: 1,
    ONTICK_RESP:3,
    CHAT_RESP:5,
    OTHER_CHAT:25,
};

var game_msgId_send = {
    LOGIN: 51,
    ONTICK:53,
    CHAT: 55
};

var game_pack_template_rcv = {
    LOGIN_RESP:function(jsonData){

    },
    ONTICK_RESP:function(jsonData){

    },
    CHAT_RESP:function(jsonData){

    },
    OTHER_CHAT:function(jsonData){

    }
}

var game_pack_template_send = {
    LOGIN:function(){

    },
    ONTICK:function(){

    },
    CHAT:function(){

    }
}


var ngc_ws_status = {none: 100, notOpened:0, opened:1, closing:3, closed:4};
/* 网络模块 超时处理放到外边gameLayer */
ngc.game.CWs = cc.Class.extend({
    _wsUrl: "",
    _cb: null,
    _target: null,
    _instWs: null,
    _msgArray: null,
    _chatSendPackAry: null,
    _curChatSendPack: null,
    _chatSendStatus: -1,
    _chatRespPack: null,
    _chatNotifyPackObj: null,
    _netSpeed: 0,
    _lastOnTickSec: 0,
    _delegate:null,

    ctor: function(){
        this._msgArray = [];
        this.clearChatCache();
    },

    /* p表示private */
    pIsOpened: function(ws){
        if(!ws)
            return false;

        return (ws.readyState === 0 || ws.readyState === 1);
    },

    /* 是否连接成功 */
    pIsConnected: function() {
        if(!this._instWs)
            return false;

        return (this._instWs.readyState === 1);
    },

    pCheckClose: function(){
        var ws = this._instWs;
        if(this.pIsOpened(ws)){
            ws.close();
        }

        this.pClearWsInfo();
    },

    pClearWsInfo: function(){
        this._instWs = null;
        this._msgArray = [];
        this.clearChatCache();
    },

    myInit: function(wsUrl, cb, target,delegate){
        this._wsUrl = wsUrl;
        this._cb = cb;
        this._target = target;
        this._delegate=delegate;

        return true;
    },

    myFinal: function(){
        this.pCheckClose();
        this._cb = null;
        this._target = null;
    },

    open: function(){
        this.pCheckClose();

        ngc.log.info(cc.formatStr("start connect: %s", this._wsUrl));
        var ws = new ngcc.CNgcWebSocket(this._wsUrl);
        this._instWs = ws;
        this._lastOnTickSec = this._delegate.getCurSecTick();

        var self = this;
        ws.onopen = function (event) {
            // action = 0 is connected
            self._msgArray.push({"action": 0, "data": "connected"});

            ngc.log.info("connected");
        };
        ws.onmessage = function (event) {
            var json = ngc.pubUtils.string2Obj(event.data);
            var action = json["action"];
            if(!action){
                ngc.log.error("ws.onmessage no action: " + event.data);
                return;
            }
            if(action === game_msgId_rcv.ONTICK_RESP) {
                self.rcvPackOnTickResult(json);
            } else if(action === game_msgId_rcv.CHAT_RESP) {
                self.rcvPackChatResult(json);
            } else if(action === game_msgId_rcv.OTHER_CHAT) {
                self.rcvPackOtherChatNotify(json);
            } else {
                self._msgArray.push(json);
            }
        };
        ws.onclose = function (event) {
            ngc.log.info("ws on close");
            self.pClearWsInfo();
        };
        ws.onerror = function (event) {
            ngc.log.info("ws on error");
        };
    },

    /* 定时调用回调，可以放到帧事件里面执行 */
    callBack: function(){
        var status = ngc_ws_status.none;
        if(this._instWs)
            status = this._instWs.readyState;
        if(this._cb)
            this._cb.call(this._target, status, this._msgArray);

        this._msgArray = [];

        this.checkSendChatMsg();
    },

    sendPack: function(jsonOrStr) {
        if(!this.pIsConnected()){
            ngc.log.error("sendPack not connected");
            return;
        }
        if(jsonOrStr.constructor === String){
            this._instWs.send(jsonOrStr);
        } else {
            var sendStr = ngc.pubUtils.obj2String(jsonOrStr);
            this._instWs.send(sendStr);
        }
    },

    sendPackOnTick: function(){
        var pack = {"action": game_msgId_send.ONTICK, "tick": this._delegate.getCurFrameTick()};
        this.sendPack(pack);
    },

    clearChatCache: function(){
        this._chatSendPackAry = [];
        this.clearCurSendCache();
        this._chatNotifyPackObj = {};
    },

    clearCurSendCache: function(){
        this._curChatSendPack = null;
        this._chatSendStatus = -1;
        this._chatRespPack = null;
    },

    getSplitLen: function(){
        return 50*1024;
    },

    getSplitMsg: function(strMsg){
        var len = this.getSplitLen();
        if(strMsg.length <= len)
            return strMsg;
        else
            return strMsg.substr(0, len);
    },

    send1SplitChatMsg: function(packOrder){
        var curPack = this._curChatSendPack;
        var splitMsg = this.getSplitMsg(curPack.chatMsg);
        var leftLen = curPack.chatMsg.length - splitMsg.length;


        if(leftLen > 0){
            curPack.chatMsg = curPack.chatMsg.substr(splitMsg.length, leftLen);
        } else {
            packOrder = 0;
            curPack.chatMsg = "";
        }

        var pack = {
            "action": game_msgId_send.CHAT,
            "chatType": curPack.chatType,
            "isSplit": curPack.isSplit,
            "packOrder": packOrder,
            "chatMsg": splitMsg
        };

        this.sendPack(pack);
    },

    checkSendChatMsg: function(){
        if(!this._curChatSendPack){
            if(this._chatSendPackAry.length > 0)
                this._curChatSendPack = this._chatSendPackAry.pop();
        }

        if(this._curChatSendPack){
            var status = this._chatSendStatus;
            if(status < 0){
                this._chatSendStatus = 1;
                this.send1SplitChatMsg(this._chatSendStatus);
            }
        }
    },

    //请求散桌
    sendPackClearTable:function(ctrlCode, isAgree){
        var pack = {
            "action": game_msgId_rcv.MSGID_CLIENT_QUEST_CTRL_TABLE,
            "ctrlCode":ctrlCode,
            "isAgree":isAgree,
        };
        this.sendPack(pack);
    },

    sendPackChat: function(chatType, chatMsg){
        chatMsg += "";
        var isSplit = 1;
        if (chatMsg.length <= this.getSplitLen())
            isSplit = 0;
        var pack = {
            "action": game_msgId_send.CHAT,
            "chatType": chatType,
            "isSplit": isSplit,
            "packOrder": 0,
            "chatMsg": chatMsg
        };
        if (0 === isSplit) {
            ngc.log.info("sendPack");
            this.sendPack(pack);
        } else {
            this._chatSendPackAry.unshift(pack);
        }
    },

    rcvPackOnTickResult: function(json) {
        var lastTick = json["tick"];
        var curTick = this._delegate.getCurFrameTick();
        this._netSpeed = ngc.pubUtils.getTickDiff(lastTick, curTick);
        this._lastOnTickSec = this._delegate.getCurSecTick();
        //ngc.log.info("net speed = " + this._netSpeed);
    },

    rcvPackChatResult: function(json) {
        if(0 !== json["code"]){
            this.clearChatCache();
            ngc.log.info("rcvPackChatResult code != 0");
            return;
        }

        if(0 === json["isSplit"]){
            this._msgArray.push(json);
            return;
        }

        var packOrder = json["packOrder"];
        if(!this._chatRespPack){
            if(1 !== packOrder){
                this.clearCurSendCache();
                ngc.log.error("rcvPackChatResult 1 !== packOrder");
                return;
            }
            this._chatRespPack = json;
        } else {
            if(2 === packOrder){
                this._chatRespPack.chatMsg += json["chatMsg"];
            } else if (0 === packOrder){
                this._chatRespPack.chatMsg += json["chatMsg"];
                this._msgArray.push(this._chatRespPack);
                this.clearCurSendCache();
                return;
            } else {
                this.clearCurSendCache();
                ngc.log.error("rcvPackChatResult packOrder not 0 2");
                return;
            }
        }

        if(this._curChatSendPack){
            var status = this._chatSendStatus;
            if(1 === status || 2 === status){
                this._chatSendStatus = 2;
                this.send1SplitChatMsg(this._chatSendStatus);
            } else {
                ngc.log.error("rcvPackChatResult 1&2 !== _chatSendStatus")
            }
        }
    },

    rcvPackOtherChatNotify: function(json) {
        if(0 === json["isSplit"]){
            this._msgArray.push(json);
            return;
        }

        var packOrder = json["packOrder"];
        var keyName = json["userId"].toString();
        var curPack = this._chatNotifyPackObj[keyName];
        if(!curPack){
            if(1 !== packOrder){
                ngc.log.error("rcvPackOtherChatNotify 1 !== packOrder");
                return;
            }
            this._chatNotifyPackObj[keyName] = json;
        } else {
            if(2 === packOrder){
                curPack.chatMsg += json["chatMsg"];
            } else if (0 === packOrder){
                curPack.chatMsg += json["chatMsg"];
                this._msgArray.push(curPack);
                delete this._chatNotifyPackObj[keyName];
            } else {
                delete this._chatNotifyPackObj[keyName];
                ngc.log.error("rcvPackOtherChatNotify packOrder not 0 2");
            }
        }
    },

    getLastOnTickSec: function() {
        return this._lastOnTickSec;
    }
});