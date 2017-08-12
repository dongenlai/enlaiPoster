/**
 * Created by dongenlai on 17/8/9.
 */

ngc.game.layer.sportLayer = ngc.CLayerBase.extend({

    myInit: function () {
        this._super(ngc.hall.jsonRes.sportLayer, true);
        this.mySetVisible(true);
    },

    onClose:function () {
        this.removeFromParent(true);
    },

})