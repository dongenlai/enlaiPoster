
ngc.urlImgUserData = cc.Class.extend({
    url: "",
    data: null,
    isLoadSuccess: false,
    retTx: null,

    ctor: function(){
        this.data = {};
        this.retTx = null;
    }
});

ngc.uiUtils = {

    getChildrenCount: function(node){
        var children = node.getChildren();
        if(!children)
            return 0;
        return children.length;
    },

    isChildIndexValid: function(node, index){
        var cnt = ngc.uiUtils.getChildrenCount(node);
        return (index >= 0 && index < cnt);
    },

    /**
     * @param {cc.Node} node
     * @return {Array}
     */
    getAllChild: function(node){
        var cnt = ngc.uiUtils.getChildrenCount(node);
        if(cnt < 1)
            return [];

        var children = node.getChildren();
        var ary = [];
        for(var i = 0; i < cnt; ++i){
            ary.push(children[i]);
        }
        return ary;
    },

    /**
     * @param {Boolean} isEnabled
     * @param {Boolean} swallowEvent
     */
    setTouchEnabled: function(node, isEnabled, swallowEvent){
        if(isEnabled){
            if(!node._myTouchListener){
                var touchListener = cc.EventListener.create({
                    event: cc.EventListener.TOUCH_ONE_BY_ONE,
                    swallowTouch: swallowEvent,
                    onTouchBegan: function(touch, event) {
                        var self = event.getCurrentTarget();
                        if(!self)
                            return false;
                        if(!self.myOnTouchBegan)
                            return false;

                        var pos = self.convertToNodeSpace(touch.getLocation());
                        return self.myOnTouchBegan(pos);
                    },
                    onTouchMoved: function(touch, event) {
                        var self = event.getCurrentTarget();
                        if(!self)
                            return;
                        if(!self.myOnTouchMoved)
                            return;

                        var pos = self.convertToNodeSpace(touch.getLocation());
                        self.myOnTouchMoved(pos);
                    },
                    onTouchEnded: function(touch, event) {
                        var self = event.getCurrentTarget();
                        if(!self)
                            return;
                        if(!self.myOnTouchEnded)
                            return;

                        var pos = self.convertToNodeSpace(touch.getLocation());
                        self.myOnTouchEnded(pos);
                    }
                });
                node._myTouchListener = touchListener;
                cc.eventManager.addListener(touchListener, node);
            }
        } else {
            if(node._myTouchListener){
                cc.eventManager.removeListener(node._myTouchListener);
                node._myTouchListener = null;
            }
        }
    },

    /**
     * @param {ngc.CLayerBase} layer
     * @param {Boolean} isShield
     * @param {Boolean} swallowState 是否吞没事件 有的在自己的图层里面添加触摸事件的时候需要传 By 董恩来
     *
     */
    setShieldTouch: function(layer, isShield, swallowState){
        if(isShield){
            var swallowTouchState = true;
            if(swallowState){
                swallowTouchState = false;
            }
            if(!layer._listenerShield){
                var listener = cc.EventListener.create({
                    event: cc.EventListener.TOUCH_ONE_BY_ONE,
                    swallowTouches: swallowTouchState,
                    onTouchBegan: function (touch, event) {
                        return true;
                    }
                });
                cc.eventManager.addListener(listener, layer);
                layer._listenerShield = listener;
            }
        } else {
            if(layer._listenerShield){
                cc.eventManager.removeListener(layer._listenerShield);
                layer._listenerShield = null;
            }
        }
    },

    /**
     * 停止控件的所有action
     * @param {cc.Node} node
     */
    stopAllActions: function(node){
        node.stopAllActions();

        if(!node._myActionCb)
            return;
        node._myActionCb(node, true);
    },

    /**
     * 清理控件的action状态
     * @param {cc.Node} node
     */
    clearActionInfo: function(node){
        if(!node._myActionCb){
            ngc.log.error(cc.formatStr("clearActionInfo node=%s no action info", node.getName()));
            return;
        }
        node._myActionCb = null;
        if(node._myActionData){
            node._myActionData = null;
        }
    },

    /**
     * 设置控件的action状态
     * @param {cc.Node} node
     */
    setActionInfo: function(node, cb, userData){
        if(node._myActionCb){
            ngc.log.error(cc.formatStr("setActionInfo node=%s has action info", node.getName()));
            return;
        }
        node._myActionCb = cb;
        node._myActionData = userData;
    },

    /**
     * 获得控件的action数据
     * @param {cc.Node} node
     */
    getActionUserData: function(node){
        if(!node._myActionData){
            ngc.log.error(cc.formatStr("getActionUserData node=%s no action data", node.getName()));
        }
        return node._myActionData;
    },

    getNodeUserDataJson: function(node){
        var data = node.getComponent("ComExtensionData");
        if(!data)
            return {};
        return ngc.pubUtils.string2Obj(data.getCustomProperty());
    },

    loadJson: function(node, jsonRes) {
        ngc.g_auto_event_target = node;
        var loadInfo = ccs.load(jsonRes);
        ngc.g_auto_event_target = null;

        if(loadInfo.action)
            loadInfo.node.runAction(loadInfo.action);

        return loadInfo;
    },

    replaceTexture: function(node, txName){
        if(node._curRepaceTx !== txName){
            node._curRepaceTx = txName;
            node.cleanup();
            node.setTexture(cc.textureCache.getTextureForKey(txName));
        }
    },

    pDoImageLoadEvent: function(url, xEventName, xData, isSuccess, xRetTx){
        var event = new cc.EventCustom(xEventName);
        var userData = new ngc.urlImgUserData();
        userData.url = url;
        userData.data = xData;
        userData.isLoadSuccess = isSuccess;
        userData.retTx = xRetTx;
        event.setUserData(userData);
        // 如果 第二个参数设置成true，那么h5可以分发事件，win下事件丢失。
        cc.eventManager.dispatchEvent(event);

    },

    pCheckClearUrlCacheImage: function(){
        if(!cc.isNative)
            return;
        var ary = Object.keys(ngc.urlImageStatus);
        if(ary.length < 180)
            return;

        for(var i = 0; i < ary.length; ++i){
            var url = ary[i];
            var status = ngc.urlImageStatus[url];
            if(status !== ngc.EImageStatus.loading){
                delete ngc.urlImageStatus[url];
                cc.textureCache.removeTextureForKey(url);
            }
        }
    },

    replaceTextureUrl: function(node, url, eventName, data){
        var bCanLoad = false;
        if(node._curRepaceTx !== url){
            node._curRepaceTx = url;
            bCanLoad = true;
        } else {
            var status = ngc.urlImageStatus[url];
            if(status === undefined || ngc.EImageStatus.loadError){
                bCanLoad = true;
            }
        }
        if(!bCanLoad)
            return;

        var status = ngc.urlImageStatus[url];
        if(status === undefined || ngc.EImageStatus.loadError){
            status = ngc.EImageStatus.loading;
            ngc.urlImageStatus[url] = status;
        }

        if(status === ngc.EImageStatus.loadSuccess){
            var tx = cc.textureCache.getTextureForKey(url);
            if(tx){
                ngc.uiUtils.pDoImageLoadEvent(url, eventName, data, true, tx);
                return;
            } else {
                console.log(cc.formatStr("replaceTextureUrl status error url=%s ", url));
                status = ngc.EImageStatus.loading;
                ngc.urlImageStatus[url] = status;
            }
        }
        ngc.uiUtils.pCheckClearUrlCacheImage();

        cc.textureCache.addImageAsync(url, function(texture) {
            if(typeof texture === "string") {
                if(ngc.urlImageStatus[url] !== ngc.EImageStatus.loadSuccess)
                    ngc.urlImageStatus[url] = ngc.EImageStatus.loadError;
                ngc.uiUtils.pDoImageLoadEvent(url, eventName, data, false, null);
                return;
            }
            if ((!texture) || (!texture.getContentSize) || (texture.getContentSize().width == 0)) {
                // html5 加载失败会得到1个0像素的图
                if(texture){
                    cc.textureCache.removeTexture(texture);
                    if(ngc.urlImageStatus[url] !== ngc.EImageStatus.loadSuccess){
                        ngc.urlImageStatus[url] = ngc.EImageStatus.loadError;
                        node.setTexture(texture);
                        //ngc.uiUtils.pDoImageLoadEvent(url, eventName, data, false, null);
                        return;
                    }
                }
            }
            ngc.urlImageStatus[url] = ngc.EImageStatus.loadSuccess;
            node.setTexture(texture);

            //ngc.uiUtils.pDoImageLoadEvent(url, eventName, data, true, texture);
        }, null);
    },

    replaceGameTexture: function(node, txNameAlias){
        ngc.uiUtils.replaceTexture(node, ngc.game.pngRes[txNameAlias]);
    }
};

