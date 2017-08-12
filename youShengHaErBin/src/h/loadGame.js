ngc.hall.SceneLoadGame=cc.Scene.extend({
    ctor:function(gameData){
        this._super();

        var layer=new ngc.hall.LayerLoadGame(gameData);
        layer.myInit();
        this.addChild(layer);

        if(cc.sys.os==cc.sys.OS_ANDROID){
            cc.eventManager.addListener({
                event: cc.EventListener.KEYBOARD,
                onKeyReleased: function(keyCode, event){
                    if(keyCode == cc.KEY.back){
                        var quitLayer=new ngc.game.layer.quit();
                        quitLayer.showInScene();
                    }
                }
            }, this);
        }
    }
});

ngc.hall.LayerLoadGame=ngc.CLayerBase.extend({
    _customEventName:"layerLoadGame",
    _layerNet:null,
    _gameData:null,
    _panelCon:null,
    ctor:function(gameData){
        this._super();
        this._gameData=gameData;
    },
    myInit : function(){
        this._super(ngc.hall.jsonRes.loadGame);
        this.mySetVisibleTrue();

        if(!this._customEventListener){
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

        var layerNet = new ngc.game.net(this.onNetMessage,this);
        this.addChild(layerNet);
        this._layerNet=layerNet;
        this._layerNet.setConnectFailedCallBack(this.enterFailed,this);
    },

    onEnter:function(){
        this._super();
        if(this._timeLine){
            this._timeLine.play("animation0",true);
        }
        this.afterLoginHs();
    },
    onHttpEvent:function(userData){
        ngc.log.info(userData);

        if(userData.errorCode !== 0){
            return;
        }
        var retJson = ngc.pubUtils.string2Obj(userData.retStr);
        ngc.log.info("-=-=-=--==-" + JSON.stringify(retJson))
        if(retJson["response"] !== 1){
            return;
        }
        switch (userData.data){
            case "login":
                this.afterLoginHs(retJson)
                break;
        }
    },
    enterFailed:function(){
        this._panelCon.setVisible(false);
        var sprite=new cc.Sprite("res/h/load/loading9.png");
        sprite.setPosition(cc.winSize.width/2,cc.winSize.height/2-100);
        this.addChild(sprite);
        this._layerNet.closeWs();
        this.scheduleOnce(function(){
            var mainScene = new ngc.game.scene.HallScene();
            cc.director.runScene(mainScene);
        },2);
    },
    afterLoginHs:function(retJson){
        //ngc.curUser.baseInfo.readFromJson(retJson);
        //ngc.curUser.access_token=retJson["access_token"];
        this._layerNet.connectWs();
        this.loadGameRes();
    },
    onNetMessage:function(actionId, data){
        switch(data.action) {
            case 0:
                this.loginGame();
                break;
            case game_msgId_rcv.LOGIN_RESP:
                if(data["code"]==0) {
                    this.afterLoginGame(data);
                } else {
                    ngc.log.info(data);
                    ngc.pubUtils.setLocalDataJson("eMjServerData", {"ip": null, "port": null});
                    this.enterFailed();
                }
                break;
        }
    },
    loginGame:function(){
        var loginPack=new game_pack_template_send.LOGIN();
        loginPack.accessToken=ngc.curUser.access_token;
        loginPack.mac="AA-BB";
        loginPack.whereFrom=2;
        loginPack.version=1;
        this._layerNet.sendData(loginPack);
    },
    afterLoginGame:function(data){
        var scene = new ngc.game.scene.main();
        cc.director.runScene(scene);
        this._layerNet.retain();
        this._layerNet.removeFromParent();
        scene.addNet(this._layerNet,this._gameData,data);
        this._layerNet.release();
        this._layerNet=null;
    },

    loadGameRes:function(){
        var self=this;
        if(ngc.game&&ngc.game.jsFiles) return;
        cc.loader.loadJs(["src/g/mjBloody/resource.js"], function(err){
            ngc.game.resJs = "src/g/mjBloody/resource.js"
            if(err){
                self.clearGameRes();
                return;
            }
            cc.loader.loadJs(ngc.game.jsFiles, function(err){
                if(err){
                    self.clearGameRes();
                    return;
                }
            });
        });
    },
    clearGameRes: function() {
        if(ngc.game.resources){
            for(var i = 0; i < ngc.game.resources.length; ++i){
                cc.loader.release(ngc.game.resources[i]);
            }
            ngc.game.resources = [];
        }
        if(ngc.game.pngRes){
            for(var name in ngc.game.pngRes){
                var png = ngc.game.pngRes[name];
                if(cc.textureCache.getTextureForKey(png)){
                    cc.loader.release(png);
                    cc.textureCache.removeTextureForKey(png);
                }
            }
            ngc.game.pngRes = {};
        }
        if(ngc.game.jsFiles){
            for(var i = 0; i < ngc.game.jsFiles.length; ++i)
                cc.sys.cleanScript(ngc.game.jsFiles[i]);
            ngc.game.jsFiles = [];
        }
        if(ngc.game.resJs){
            cc.sys.cleanScript(ngc.game.resJs);
        }

        cc.sys.garbageCollect();
    }
})