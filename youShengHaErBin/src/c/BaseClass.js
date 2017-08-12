ngc.CNodeBase = cc.Node.extend({
    _loadInfo: null,

    myInit: function(jsonRes){
        var loadInfo = ngc.uiUtils.loadJson(this, jsonRes);
        this.addChild(loadInfo.node);
        this._loadInfo = loadInfo;

        this.mySetVisible(false);
    },

    myFinal: function(){
        ngc.uiUtils.stopAllActions(this);
    },

    mySetVisible: function(b){
        if(b && !this.isVisible())
            this.mySetVisibleTrue();
        else if(!b && this.isVisible())
            this.mySetVisibleFalse();
    },

    mySetVisibleTrue: function() {
        this.setVisible(true);
    },

    mySetVisibleFalse: function(){
        this.setVisible(false);
    },

    /**
     * @param {cc.Point} pos
     */
    myOnTouchBegan: function(pos){
        var r = cc.rect(0, 0, this.width, this.height);

        if (cc.rectContainsPoint(r, pos))
            return true;
        else
            return false;
    },

    myGetRect: function(){
        return cc.rect(this.getPositionX(), this.getPositionY(), this.width, this.height);
    }
});

ngc.CLayerBase = cc.Layer.extend({
    _loadInfo: null,
    _listenerShield: null,
    _shieldTouch: false,
    _timeLine:null,

    myInit: function(jsonRes, shieldTouch){
        if(shieldTouch)
            this._shieldTouch = true;

        var loadInfo = ngc.uiUtils.loadJson(this, jsonRes);
        this.addChild(loadInfo.node);
        this._loadInfo = loadInfo;
        this._timeLine=loadInfo.action;

        this.mySetVisible(false);
    },

    myFinal: function(){
        ngc.uiUtils.stopAllActions(this);
    },

    mySetVisible: function(b){
        if(b && !this.isVisible())
            this.mySetVisibleTrue();
        else if(!b && this.isVisible())
            this.mySetVisibleFalse();
    },

    mySetVisibleTrue: function(swallowState) {
        ngc.uiUtils.setShieldTouch(this, this._shieldTouch, swallowState);
        this.setVisible(true);
    },

    mySetVisibleFalse: function(){
        this.setVisible(false);
        ngc.uiUtils.setShieldTouch(this, false);
    },

    onBtnCloseClick: function(sender){
        ngc.g_mainScene.closeCurLayer();
    },

    onBtnCloseSelfClick: function (sender) {
        ngc.uiUtils.setShieldTouch(this, false);
        this.mySetVisibleFalse();
        this.removeFromParent(true);
    },
});

ngc.CGameLayerBase = ngc.CLayerBase.extend({

    onFrameTick: function(curFrame){

    },

    onSecTick: function(curSec){

    },

    myInit: function(jsonRes){
        this._super(jsonRes, true);
    },

    isSelfGaming: function() {
        return false;
    },

    setPaused: function(isPause){

    },

    closeTopLayer: function() {
        return 0;
    }
});

ngc.CSceneBase = cc.Scene.extend({
    _loadInfo: null,
    _timeLine:null,
    myInit: function(jsonRes){
        var loadInfo = ngc.uiUtils.loadJson(this, jsonRes);
        this.addChild(loadInfo.node);
        this._loadInfo = loadInfo;
        this._timeLine=loadInfo.action;
    },

    myFinal: function(){

    }
});

ngc.poolList = {
    _list: {},

    pGetPool: function(poolName){
        var pool = ngc.poolList._list[poolName];
        if(!pool){
            pool = [];
            ngc.poolList._list[poolName] = pool;
        }

        return pool;
    },

    pIsNodeExists: function(pool, node){
        for(var i = 0; i < pool.length; ++i){
            if(pool[i] === node)
                return true;
        }

        return false;
    },

    addNodeToPool: function(poolName, node){
        if(!node || poolName.length < 1)
        {
            ngc.log.error("AddNodeToPool param error");
            return;
        }
        var pool = ngc.poolList.pGetPool(poolName);
        if(ngc.poolList.pIsNodeExists(pool, node)){
            ngc.log.error("AddNodeToPool pIsNodeExists");
            return;
        }

        pool.push(node);
    },

    getNodeFromPool: function(poolName){
        var pool = ngc.poolList.pGetPool(poolName);
        if(pool.length < 1)
            return null;

        var node = pool.pop();
        return node;
    },

    clearPool: function(poolName){
        var pool = ngc.poolList.pGetPool(poolName);
        for(var i = 0; i < pool.length; ++i){
            var node = pool[i];
            node.release();
        }
    },

    clearPoolByPrefix: function(poolPrefix){
        var len = poolPrefix.length;

        var delNameList = [];
        for(var name in ngc.poolList._list){
            if(name.substr(0, len) === poolPrefix){
                ngc.poolList.clearPool(name);
                // 在clearPool中赋值 pool=[]影响不到_list
                delNameList.push(name);
            }
        }
        for(var i = 0; i < delNameList.length; ++i){
            delete ngc.poolList._list[delNameList[i]];
        }
    }

};