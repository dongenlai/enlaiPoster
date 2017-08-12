/**
 * Created by Dongenlai on 2017/3/29.
 */
ngc.game.layer.getRoomList = ngc.CLayerBase.extend({
    _listView:null,
    _cellPanel:null,
    _roomText:null,
    _createTimeText:null,
    _playerText:null,
    _isStartGame:null,

    _customEventName:"getRoomListEvent",
    _customEventListener:null,
    _roomID:null,
    _gameRoomID:null,

    ctor: function (gameRoomId) {
        this._super();
        this._gameRoomID = gameRoomId;
        this.myInit();
    },

    myInit:function(){
        this._super(ngc.hall.jsonRes.getRoomList, true);
        this.mySetVisible(true);
        if (!this._customEventListener) {
            var self = this;
            this._customEventListener = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: self._customEventName,
                callback: function(event){
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener, 1);
        }
        this.getRoomList();
    },

    onHttpEvent: function (userData) {
        if (userData.errorCode !== 0) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "获取服务器失败");
            this.addChild(commonLayer);
            return;
        }

        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        console.log("retJson ==== " + JSON.stringify(retJson));
        if(userData.data == "fs"){
            this.onFsSuccess(retJson);
        }

        if (retJson["response"] == 1) {
            switch (userData.data) {
                case "game_privateTableList":
                    this.initRoomListData(retJson);
                    break;
                case "autoLogin":
                    this.getRoomList();
                    break;
                default:
                    ngc.log.error("onHttpEvent data=" + userData.data);
                    break;
            }
        } else if (retJson["response"] == 9 && !this._hasLogin&&ngc.curUser.token!=undefined&&ngc.curUser.baseInfo!=undefined) {
            this._hasLogin=true;
            var postData = {"userId": ngc.curUser.baseInfo.userId, "token": ngc.curUser.token};
            ngc.http.httpPostHs("/interface/base_autoLogin.do", postData, this._customEventName, "autoLogin");
        } else {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, retJson["msg"]);
            this.addChild(commonLayer);
        }
    },

    //现获取一下人任务奖励
    getRoomList:function(){
        var postData = {playTypeId:parseInt(this._gameRoomID/100)};
        ngc.http.httpPostHs("/interface/game_privateTableList.do", postData , this._customEventName, "game_privateTableList");
    },

    initRoomListData:function(data){
      ngc.log.info("initRoomListData: " + JSON.stringify(data));
      var vo = data["vo"] || [];
      var fileInPut = ngc.hall.pngRes.roomListBtn1;
      var fileInvate = ngc.hall.pngRes.roomListBtn2;
      this._listView.removeAllItems();

      for(var key = 0 in vo){
          var curData = vo[key];
          var tableID = curData["tableId"] || "";
          var createTime = curData["createTime"] || "";
          var totalRound = curData["totalInning"] || "";
          var option = curData["option"] || {};
          var isStartGame = curData["isStartGame"] || false;

          if(this._roomText)
             this._roomText.string = tableID;

          if(this._createTimeText)
            this._createTimeText.string = createTime;

          var dataObj = eval("(" + option + ")");
          var curGameRoomID = dataObj.gameRoomId;
          var playStr = this.getPlayerTypeStr(dataObj, curGameRoomID);

          if(this._playerText){
              this._playerText.setString(playStr);
          }

          if(isStartGame)
            this._isStartGame.string = "房间已开";

          var _tempPanel = this._cellPanel.clone();
          if(!isStartGame){
              var inputBtn = new ccui.Button(fileInPut, fileInPut, fileInPut, ccui.Widget.LOCAL_TEXTURE);
              inputBtn.attr({
                  x:595.19,
                  y:103.12
              });
              _tempPanel.addChild(inputBtn);
              inputBtn.roomId = tableID;
              inputBtn.addTouchEventListener(this.onInPutBtnTouch, this);

              var invateBtn = new ccui.Button(fileInvate, fileInvate, fileInvate, ccui.Widget.LOCAL_TEXTURE);
              invateBtn.attr({
                  x:753.12,
                  y:103.12
              });

              _tempPanel.addChild(invateBtn);
              invateBtn.roomId = tableID;
              invateBtn.totalRound = totalRound;
              invateBtn.playTypeStr = playStr;
              invateBtn.addTouchEventListener(this.onInvateBtnTouch, this);
          }
          this._listView.pushBackCustomItem(_tempPanel);
      }
    },

    //请求Fs
    connectFs: function (tableNumber){
        var gameRoomTypeId = ngc.curUser.gameRoomTypeId;
        var accessToken = ngc.curUser.access_token;
        var postData = {
            "accessToken": accessToken,
            "jingWeiDu": "{'jingdu':'0.0','weidu':'0.0'}",
            "gameRoomType": gameRoomTypeId,
            "isFind": 1,    //创建房间的时候传 0 加入房间传1
            "tableNum": tableNumber
        };
        var fsUrl = ngc.cfg.GAME_FSADRRESS;
        ngc.http.httpPostFs(fsUrl, postData, this._customEventName, "fs");
    },

    // 连接分发成功
    onFsSuccess: function (jsonData) {
        ngc.log.info("onFsSuccess: " + JSON.stringify(jsonData))
        var data = jsonData["data"];
        var ip = data[0].ip;
        var port = data[0].port;
        ngc.cfg.GAME_ADRRESS = ip;
        ngc.cfg.GAME_PORT = port;
        ngc.curUser.gameRoomId = data[0]["gameRoomId"];
        // setCurrentGameByGameRoomId(data[0]["gameRoomId"]);
        this.onInPutGame();
    },

    onInPutBtnTouch:function(sender, type){
        if(type != ccui.Widget.TOUCH_ENDED) return;
        var roomID = sender.roomId;
        this._roomID = roomID;
        this.connectFs(roomID);
    },

    onInPutGame:function(){
        var roomID = this._roomID;
        var gameData = { "isFind": 1, "tableNum": roomID, "creating": true };
        this.onCloseMySelf();
        var scene = new ngc.hall.SceneLoadGame(gameData);
        cc.director.runScene(scene);
    },

    onInvateBtnTouch:function(sender, type){
        if(type != ccui.Widget.TOUCH_ENDED) return;
        var roomID = sender.roomId;
        var totalRound = sender.totalRound;
        var playTypeStr =sender.playTypeStr;
        ngc.log.info("onInvateBtnTouch_playTypeStr:" + playTypeStr)
        ShareBZ.doShare(1, 4, "", "沧州麻将-" + roomID + "-代开", ngc.cfg.shareUrlN, "房号：" + roomID  + "，" + totalRound.toString() + "局，" + playTypeStr + "，小伙伴们速度来啊！[沧州麻将]", 0, function () {
            //console.log("邀请成功");
        });
    },

    getPlayerTypeStr:function(dataObj, curGameRoomID){
        var vipStr = (dataObj.vipRoomType == 3) ? ",房主承担," : ",每人一卡";
        var playTypeStr = "";
        if(curGameRoomID == 60401){
            playTypeStr = "扣点-" + (dataObj.isJiaFan ? "加番": "不加番");
        }else if(curGameRoomID == 60501){
            playTypeStr = "推倒胡-" + (dataObj["hasDaHu"]==1?"大胡":"平胡")+(dataObj["canTang"]==1?",报听":"")+(dataObj["hasFeng"]==1?",带风":"")+(dataObj["canZhuoPaoHu"]==1?",自摸胡":"")+(dataObj["isNotHuGang"] == 1 ?",杠就算分":"");
        }else if(curGameRoomID == 61801){
            if(dataObj.lzCount == 1){
                playTypeStr = "单耗子";
            }else if(dataObj.lzCount == 2){
                playTypeStr = "双耗子";
            }
            playTypeStr = "扣点癞子-" + playTypeStr;
        }else if(curGameRoomID == 91104){
            var gangScore = dataObj["gangScore"];
            var canTang = dataObj["canTang"];
            var chuiZhuang = dataObj["chuiZhuang"];
            var chi = dataObj["chi"];
            var yao13_1 = dataObj["yao13_1"];
            var yao13_3 = dataObj["yao13_3"];
            playTypeStr = "靠八张-" + (gangScore == 1 ? "杠就算分" : "")+(canTang == 1 ? ",报听":"") + (chuiZhuang == 1 ? ",吹庄":"") + (chi == 1?",带吃":"") + (yao13_1 == 1 ?",十三幺抢一次":"") + (yao13_3 == 1 ?",十三幺抢三次":"")
        }else if(curGameRoomID == 91105){
            playTypeStr = "晋中麻将-" + (dataObj["canTang"]==1?"报听":"") + (dataObj["gangScore"] == 1 ?"杠就算分":"");
        }
        return playTypeStr + vipStr;
    },

    onCloseMySelf:function(){
        if (this._customEventListener) {
            cc.eventManager.removeListener(this._customEventListener);
            this._customEventListener = null;
            ngc.log.info("onCloseMySelf")
        }
       this.removeFromParent(true);
    },

})