ngc.pubUtils ={
    trim: function(s){
        return s.replace(/^\s+|\s+$/g, "");
    },

    repeatStr: function(str, repeatCount){
        var retStr = "";
        for(var i = 0; i < repeatCount; ++i){
            retStr += str;
        }

        return retStr;
    },

    /**
     * @param iValue
     * @param fmtLen
     * @param isPrefixAdd
     * @returns {string}
     */
    int2StrFormat: function(iValue, fmtLen, isPrefixAdd){
        var prefixStr = "";
        if(iValue >= 0){
            if(isPrefixAdd)
                prefixStr = "+";
        } else {
            iValue = -iValue;
            prefixStr = "-";
        }

        var str = iValue.toString();
        if(str.length >= fmtLen)
            return prefixStr + str;

        return prefixStr + ngc.pubUtils.repeatStr("0", fmtLen - str.length) + str;
    },

    /**
     * ngc.pubUtils.int64ToStrFormatKWPicNum(-101450, 2, true, 10)
     * @param {Number} i64Value
     * @param {Number} maxDecimalLen
     * @param {Boolean} isPrefixAdd
     * @param {Number} kwMulti
     * @return {String}
     */
    int64ToStrFormatKWPicNum: function(i64Value, maxDecimalLen, isPrefixAdd, kwMulti){
        var prefixStr = "";
        if(i64Value >= 0){
            if(isPrefixAdd)
                prefixStr = "A";
        } else {
            i64Value = -i64Value;
            prefixStr = "_";
        }
        if(!kwMulti)
            kwMulti = 10;

        var str = "";
        var decimalDiv = 1;
        if(maxDecimalLen > 0)
            decimalDiv =  Math.pow(10, maxDecimalLen);
        if(i64Value >= kwMulti*10000){
            var iW = Math.round(i64Value * decimalDiv / 10000)/decimalDiv;
            str = iW.toString().replace(".", "D") + "W";
        } else if (i64Value >= kwMulti*1000){
            var iK = Math.round(i64Value * decimalDiv / 1000)/decimalDiv;
            str = iK.toString().replace(".", "D") + "K";
        } else {
            str = i64Value.toString();
        }

        return prefixStr + str;
    },

    getCurDateStr: function() {
        var now = new Date();
        return cc.formatStr("%d-%d-%d %d:%d:%d %d", now.getFullYear(), now.getMonth(), now.getDate(),
            now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds());
    },

    /**
     * 随机int，包括边界
     * @param {Number} min
     * @param {Number} max
     * @return {Number}
     */
    randomInt: function(min, max){
        if(min > max)
            min = max;

        // round(0,n) = [0, n]
        return  Math.round(Math.random() * (max - min)) + min;
    },

    maxTick: 2100000000,

    /**
     * @param {Number} curTick
     * @return {Number}
     */
    addTick: function(curTick) {
        ++curTick;
        if(curTick > this.maxTick)
            curTick = 1;
        return curTick;
    },

    /**
     * @param {Number} oldTick
     * @param {Number} newTick
     * @return {Number}
     */
    getTickDiff: function(oldTick, newTick){
        if(oldTick <= newTick)
            return (newTick - oldTick);
        else
            return (ngc.uiUtils.maxTick - oldTick + newTick);
    },

    /**
     * parse string to json object.
     * @param {String} strData
     * @returns {Object}
     */
    string2Obj: function(strData){
        try {
            return JSON.parse(strData);
        } catch (e) {
            ngc.log.error(cc.formatStr("string2Obj: %s", strData));
            return {};
        }
    },
    /**
     * serialize json object to string.
     * @param {Object} json
     * @returns {String}
     */
    obj2String: function(json) {
        try {
            return JSON.stringify(json);
        } catch (e) {
            ngc.log.info("obj2String error");
            return "";
        }
    },

    getLocalDataJson: function(key) {
        var data = cc.sys.localStorage.getItem(key);
        if(!data)
            return {};
        var json = ngc.pubUtils.string2Obj(data);
        if(json["version"] !== ngc.cfg.localStorageVersion){
            ngc.log.info("getLocalDataJson version changed");
            return {};
        }

        return json;
    },

    setLocalDataJson: function(key, json){
        if(ngc.cfg._testState) return;
        if(!json)
            json = {};

        json["version"] = ngc.cfg.localStorageVersion;
        cc.sys.localStorage.setItem(key, ngc.pubUtils.obj2String(json));
    },
};

