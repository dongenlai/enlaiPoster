cc.MoveByPull3DObj=cc.MoveBy.extend({
    _selfTarget:null,
    _pullTarget:null,
    ctor:function(duration, deltaPos, deltaY,selfTarget,pullTarget){
        this._super(duration,deltaPos,deltaY);
        this._selfTarget=selfTarget;
        this._pullTarget=pullTarget;
    },
    update:function(dt){
        var pos1=this._selfTarget.getPosition3D();
        this._super(dt);
        var pos2=this._selfTarget.getPosition3D();
        var gap=cc.math.vec3Sub(pos2,pos1);
        if(this._pullTarget){
            this._pullTarget.setPosition3D(cc.math.vec3Add(this._pullTarget.getPosition3D(),gap));
        }
    }
});
cc.moveByPull3DObj = function (duration, deltaPos, deltaY,selfTarget,pullTarget) {
    return new cc.MoveByPull3DObj(duration, deltaPos, deltaY,selfTarget,pullTarget);
};