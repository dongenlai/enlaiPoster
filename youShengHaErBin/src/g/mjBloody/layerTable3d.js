ngc.game.layer.table3d=cc.Layer.extend({
    dirPos:null,
    selfDir:SitDir.EAST,           //自己面朝的方向
    firstP:0,                      //第一个出牌人的位置
    grabP:0,                       //从哪个人的位置开始抓牌
    grabPFromIndex:0,              //从哪个人的位置开始抓牌

    standardMJNumInOneDir:34,      //每个人面前的牌堆的麻将牌标准数量
    maxDicePoint:1,                //骰子的点数较大的一个
    minDicePoint:1,                //骰子的点数较小的一个

    mjCards:null,                  //牌堆上所有的麻将
    mjCardWidth:ngc.game.mjModelWidth,             //麻将牌宽

    tableNumLable: null,
    _currentPaiNum: 0,
    diceObj:null,
    lastIndexInPos:null,

    _scaleFlag: false,

    ctor:function () {
        this._super();

        this.mjCards=[];
        this.tableNumLable=null;
    },

    isScaleCards: function (flag) {
        this._scaleFlag = flag;
        this.mjCardWidth = this._scaleFlag ? ngc.game.mjModelWidth - 1 : this.mjCardWidth;
    },

    initPos:function(){
        if (this._scaleFlag) {
            this.dirPos=[
                cc.math.vec3(-10806, cc.winSize.height/2-320, -78),
                cc.math.vec3(cc.winSize.width/2-143, cc.winSize.height/2-320, -20083),
                cc.math.vec3(-10538, cc.winSize.height/2-320, -364),
                cc.math.vec3(cc.winSize.width/2+148, cc.winSize.height/2-320, -20352)
            ];
        } else {
            this.dirPos=[
                cc.math.vec3(-10816, cc.winSize.height/2-320, -78),
                cc.math.vec3(cc.winSize.width/2-143, cc.winSize.height/2-320, -20070),
                cc.math.vec3(-10527, cc.winSize.height/2-320, -364),
                cc.math.vec3(cc.winSize.width/2+148, cc.winSize.height/2-320, -20354)
            ];
        }
    },

    onEnter:function(){
        this._super();
    },

    setSelfDir:function(dir){
        this.dir=dir;
    },

    getHandObj:function(){
        return this._handObj;
    },

    setDicePoint:function(firstP,grabP,dice1,dice2){
        this.firstP=firstP;
        this.maxDicePoint=Math.max(dice1,dice2);
        this.minDicePoint=Math.min(dice1,dice2);

        this.grabP= grabP;
    },

    minusMJCardByNum:function(num){
        if(this.mjCards.length >= num){
            while(num > 0){
                var mjCard = this.mjCards.shift();
                if(mjCard)
                    mjCard.removeFromParent(true);
                num--;
            }
        }
        var mJNum = ngc.g_mainScene.table2d._mJNum;
        if(mJNum)
            mJNum.setString("剩" + this.mjCards.length + "张");
    },

    initMJCards: function(allCards, leftCards) {
        this.initPos();
        this.grabPFromIndex = leftCards[this.grabP] || 0;
        var dirPos = this.dirPos;
        var mjCardWidth = this.mjCardWidth;
        var mjNum = ngc.g_mainScene.table2d._mJNum;
        var garbP = this.grabP;

        for(var i = 0; i < 4; i++){
            var index = (garbP + i) % 4;
            var cardNum = allCards[index];
            this._currentPaiNum += cardNum;
            var gap = Math.ceil(this.standardMJNumInOneDir/2) - Math.ceil(cardNum/2);
            if(index == 0)
                dirPos[0].x += gap / 2 * mjCardWidth;
            else if(index == 1)
                dirPos[1].z -= gap / 2 * mjCardWidth;
            else if(index == 2)
                dirPos[2].x -= gap / 2 * mjCardWidth;
            else if(index == 3)
                dirPos[3].z += gap / 2 * mjCardWidth;

            var j = 1;
            if (index == this.grabP) {
                j = this.grabPFromIndex + 1;
            }

            //显示剩余牌的数量
            if(i == 3) {
                if(mjNum)
                    mjNum.setString("剩" + this._currentPaiNum + "张");
                this._currentPaiNum = 0;
            }

            for(j; j <= cardNum; j++){
                this.generateOneMJCard(index, j);
            }
        }
        if(this.grabPFromIndex%2==1){this.grabPFromIndex++;}
        for(var k = 1, length = this.grabPFromIndex; k <= length; k ++){
            this.generateOneMJCard(this.grabP, k);
        }
        this.lastIndexInPos = i-2;
        this.setCameraMask(2);
    },

    getPosIndir:function(posTemplate,index,dirIndex){
        var gap=dirIndex<2?-this.mjCardWidth:this.mjCardWidth;
        var newPos=cc.math.vec3(posTemplate.x,posTemplate.y,posTemplate.z);
        if(index%2==1){
            newPos.y+=10;
        }
        index=Math.ceil(index/2);
        if(newPos.x<0){
            if(newPos.x<-10000&&newPos.x>-20000)
                newPos.x=Math.abs(newPos.x%-10000)+index*gap;
            else
                newPos.x=newPos.x%-20000+index*gap;
        }
        else if(newPos.y<0){
            if(newPos.y<-10000&&newPos.y>-20000)
                newPos.y=Math.abs(newPos.y%-10000)+index*gap;
            else
                newPos.y=newPos.y%-20000+index*gap;
        }
        else if(newPos.z<0){
            if(newPos.z<-10000&&newPos.z>-20000)
                newPos.z=Math.abs(newPos.z%-10000)+index*gap;
            else
                newPos.z=newPos.z%-20000+index*gap;
        }
        return newPos;
    },



    generateOneMJCard:function(dirIndex, indexInPos){
        var sprite = ngc.game.createMj(dirIndex,MJCardClass.QIANG);
        var pos3d = this.getPosIndir(this.dirPos[dirIndex], indexInPos, dirIndex);
        sprite.setPosition3D(pos3d);
        this.addChild(sprite);
        this.mjCards.push(sprite);
    },
    //
    // getPosIndir:function(posTemplate, index, dirIndex){
    //     var gap=dirIndex<2?-this.mjCardWidth:this.mjCardWidth;
    //     var newPos=cc.math.vec3(posTemplate.x,posTemplate.y,posTemplate.z);
    //     if(index%2==1){
    //         newPos.y+=10;
    //     }
    //     index=Math.ceil(index/2);
    //     if(newPos.x<0){
    //         if(newPos.x<-10000&&newPos.x>-20000)
    //             newPos.x=Math.abs(newPos.x%-10000)+index*gap;
    //         else
    //             newPos.x=newPos.x%-20000+index*gap;
    //     }
    //     else if(newPos.y<0){
    //         if(newPos.y<-10000&&newPos.y>-20000)
    //             newPos.y=Math.abs(newPos.y%-10000)+index*gap;
    //         else
    //             newPos.y=newPos.y%-20000+index*gap;
    //     }
    //     else if(newPos.z<0){
    //         if(newPos.z<-10000&&newPos.z>-20000)
    //             newPos.z=Math.abs(newPos.z%-10000)+index*gap;
    //         else
    //             newPos.z=newPos.z%-20000+index*gap;
    //     }
    //     return newPos;
    // },
    //打骰子动画
    showBeginAni:function(callBack,target,pack){
        var scene=this.getParent();
        var player = scene.getPlayerBySIndex(pack.bankerP);
        player.get3DPart().showDiceHandAni(function(){
            callBack.call(target, this.firstP);
        }, this);
    },

    //显示房间号
    showTableNum:function(tableNum){
        if(!this.tableNumLable){
            var label3D=new jsb.Sprite3D();
            var label=new cc.LabelTTF("房间号："+tableNum,"Arial",36);
            label3D.addChild(label);
            label3D.setPosition3D(cc.math.vec3(cc.winSize.width/2, cc.winSize.height/2-500, -464));
            label3D.setLightMask(cc.LightFlag.LIGHT3);
            label3D.setCameraMask(2);
            label3D.setScale(0.4);
            this.addChild(label3D);

            this.tableNumLable=label3D;
        }
    },
    removeAllCards:function(){
        this.mjCards=[];
        this.removeAllChildren(true);
        if(ngc.g_mainScene.table2d._mJNum)
            ngc.g_mainScene.table2d._mJNum.setString("剩" + this.mjCards.length + "张");
    },

    //摸宝
    moBaoAction:function(data){
        ngc.log.info("摸宝");
        this.minusMJCardByNum(1);

        ngc.g_mainScene.table2d.showBaoAni(true);
    }
});

