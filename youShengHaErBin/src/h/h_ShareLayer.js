/**
 * Created by Dongenlai on 2016/10/14.
 */
ngc.game.layer.shareLayer = ngc.CLayerBase.extend({
    _customEventName: "getZhanJiData",
    _customEventListener:null,

    _listView:null,
    _cellPanel:null,
    _cellbg:null,
    _countNumber:10,
    _TimeNum:null,
    _roomCardNumber:null,
    _endTimeNumber:null,
    _nameText:[],
    _scoreText:[],
    _hasLogin:false,

    _haErBinBtn:null,
    _heiLongJiangBtn:null,
    _haHeiLongJiangBg:null,
    _haErBinBg:null,

    _sharePanel:null,
    _zhanJiPanel:null,

    _logo:null,
    _curTexture:null,
    _zhanjiPanel:null,
    gamrRoomID:null,


    myInit:function(){
        this._nameText = [];
        this._scoreText = [];
        this._hasLogin=false;
        this._super(ngc.hall.jsonRes.shareLayer, true);
        this.mySetVisible(true);
        this._curTexture = this._logo.getTexture();
        this.gamrRoomID = ngc.curUser.gameRoomId;
        this.onShare();
    },


    initMjView:function (visible) {
        this._haHeiLongJiangBg.setVisible(!visible);
        this._haErBinBg.setVisible(visible);

        this._sharePanel.setVisible(visible);
        this._zhanjiPanel.setVisible(!visible);

        var file = visible ? "res/hallUi/e/title2 3.png": this._curTexture;
        this._logo.setTexture(file);
    },

    on2Ren:function () {
        this.gamrRoomID = ngc.curUser.game2RenRoomId;
        this.sendZhanjiData();
    },

    on3Ren:function () {
        this.gamrRoomID = ngc.curUser.game3RenRoomId;
        this.sendZhanjiData();
    },

    on4Ren:function () {
        this.gamrRoomID = ngc.curUser.gameRoomId;
        this.sendZhanjiData();
    },

    onZhanJi:function () {
        this.initMjView(false);
        this.sendZhanjiData();
    },

    onShare:function () {
        this.initMjView(true);
    },

    onEnter:function(){
        this._super();
        this._customEventListener = null;
        if (!this._customEventListener) {
            var self = this;
            this._customEventListener = cc.EventListener.create({
                event: cc.EventListener.CUSTOM,
                eventName: self._customEventName,
                callback: function (event) {
                    self.onHttpEvent(event.getUserData());
                }
            });
            cc.eventManager.addListener(this._customEventListener, 1);
        }
    },


    sendZhanjiData:function(){
        var postData = {gameRoomId:this.gamrRoomID, count: this._countNumber};
        ngc.http.httpPostHs("/interface/game_userResultSum.do", postData, this._customEventName, "getZhanJiData");
    },

    onHttpEvent: function (userData) {
        ngc.log.info(userData);
        if (userData.errorCode !== 0) {
            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, "获取服务器失败");
            this.addChild(commonLayer);

            this.runAction(cc.sequence(cc.delayTime(4), cc.CallFunc(function(target){
                //target.removeMySelf();
            })))
            this.hideLoading();
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        if (retJson["response"] == 1) {
            switch (userData.data) {
                case "getZhanJiData":
                    this.initListView(retJson);
                    break;
                case "autoLogin":
                    this.sendZhanjiData();
                    break;
                case "getRecord":
                    this.downLoadRecord(retJson);
                    break;
                default:
                    ngc.log.error("onHttpEvent data=" + userData.data);
                    break;
            }
        } else if(retJson["response"]==9&&!this._hasLogin&&ngc.curUser.token!=undefined&&ngc.curUser.baseInfo!=undefined) {
            this.hideLoading();

            this._hasLogin=true;
            var postData = {"userId": ngc.curUser.baseInfo.userId, "token": ngc.curUser.token};
            ngc.http.httpPostHs("/interface/base_autoLogin.do", postData, this._customEventName, "autoLogin");
        }
        else{
            this.hideLoading();

            var commonLayer = new ngc.game.layer.commonBombBoxLayer(4, true, true, retJson["msg"]);
            this.addChild(commonLayer);

            this.runAction(cc.sequence(cc.delayTime(4), cc.CallFunc(function(target){
                //target.removeMySelf();
            })))
        }
    },

    getNum:function(textStr){
        var numberArry = textStr.replace(/[^0-9]/ig,"");
        return numberArry || 0;
    },


    getTimeOff:function(endTime){
        var year = endTime.substr(0, 4);
        var mounth = endTime.substr(4, 2);
        var day = endTime.substr(6, 2);
        var hour = endTime.substr(8, 2);
        var minute = endTime.substr(10, 2);
        var second = endTime.substr(12, 2);

        return [year, mounth, day, hour, minute, second];

    },

    initListView:function(jsonData){
        var vo = jsonData["ex"] || [];
        this._listView.setScrollBarEnabled(false);
        for(var k = 0 in vo){
            var dataArry = vo[k];
            var serialNum=null;
            for(var i = 0, length = dataArry.length; i < length; ++i){
                var curData = dataArry[i];
                var userName = curData.nickName || "";
                var score = curData.addBean || "";
                var scoreStr = "";
                if(parseInt(score) < 0){
                    scoreStr = score;
                }else{
                    scoreStr = "+" + score;
                }
                this._nameText[i].string = userName;
                this._scoreText[i].string = scoreStr;
                // if(serialNum==null&&curData["openSerialNums"]&&curData["openSerialNums"].length>0){
                //     for(var key2=0 in curData["openSerialNums"]){
                //         if(serialNum==null)
                //             serialNum=curData["openSerialNums"][key2];
                //         else
                //             serialNum+= "," + curData["openSerialNums"][key2];
                //     }
                // }
            }
            var _tempPanel = this._cellPanel.clone();
            var btn=ccui.helper.seekWidgetByName(_tempPanel, "_recordPlayBtn");
            btn.serialNum=serialNum;
            this._listView.pushBackCustomItem(_tempPanel);
        }

    },
    onRecordPlay:function(sender,type){
        if(type==ccui.Widget.TOUCH_ENDED){
            var serialNum=sender.serialNum;
            var postData={
                "userId":ngc.curUser.baseInfo.userId,
                "openSerialNums":serialNum,
                "accessToken":ngc.curUser.access_token
            }
            this.showLoading();
            ngc.http.httpPost(ngc.cfg.urlRecord, {}, 10*1000, postData,this._customEventName, "getRecord");
        }
    },

    onBackGameScene:function(){
        this.removeFromParent(true);
    },

    onExit:function(){
        this._super();
        if (this._customEventListener) {
            cc.eventManager.removeListener(this._customEventListener);
            this._customEventListener = null;
        }
    },

    downLoadRecord:function(records){
        var recordFiles=[];
        for(var i=1;i<=30;i++){
            if(records["url"][i.toString()]){
                recordFiles.push(records["url"][i.toString()]);
            }
            else{
                break;
            }
        }
        if(recordFiles.length>0){
            ngc.log.info(recordFiles);
            this.startDowloadFiles(recordFiles);
        }
    },
    showLoading: function () {
        if (!this.loadingNode) {
            var loadInfo = ngc.uiUtils.loadJson(this, ngc.hall.jsonRes.logining);
            this.addChild(loadInfo.node);
            this.loadingNode = loadInfo;

            var childs = loadInfo.node.getChildren();
            childs[1].setVisible(false);
            childs[2].setVisible(false);
            loadInfo.node.setPosition(90, 0);
        }
        this.loadingNode.node.setVisible(true);
        this.loadingNode.action.play("animation0", true);
    },

    hideLoading:function(){
        if(this.loadingNode)
            this.loadingNode.node.setVisible(false);
    },

    startDowloadFiles:function(remoatefiles){
        var toDownLoadFiles=[];
        var toloaclPath="mjrecordfiles/";
        var toLocalFiles=[];

        for(var key=0 in remoatefiles){
            var remoteFile=remoatefiles[key].replace(/\\/g, "/");
            var index=remoteFile.lastIndexOf("/");
            var fileName=remoteFile.substring(index+1);
            var localFilePath=jsb.fileUtils.getWritablePath()+toloaclPath+fileName;
            if(!jsb.fileUtils.isFileExist(localFilePath)){
                toDownLoadFiles.push(remoteFile);
            }
            toLocalFiles.push(toloaclPath+fileName);
        }

        if(toDownLoadFiles.length==0) { //要下载的都已经缓存在本地了
            this.onAllFilesDownloaded(toLocalFiles);
        }
        else{
            this.fileLoader=new ngc.fileDownloader(toDownLoadFiles,toLocalFiles,this.onAllFilesDownloaded,this,this.onDownloadFialed,this);
        }
    },

    onAllFilesDownloaded:function(toLocalFiles){
        this.hideLoading();
        this.downloadFiles=toLocalFiles;
        this.unscheduleUpdate();
        this.scheduleUpdate();
    },

    onDownloadFialed:function(){
        ngc.log.info("下载失败!");
        this.hideLoading();
    },
    update:function(){
        if(this.downloadFiles&&this.downloadFiles.length>0){
            var realLocalFiles=[];
            for(var key=0 in this.downloadFiles){
                realLocalFiles.push(jsb.fileUtils.getWritablePath()+this.downloadFiles[key]);
            }
            if(realLocalFiles.length>0){
                var tablePlayer = new ngc.game.scene.tablePalyerScene();
                tablePlayer.setLocalFiles(realLocalFiles);
                cc.director.pushScene(tablePlayer);
            }
            this.downloadFiles=null;
        }
    }
});



