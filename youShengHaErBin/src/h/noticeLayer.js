/**
 * Created by ngc on 2016/11/15.
 */

ngc.game.layer.NoticeLayer = ngc.CLayerBase.extend({

    _text: null,
    _customEventName: "layerBulletin",
    _listView:null,

    ctor: function (bullentId) {
        this._super();
        this.myInit(bullentId);
    },

    myInit: function (bullentId) {
        this._super(ngc.hall.jsonRes.noticeLayer, true);
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

        this.getData(bullentId);
    },

    onEnter: function () {
        this._super();
    },

    onHttpEvent: function (userData) {
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        if (retJson["response"] !== 1) {
            return;
        }

        if (userData.data == "getNormalNotifcation"){
            retJson.content=retJson.content.replace(/\\n/g, "\n");
            this._text.string = retJson.content;
        }
    },

    getData: function (bulletinID) {
        var postData = { "bulletinId": bulletinID };
        ngc.http.httpPostHs("/interface/mic_bulletinDetail.do", postData, this._customEventName, "getNormalNotifcation");
    },

    onExit: function () {
        this._super();
    },

    onClose: function () {
        this.removeFromParent(true);
    }
});