ngc.httpUserData = cc.Class.extend({
    data: null,
    errorCode: 0,
    errorMsg: "",
    retStr: "",

    ctor: function(){
        this.data = {};
    }
});

ngc.http = {
    httpGet: function(url, cb){
        var xhr = cc.loader.getXMLHttpRequest();

        // Simple events 'loadstart', 'abort', 'error', 'load', 'loadend', 'timeout'
        ['abort', 'error', 'timeout'].forEach(function (eventname) {
            xhr["on" + eventname] = function () {
                cb(1, eventname);
            }
        });

        // Special event
        xhr.onreadystatechange = function () {
            if (xhr.readyState == 4 && (xhr.status >= 200 && xhr.status <= 207)) {
                var httpStatus = xhr.statusText;
                var response = xhr.responseText;

                cb(0, httpStatus, response);
            }

        };

        // 10 seconds for timeout
        xhr.timeout = 10*1000;

        //set arguments with <URL>?xxx=xxx&yyy=yyy
        xhr.open("GET", url, true);
        //xhr.setRequestHeader("Accept-Encoding","gzip,deflate");
        xhr.setRequestHeader("Content-Type","text/plain;charset=UTF-8");

        xhr.send();
    },

    postEvent: function(xEventName, xData, xErrorCode, xErrorMsg, xRetStr){
        var event = new cc.EventCustom(xEventName);
        var userData = new ngc.httpUserData();
        userData.data = xData;
        userData.errorCode = xErrorCode;
        userData.errorMsg = xErrorMsg;
        userData.retStr = xRetStr;
        event.setUserData(userData);

        // 如果 第二个参数设置成true，那么h5可以分发事件，win下事件丢失。
        cc.eventManager.dispatchEvent(event);
    },

    httpPost: function(url, header, timeOut, postData, postEventName, data){
        var xhr = cc.loader.getXMLHttpRequest();

        // Simple events 'loadstart', 'abort', 'error', 'load', 'loadend', 'timeout'
        ['abort', 'error', 'timeout'].forEach(function (eventname) {
            xhr["on" + eventname] = function () {
                ngc.http.postEvent(postEventName, data, 1, eventname, "");
            }
        });

        // Special event
        xhr.onreadystatechange = function () {
            if (xhr.readyState == 4 && (xhr.status >= 200 && xhr.status <= 207)) {
                var httpStatus = xhr.statusText;
                var response = xhr.responseText;

                //设置
                var setCookie = xhr.getResponseHeader("Set-Cookie");
                if(setCookie){
                    var sliceIndex = setCookie.indexOf(";");
                    setCookie = setCookie.substring(sliceIndex,0);
                    ngc.Cookie.cookie=setCookie;
                }

                ngc.http.postEvent(postEventName, data, 0, httpStatus, response);
            }
        };

        // 10 seconds for timeout
        xhr.timeout = timeOut;

        xhr.open("POST",url, true);
        xhr.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
        xhr.setRequestHeader("Cookie",ngc.Cookie.cookie);

        for(var name in header){
            xhr.setRequestHeader(name, header[name]);
        }

        // win下不支持send object
        if(postData.constructor === String)
            xhr.send(postData);
        else{
            var sendData = "";
            for(var name in postData){
                if(sendData.length === 0)
                 sendData += cc.formatStr("%s=%s", name, encodeURIComponent(postData[name]));
                else
                 sendData += cc.formatStr("&%s=%s", name, encodeURIComponent(postData[name]));
            }
            xhr.send(sendData);
        }
    },

    httpPostHs: function(subUrl, postData, postEventName, data){
        var strUUID = "";
        var json =  ngc.pubUtils.getLocalDataJson("Guuid");
        if(!json || !json["uuid"]){
            strUUID  = Math.uuid();
            ngc.pubUtils.setLocalDataJson("Guuid", {"uuid":strUUID});
        }
        else{
            strUUID = json["uuid"];
        }

        var header = {
            "os": cc.sys.os,
            "appKey":ngc.cfg.appkey,
            "appVersion": ngc.cfg.appVersion,
            "pver": ngc.cfg.pver,
            "smUserId": ngc.cfg.smUserId,
            "smPinYin": ngc.cfg.smPinYin,
            "userId": ngc.curUser.baseInfo.userId.toString(),
            "token": ngc.curUser.token,
            "gameId": ngc.curUser.gameId.toString(),
            "udid": strUUID
        };
        ngc.http.httpPost(ngc.cfg.urlHs + subUrl, header, 10*1000, postData, postEventName, data);
    },

    httpPostFs: function(fsUrl, postData, postEventName, data) {
        var strUUID = "";
        var json =  ngc.pubUtils.getLocalDataJson("Guuid");
        if(!json || !json["uuid"]){
            strUUID  = Math.uuid();
            ngc.pubUtils.setLocalDataJson("Guuid", {"uuid":strUUID});
        }
        else{
            strUUID = json["uuid"];
        }

        var header = {
            "os": cc.sys.os,
            "appKey":ngc.cfg.appkey,
            "appVersion": ngc.cfg.appVersion,
            "pver": ngc.cfg.pver,
            "smUserId": ngc.cfg.smUserId,
            "smPinYin": ngc.cfg.smPinYin,
            "userId": ngc.curUser.baseInfo.userId.toString(),
            "token": ngc.curUser.token,
            "gameId": ngc.curUser.gameId.toString(),
            "udid": strUUID
        };
        ngc.http.httpPost(fsUrl, header, 10*1000, postData, postEventName, data);
    }
};

