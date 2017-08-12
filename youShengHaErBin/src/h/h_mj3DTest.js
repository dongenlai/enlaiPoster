ngc.hall.CSceneMain=cc.Scene.extend({
    ctor:function(){
        this._super();
        var layer= new ngc.hall.layerMain();
        this.addChild(layer);
    }
});

var SkinType = {
    UPPER_BODY : 0,
    PANTS : 1,
    SHOES : 2,
    HAIR : 3,
    FACE : 4,
    HAND : 5,
    GLASSES : 6,
    MAX_TYPE : 7
};

ngc.hall.layerMain = cc.Layer.extend({
    _curSkin:["Girl_UpperBody01", "Girl_LowerBody01", "Girl_Shoes01", "Girl_Hair01", "Girl_Face01", "Girl_Hand01", ""],
    _camera:null,
    _angle:0,
    _status:1,//////1:移动相机，2:旋转相机
    _itemMenu:null,
    ctor:function(){
        this._super();

        var sprite = new jsb.Sprite3D("res/g/mjBloody/obj/copy/");
        sprite.setPosition(cc.p(cc.winSize.width/2,cc.winSize.height/2-20));
        this.addChild(sprite);
        this._sprite=sprite;
        this._sprite.setCameraMask(2);

        //var animation = new jsb.Animation3D("res/h/shou.c3b");
        //if(animation){
        //    var animate = new jsb.Animate3D(animation);
        //    //sprite.runAction(cc.repeatForever(animate));
        //}
        //
        //
        //cc.textureCache.addImage("res/h/shou-nan.png");
        //cc.textureCache.addImage("res/h/zhijia.png");
        //
        //this._sprite.setTexture(cc.textureCache.getTextureForKey("res/h/shou-nan.png"));
        //this._sprite.setTexture(cc.textureCache.getTextureForKey("res/h/zhijia.png"));
        //ngc.log.info(this._sprite.getChildrenCount());
        //var a=this._sprite.getChildrenCount();
        //var chidren=this._sprite.getChildren();
        //for(var i=0;i<a;i++){
        //    var child = chidren[i];
        //    var subChilds=child.getChildren();
        //    for(var j=0;j<child.getChildrenCount();j++){
        //        var subChild=subChilds[j];
        //
        //        var mesh=subChild.getMeshByIndex(0);
        //        ngc.log.info(mesh.getName());
        //        if(mesh.getName()=="Object001"){
        //            mesh.setTexture(cc.textureCache.getTextureForKey("res/h/tile_me_12.png"));
        //        }
        //        //else{
        //        //    mesh.setTexture(cc.textureCache.getTextureForKey("res/h/majiang.png"));
        //        //
        //        //}
        //        //subChild.setTexture(cc.textureCache.getTextureForKey("res/h/majiang.png"));
        //        //var mesh = subChild.getMeshByIndex(0);
        //
        //    }
        //}
        //
        ////var material=cc.Material.createWithFilename("res/h/majiang.mtl");
        ////this._sprite.setMaterial(material);
        //
        //
        ////cc.textureCache.addImage("res/h/majiang.png");
        //////ngc.log.info(cc.textureCache.getTextureForKey("res/h/majiang.png"));
        ////this._sprite.setTexture(cc.textureCache.getTextureForKey("res/h/majiang.png"));
        //
        //
        ////var animation = new jsb.Animation3D(ngc.hall.res3D.girlReSkin);
        ////if(animation){
        ////    var animate = new jsb.Animate3D(animation);
        ////    sprite.runAction(cc.repeatForever(animate));
        ////}
        //
        this.applyCurSkin();
        //
        //cc.eventManager.addListener({
        //    event:cc.EventListener.TOUCH_ALL_AT_ONCE,
        //    onTouchesMoved:this.onTouchesMoved.bind(this)
        //}, this);
        //
        //
        //var textureCube = jsb.TextureCube.create("res/h/skybox/left.jpg","res/h/skybox/right.jpg", "res/h/skybox/top.jpg", "res/h/skybox/bottom.jpg", "res/h/skybox/front.jpg", "res/h/skybox/back.jpg");
        //
        ////set the texture parameters
        //textureCube.setTexParameters(gl.LINEAR, gl.LINEAR, gl.MIRRORED_REPEAT, gl.MIRRORED_REPEAT);
        //var skybox = jsb.Skybox.create();
        //skybox.setTexture(textureCube);
        //this.addChild(skybox);
        //
        //
        //
        var camera = new cc.Camera(cc.Camera.Mode.PERSPECTIVE, 60, cc.winSize.width/cc.winSize.height, 10, 1000);
        camera.setCameraFlag(cc.CameraFlag.USER1);
        camera.setPosition3D(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2+50, 50));
        camera.lookAt(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2, 0), cc.math.vec3(0, 1, 0));
        this._camera=camera;

        this.addChild(camera);
        this.setCameraMask(2);


        this._itemMenu = new cc.Menu();
        this._itemMenu.setContentSize(cc.winSize);
        this._itemMenu.ignoreAnchorPointForPosition(false);
        this._itemMenu.setPosition(cc.p(0,0));
        this._itemMenu.setAnchorPoint(cc.p(0,0));

        var label = new cc.LabelTTF("水平移动相机", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.changeStatus1, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(100,150));

        var label = new cc.LabelTTF("水平旋转相机", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.changeStatus2, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(100,200));

        var label = new cc.LabelTTF("拉近", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.zoomIn, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(50,250));

        var label = new cc.LabelTTF("拉远", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.zoomOut, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(50,300));

        var label = new cc.LabelTTF("进入2d", "Arial", 24);
        var menuItem = new cc.MenuItemLabel(label, this.enter2d, this);
        this._itemMenu.addChild(menuItem, 100);
        menuItem.setPosition(cc.p(50,350));

        this.addChild(this._itemMenu);
    },
    onEnter:function(){
        this._super();

        //this.enter2d();
    },
    applyCurSkin:function(){
        //var chidren=this._sprite.getChildren();
        //for(var i=0;i<chidren.length;i++){
        //    var child = chidren[i];
        //    var mesh=child.getMeshByIndex(0);
        //    var subChilds=child.getChildren();
        //    for(var j=0;j<child.getChildrenCount();j++){
        //        var subChild=subChilds[j];
        //        var mesh=subChild.getMeshByIndex(0);
        //        ngc.log.info(mesh.getName());
        //        if(mesh.getName()=="Object001"){
        //            mesh.setTexture(res);
        //            return;
        //        }
        //    }
        //}



        ngc.log.info("mesh num: "+this._sprite.getMeshCount());
        for(var i = 0; i < this._sprite.getMeshCount(); i++){
            var mesh = this._sprite.getMeshByIndex(i);
            var isVisible = false;
            ngc.log.info(mesh.getName());
            mesh.setVisible(true);
            //for(var j = 0; j < SkinType.MAX_TYPE; j++){
            //    if(mesh.getName() == this._curSkin[j]){
            //        isVisible = true;
            //        break;
            //    }
            //}
            //mesh.setVisible(isVisible);
            //if(mesh.getName()=="Girl_Shoes01"){
            //    if(cc.textureCache.getTextureForKey("res/h/Girl_Shoes02.png"))
            //    {
            //        mesh.setTexture(cc.textureCache.getTextureForKey("res/h/Girl_Shoes02.png"));
            //    }
            //    else{
            //        ngc.log.info("no");
            //    }
            //}
        }
    },
    onTouchesMoved:function(touches, event){
        if(touches.length > 0){
            var touch = touches[0];
            var delta = touch.getDelta();
            if(this._status==1){
                this._angle -= cc.degreesToRadians(delta.x);
                this._camera.setPosition3D(cc.math.vec3(cc.winSize.width/2 + 50*Math.sin(this._angle), cc.winSize.height/2+50, 50*Math.cos(this._angle)));
                this._camera.lookAt(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2, 0), cc.math.vec3(0, 1, 0));
            }
            else if(this._status==2){
                this._angle -= cc.degreesToRadians(delta.x)*10
                this._camera.setRotation3D(cc.math.vec3(0, this._angle, 0));
            }
        }
    },
    changeStatus1:function(){
        if(this._status==1) return;
        this._status=1;
        this._angle=0;

        this._camera.setPosition3D(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2+50, 50));
        this._camera.lookAt(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2+30, 0), cc.math.vec3(0, 1, 0));
    },
    changeStatus2:function(){
        if(this._status==2) return;
        this._status=2;
        this._angle=0;

        this._camera.setPosition3D(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2+50, 50));
        this._camera.lookAt(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2, 0), cc.math.vec3(0, 1, 0));
    },
    zoomIn:function(){
        var times=2;
        var cameraPos = this._camera.getPosition3D();
        var lookPos=cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2, 0);
        var lookDir = cc.math.vec3(cameraPos.x - lookPos.x, cameraPos.y - lookPos.y, cameraPos.z - lookPos.z);
        //if(cc.math.vec3Length(cameraPos) >= 50){
            var n = cc.math.vec3Normalize(lookDir);
            cameraPos.x -= n.x*times;
            cameraPos.y -= n.y*times;
            cameraPos.z -= n.z*times;
            this._camera.setPosition3D(cameraPos);
        //}
    },
    zoomOut:function(){
        var times=2;
        var cameraPos = this._camera.getPosition3D();
        var lookPos=cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2, 0);
        var lookDir = cc.math.vec3(cameraPos.x - lookPos.x, cameraPos.y - lookPos.y, cameraPos.z - lookPos.z);
        //if(cc.math.vec3Length(cameraPos) >= 50){
        var n = cc.math.vec3Normalize(lookDir);
        cameraPos.x += n.x*times;
        cameraPos.y += n.y*times;
        cameraPos.z += n.z*times;
        this._camera.setPosition3D(cameraPos);
        //}
    },
    enter2d:function(){
        var selft=this;
        cc.loader.loadJs(["src/g/mjBloody/resource.js"], function(err){
            ngc.game.resJs = "src/g/mjBloody/resource.js"
            if(err){
                self.clearGameRes();
                ngc.log.error("load js failed: " + gameInfo.resJs);
                return;
            }
            cc.loader.loadJs(ngc.game.jsFiles, function(err){
                if(err){
                    self.clearGameRes();
                    ngc.log.error("load js failed: ngc.game.jsFiles");
                    return;
                }
                var scene = new ngc.game.scene.main();
                cc.director.runScene(scene);
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

        this.doGarbageCollect();
        //this.scheduleOnce(this.doGarbageCollect, 0.5);
    }
})