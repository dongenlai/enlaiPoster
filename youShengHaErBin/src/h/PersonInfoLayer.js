/**
 * Created by admin on 2016/8/19.
 */

ngc.game.layer.PersonInfoLayer = ngc.CLayerBase.extend({
    _headIcon: null,
    _volumeNum: null,
    _cardNum: null,
    _nameTxt: null,
    _sexTxt: null,
    _userIdTxt: null,
    _typeTxt: null,
    _customEventListenerUrlImage:null,
    _customEventNameUrlImage: "urlImageSceneMain",

    onEnter: function () {
        this._super();
        //this._volumeNum.string = "";          // 这个卷不知道是什么
        this._cardNum.string = ngc.curUser.baseInfo.specialGold;
        this._nameTxt.string = ngc.curUser.baseInfo.nickName;
        this._sexTxt.string = (ngc.curUser.baseInfo.sex == 1) ? "男" : "女";
        this._userIdTxt.string = ngc.curUser.baseInfo.userId;
        this._typeTxt.string = (ngc.curUser.baseInfo.userType == 0) ? "游客用户" : "手机用户";
        this.onChangeIcon();
    },

    onExit: function () {
        this._super();
    },

     myInit: function () {
        this._super(ngc.hall.jsonRes.personInfoLayer, true);
        this.mySetVisible(true);
    },

    onChangeIcon: function () {
        var user = ngc.curUser;
        var faceUrl = user.baseInfo.calcFaceUrl();
        if (faceUrl.length > 0) {
            this.loadFaceUrl(faceUrl);
        } else {
            var _file = "res/hallUi/a/head.png";
            this._headIcon.setTexture(_file);
        }

    },

    loadFaceUrl: function (url) {
        var data = {type: "selfFace"};
        if (cc.sys.os == cc.sys.OS_IOS) {//ios 头像无法载入bug暂行办法
            JsbBZ.loadHeadImage(this._headIcon, url, this._customEventNameUrlImage, data);
            return;
        }
        ngc.uiUtils.replaceTextureUrl(this._headIcon, url, this._customEventNameUrlImage, data);
    },

    onChangeLogin: function () {

    },

    onSureInfo: function () {

    },

    onAddVolume: function () {

    },

    onAddCard: function () {

    },

    onClose: function () {
        this.removeFromParent(true);
    }
});