// for reload _logList
ngc.logBufferAry = ngc.logBufferAry || [];

ngc.log = {
    //timerDoLog: function(){
    //    var len = ngc.logBufferAry.length;
    //    if(len < 1)
    //        return;
    //    var msg = ngc.logBufferAry.pop();
    //    ngc.http.httpGet(cc.formatStr("http://192.168.2.22:8900/?%s",  encodeURIComponent(msg)),
    //        function (errorCode, httpStatus, response) {
    //            // 这2个字符串如果+在一起，console日志出不来全部，httpStatus最后有个 String.fromCharCode(13)。
    //            // console.log("httpStatus7=" + httpStatus[6].charCodeAt()); win下 是 httpStatus7=13
    //            httpStatus = ngc.pubUtils.trim(httpStatus);
    //        });
    //},

    info: function(strMsg) {
        // to do 发布到公网需要去掉http的日志
        ngc.logBufferAry.unshift(cc.formatStr("[INFO ]%s[%s]", strMsg, ngc.pubUtils.getCurDateStr()));
        if(strMsg===undefined)
            console.log("undefined");
        else if(strMsg===null)
            console.log("null");
        else if(typeof strMsg == "string")
            console.log(strMsg);
        else
            console.log(JSON.stringify(strMsg).toString());
    },

    error: function(strMsg){
        // to do 发布到公网需要去掉http的日志
        //ngc.logBufferAry.unshift(cc.formatStr("[ERROR]%s[%s]", strMsg, ngc.pubUtils.getCurDateStr()));
        //
        //if(!cc.sys.isNative)
        //    console.error(strMsg);
        //else
        //    console.log("[ERROR]" + strMsg);
    }
};

