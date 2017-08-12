/**
 * Created by dongenlai on 17/8/9.
 */

ngc.game.layer.keFuLayer = ngc.CLayerBase.extend({
    _haErBinBtn:null,
    _heiLongJiangBtn:null,
    _haHeiLongJiangBg:null,
    _haErBinBg:null,
    _fanKuiPanel:null,
    _keFuText:null,
    _logo:null,
    _curTexture:null,

    myInit: function () {
        this._super(ngc.hall.jsonRes.keFuLayer, true);
        this.mySetVisible(true);
        this._curTexture = this._logo.getTexture();
        this.initMjView(true);
    },

    initMjView:function (visible) {
        this._haHeiLongJiangBg.setVisible(!visible);
        this._haErBinBg.setVisible(visible);
        this._fanKuiPanel.setVisible(!visible);
        this._keFuText.setVisible(visible);

        var file = visible ? this._curTexture: "res/hallUi/e/title2.png";
        this._logo.setTexture(file);
    },

    onYiJianFanKui:function () {
      this.initMjView();
    },

    onKeFuCallBack:function () {
        this.initMjView(true);
    },

    onBackGameScene:function () {
        this.removeFromParent(true);
    },

})