var ShareBZ = ShareBZ || {};
ShareBZ.isDoSharing = false; //是否正在分享操作中，避免重复操作
ShareBZ.cb = null;
ShareBZ.t = null;
/**
 * 分享入口方法
 * 字符串参数如果没有的就传空字符串
 * @param {int} channel 分享渠道,目前只有微信(为1)
 * @param {int} sharePoint 分享点，要与服务端设置相对应，不同的分享点分享奖励不一样
 * @param {String} pathName 分享图片的本地路径
 * @param {String} title 分享标题
 * @param {String} url 分享的url地址
 * @param {String} description 分享的具体描述
 * @param {int} 分享方式,对于微信而言 0:分享到微信好友，1：分享到微信朋友圈
 * @param {Function} 分享结果的回调方法,参数为channel(渠道),sharePoint(分享点),shareResult(分享结果),awardBean(奖励的游戏豆)
 */
ShareBZ.doShare = function (channel, sharePoint, pathName, title, url, description, flag, cb) {
    if (ShareBZ.isDoSharing) return;
    ShareBZ.cb = cb;
    ShareBZ.isDoSharing = true;
    ShareBZ.t = setTimeout(function () {
        ShareBZ.isDoSharing = false;
    }, 2000);
    if (cc.sys.os == cc.sys.OS_ANDROID) {
        jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "doShare", "(IIILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V",
            ngc.curUser.gameId, channel, sharePoint, pathName, title, url, description, flag);
    }
    if (cc.sys.os == cc.sys.OS_IOS) {
        jsb.reflection.callStaticMethod("NGCWeiXinAgent", "doShare:channel:sharePoint:pathName:title:url:description:flag:", ngc.curUser.gameId, channel, sharePoint, pathName, title, url, description, flag);
    }

};

ShareBZ.doShareWithText = function (channel, sharePoint, text, flag, cb) {
    if (ShareBZ.isDoSharing) return;
    ShareBZ.cb = cb;
    ShareBZ.isDoSharing = true;
    ShareBZ.t = setTimeout(function () {
        ShareBZ.isDoSharing = false;
    }, 2000);
    if (cc.sys.os == cc.sys.OS_ANDROID) {
        jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", "doShareWithText", "(IILjava/lang/String;I)V",
            ngc.curUser.gameId, channel, text, flag);
    } else if (cc.sys.os == cc.sys.OS_IOS) {
        jsb.reflection.callStaticMethod("WXApiRequestHandler", "sendText:InScene:", text, 0);
    }
};

/**
 * 供原生代码调用的分享结果回调
 * @param {int} channel
 * @param {int} sharePoint
 * @param {long} t
 * @param {int} shareResult 分享结果 0失败,1成功,2取消
 * @param {String} 校验码，服务端据此判定上报的安全性
 */
ShareBZ.onResult = function (channel, sharePoint, t, shareResult, key) {
    console.log("ShareBZ.onResult");
    if (ShareBZ.t) clearTimeout(ShareBZ.t);
    ShareBZ.isDoSharing = false;
    if (ShareBZ.cb) ShareBZ.cb(channel, sharePoint, shareResult, 0);
    if (sharePoint == 0)//0的时候为邀请分享 不连接服务器
        return;
   // var postData = {"channel": channel, "sharePoint": sharePoint, "t": t, "result": shareResult, "key": key};
  //  ngc.http.httpPostHs("/interface/user_shareResult.do", postData, "freeCoin", "shareResult");


};