var JsbBZ = JsbBZ || {};
JsbBZ.isWeiXinInstalled = true;
JsbBZ.isCalling = false;
JsbBZ.list = [];
JsbBZ.node = null;
JsbBZ.urlToNode={};

JsbBZ.loadHeadImage = function (Node, url, eventName, data) {
    if (!url)
        return;
    this.list.push({url: url, eventName: eventName, data: data});
    this.urlToNode[url.toString()]=Node;
    if (!this.isCalling) {
        this.isCalling = true;
        jsb.reflection.callStaticMethod("RootViewController", "loadHeadImage:", url);
    }
};

JsbBZ.callBack = function (path,url) {
    console.log("path = " + path);
    var tx = cc.textureCache.addImage(jsb.fileUtils.getWritablePath() + path);
    if (tx) {
        if(this.urlToNode[url.toString()]){
            if(cc.sys.isObjectValid(this.urlToNode[url.toString()]))
                this.urlToNode[url.toString()].setTexture(tx);
            delete this.urlToNode[url.toString()];
        }
    }
    this.list.splice(0, 1);
    if (this.list.length != 0) {
        jsb.reflection.callStaticMethod("RootViewController", "loadHeadImage:", this.list[0].url);
    } else {
        this.isCalling = false;
    }
};

JsbBZ.checkWeiXinInstalled = function () {
    if (cc.sys.os == cc.sys.OS_IOS) {
        JsbBZ.isWeiXinInstalled = jsb.reflection.callStaticMethod("NGCWeiXinAgent", "checkAppIsInstall:", "");
    } else {
        JsbBZ.isWeiXinInstalled = true;
    }
};


