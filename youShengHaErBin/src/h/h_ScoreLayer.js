/**
 * Created by dongenlai on 17/8/9.
 */

ngc.game.layer.scoreLayer = ngc.CLayerBase.extend({

    myInit: function () {
        this._super(ngc.hall.jsonRes.scoreLayer, true);
        this.mySetVisible(true);
    },

    onBackGameScene:function () {
        this.removeFromParent(true);
    },

})