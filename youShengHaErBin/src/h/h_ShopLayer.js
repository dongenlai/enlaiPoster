/**
 * Created by dongenlai on 17/8/9.
 */

ngc.game.layer.shopLayer = ngc.CLayerBase.extend({

    myInit: function () {
        this._super(ngc.hall.jsonRes.shopLayer, true);
        this.mySetVisible(true);
    },

    onClose:function () {
        this.removeFromParent(true);
    },

})