ngc.Cookie={
    cookie:"",
}

ngc.fileDownloader=function(remoateFiles,toLocalFiles,successCallBack,successCallBackTarget,failCallBack,failCallBackTarget){
    this._remoateFiles=remoateFiles;
    this._toLocalFiles=toLocalFiles;
    this._successCallBack=successCallBack;
    this._successCallBackTarget=successCallBackTarget;
    this._failCallBack=failCallBack;
    this._failCallBackTarget=failCallBackTarget;

    this._successNum=0;
    this._errorNum=0;

    this.startDownLoad();
}
ngc.fileDownloader.prototype.startDownLoad=function(){
    var self=this;

    for(var key=0 in this._remoateFiles){
        var loader=new ngcc.ngccGameDownloader("");
        loader.onSuccess=function(success){
            self.onOneSuccess();
        }
        loader.onError=function(errorcode,errorcodeInternal,errorStr){
            self.onOneError(errorcode,errorcodeInternal,errorStr);
        }
        loader.onProgress=function(bytesReceived,totalBytesReceived,totalBytesExpected){

        }

        loader.startDownloadFileAsync(this._remoateFiles[key],this._toLocalFiles[key]);
    }
}

ngc.fileDownloader.prototype.onOneSuccess=function(){
    if(++this._successNum==this._remoateFiles.length&&this._successCallBack){  //下载成功
        this._successCallBack.call(this._successCallBackTarget,this._toLocalFiles);
    }
}

ngc.fileDownloader.prototype.onOneError=function(errorcode,errorcodeInternal,errorStr){
    if(this._errorNum++==0&&this._failCallBack){
        this._failCallBack.call(this._failCallBackTarget);
    }
}

