/**
 * Created by admin on 2016/9/13.
 */

ngc.game.layer.AboutLayer = ngc.CLayerBase.extend({
    ctor: function (tag) {
        this._flag = tag || false;
        this._super();
        this.myInit();
    },

    myInit: function () {
        this._super(ngc.hall.jsonRes.helpLayer, true);
        this.mySetVisible(true);
        this.onHaErBinRule();
    },

    initMjView:function (visible) {
        this._haHeiLongJiangBg.setVisible(!visible);
        this._haErBinBg.setVisible(visible);
    },

    onHeiLongJiangRule:function () {
        this.initMjView();
    },

    onHaErBinRule:function () {
        this.initMjView(true);
    },

    onEnter: function () {
        this._super();
        ngc.log.info("_flag: " + this._flag);

         if(this._flag == "protocol"){
             var webView = new ccui.WebView(ngc.cfg.protocolUrlN);
             webView.setContentSize(650, 370);
             webView.setPosition(667, 380);
             webView.setScalesPageToFit(true);
             window.webView = webView;
             this.addChild(webView);
         }else if(this._flag == "wanfa"){
             var webView = new ccui.WebView(ngc.cfg.ruleUrlN);
             webView.setContentSize(650, 370);
             webView.setPosition(667, 380);
             webView.setScalesPageToFit(true);
             window.webView = webView;
             this.addChild(webView);
         }else{

         }
    },

    onExit: function () {
        this._super();
    },

    onSure: function () {
        this.removeFromParent(true);
    },

    onBackGameScene: function () {
        this.removeFromParent(true);
    }
});
