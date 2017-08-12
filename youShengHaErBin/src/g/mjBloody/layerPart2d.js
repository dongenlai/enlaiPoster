ngc.game.playerpart2d=cc.Layer.extend({
    _isSelf:false,
    _playerIndex:0,

    aniLayer:null,

    player:null,
    scene:null,
    hupaiPrompt:null,

    curState:null,
    toStates:null,

    ctor: function() {
        this._super();
        this.scene=null;
        this.hupaiPrompt=null;
        this.toStates=[];
    },

    setState:function(state){
        this.curState = state;
        var packData = state.packData;
        switch (state.state){
            case PlayerState.NONE:
                break;
            case PlayerState.XUANPAIING:
                if(this._playerIndex==0)
                    this.showXUANPAISelf();
                else
                    this.showXUANPAIOther();
                break;
            case PlayerState.XUANPAISHOW:
                if(this._playerIndex!=0){
                    this.hideTip();
                }
                else{
                    this.removeXUANPAIESelf();
                }
                break;
            case PlayerState.DINGQUEING:
                if(this._playerIndex==0) {
                    this.showDINGQUESelf();
                }
                else{
                    this.showDINGQUEOther();
                }
                break;
            case PlayerState.MOPAISHOW:
                if(this._playerIndex==0&&packData){
                    this.scene.table2d.showDiscardTipDelay();

                    if(packData.mjAction.length<=0||(packData.mjAction.length==1&&packData.mjAction[0]["a"]==opServerActionCodes.mjaChu)){
                        this.removeOpSelectionSelf();
                        break;
                    }
                    this.scheduleOnce(function(){
                        this.setState(new PlayerStateData(PlayerState.YAOPAIING,packData));
                    },0.4);
                    if(packData.mjAction.length>0){
                        this.scheduleOnce(function(){
                            this.parseAndSetTingPai(packData.mjAction);
                        },0.1);
                    }
                }
                break;
            case PlayerState.YAOPAIING:

                if(this._playerIndex == 0 && packData && packData.mjAction.length > 0){
                    this.showOpSelectionSelf(packData.mjAction);
                    if(packData.decTimeCount!=undefined&&packData.decTimeCount>0){
                        this.scene.table2d.setNormalCount(packData.decTimeCount,0);
                    }
                }
                break;
            case PlayerState.CHUPAISHOW:
                var player=this.scene.getPlayerByCIndex(0);
                player.layerPart2d.removeOpSelectionSelf();
                if(this._playerIndex!=0){
                    if(packData){
                        if(packData.mjAction.length>0 && !(packData.mjAction.length == 1 && packData.mjAction[0]["a"] == opServerActionCodes.mjaMo)){
                            this.scheduleOnce(function(){
                                player.setState(new PlayerStateData(PlayerState.YAOPAIING,packData));
                            },0.8);
                        }
                    }
                }
                if(this._playerIndex==0){
                    this.scene.table2d.hideDiscardTip();
                }
                this.hideHuPaiPrompt();
                break;
            case PlayerState.DINGQUESHOW:
                if(this._playerIndex!=0){
                    this.hideTip();
                }
                else{
                    this.removeDINGQUESelf();
                }
                this.showDingQUERSAni(packData);
                break;
            case PlayerState.YAPPAISHOW:
                if(packData && packData.card != undefined){
                    var table2d=this.scene.getTable2D();
                    table2d.showOPRSAni(this._playerIndex, packData.action);
                }
                var player=this.scene.getPlayerByCIndex(0);
                player.layerPart2d.removeOpSelectionSelf();
                if(this._playerIndex==0&&packData.mjAction.length>0&&!(packData.mjAction.length==1&&packData.mjAction[0]["a"]==opServerActionCodes.mjaMo)){
                    player.setState(new PlayerStateData(PlayerState.YAOPAIING,packData));
                }
                if(this._playerIndex==0)
                    this.scene.table2d.showDiscardTipDelay();
                if(packData.mjAction.length>0){
                    this.scheduleOnce(function(){
                        this.parseAndSetTingPai(packData.mjAction);
                    },0.5);
                }
                break;
            case PlayerState.HUPAISHOW:
                this.refreshPlayerScores(packData);

                if(packData&&packData.card!=undefined){
                    var table2d=this.scene.getTable2D();
                    table2d.showOPRSAni(this._playerIndex,opServerActionCodes.mjaHu,packData.isZiMo);
                }

                var player=this.scene.getPlayerByCIndex(0);
                player.layerPart2d.removeOpSelectionSelf();

                var selfHu=false;
                if(this._playerIndex!=0&&packData.mjAction.length>0){
                    for(var key=0 in packData.mjAction){
                        if(packData.mjAction[key]["a"]==opServerActionCodes.mjaHu){
                            selfHu=true;
                            break;
                        }
                    }
                }
                if(selfHu){
                    player.setState(new PlayerStateData(PlayerState.YAOPAIING,packData));
                }

                this.hideHuPaiPrompt();
                break;
            default:

                break;
        }
    },
    setSelf:function(){
        this._isSelf=true;
    },
    setScene:function(scene){
        this.scene=scene;
    },
    setPlayerIndex:function(index){
        this._playerIndex=index;
        if(this._playerIndex==0){
            ///胡牌提示框
            var layer = new ngc.game.hupaiprompt();
            layer.myInit();
            this.addChild(layer);
            this.hupaiPrompt=layer;
        }
    },
    setPlayer:function(player){
        this.player=player;
    },
    update:function(dt){
        if(this.toStates.length>0){
            this.curState=this.toStates.shift();
            var packData=this.curState.packData;


        }
    },

    showXUANPAISelf:function(){
        var table2d=this.scene.getTable2D();
        if(table2d){
            var layer=new ngc.game.opswap();
            layer.myInit();
            table2d.addChild(layer,0,11111);
        }
    },

    removeXUANPAIESelf:function(){
        var table2d=this.scene.getTable2D();
        if(table2d){
            table2d.removeChildByTag(11111);
        }
    },

    showXUANPAIOther:function(){
        var table2d=this.scene.getTable2D();
        table2d.showXPTip(this._playerIndex);
    },
    hideTip:function(){
        var table2d=this.scene.getTable2D();
        table2d.hideTip(this._playerIndex);
    },

    showDINGQUESelf:function(){
        var table2d=this.scene.getTable2D();
        if(table2d){
            var suggestedCardType=CardType.WAN;
            if(this.player) suggestedCardType=this.player.getSuggestedCardType();
            var layer=new ngc.game.oplack();
            layer.myInit(suggestedCardType);
            table2d.addChild(layer,0,11112);
        }
    },
    removeDINGQUESelf:function(){
        var table2d=this.scene.getTable2D();
        if(table2d){
            table2d.removeChildByTag(11112);
        }
    },
    showDINGQUEOther:function(){
        var table2d=this.scene.getTable2D();
        table2d.showDQTip(this._playerIndex);
    },

    showDingQUERSAni:function(packData){
        var cardType=CardType.WAN;
        if(packData){
            if(this._playerIndex==0)
                cardType=packData.U0;
            else if(this._playerIndex==1)
                cardType=packData.U1;
            else if(this._playerIndex==2)
                cardType=packData.U2;
            else if(this._playerIndex==3)
                cardType=packData.U3;
        }
        else if(this._playerIndex==0){
            cardType=this.getTempLackCardType();
        }
        var table2d=this.scene.getTable2D();
        table2d.showDQRSAni(this._playerIndex,cardType);
    },

    showOtherCZ:function(){
        var table2d=this.scene.getTable2D();
        table2d.showOtherCZ(this._playerIndex);
    },

    setTempLackCardType:function(cardType){
        this.tempLackCardType=cardType;
    },
    getTempLackCardType:function(){
        var tem=this.tempLackCardType;
        this.tempLackCardType=null;
        return tem;
    },

    //吃碰胡...
    showOpSelectionSelf:function(actions){
        this.removeOpSelectionSelf();
        var table2d=this.scene.getTable2D();
        if(table2d){
            var layer=new ngc.game.opaction();
            if(layer.myInit(actions)){
                layer.setDelegate(this);
                table2d.addChild(layer,0,11113);
            }
        }
    },
    removeOpSelectionSelf:function(){
        var table2d=this.scene.getTable2D();
        if(table2d){
            table2d.removeChildByTag(11113);
        }
    },

    refreshPlayerScores:function(pack){
        if(pack.scores&&pack.scores.length>0){
            var table2d=this.scene.getTable2D();

            for(var key=0 in pack.scores){
                var player=this.scene.getPlayerBySIndex(parseInt(key));
                if(player){
                    var nowScore=player.getFromToRefresh();
                    if(nowScore==undefined)
                        nowScore=pack.scores[key];

                    var oldScore=player.getScore();
                    player.setScore(nowScore);
                    if(nowScore-oldScore!=0)
                        table2d.showScoresAni(player.getPlayerIndex(),nowScore-oldScore,1.5);
                }
            }
        }

        //var playerWin=this.scene.getPlayerBySIndex(pack.pos);
        //var playerScore=playerWin.getScore();
        //playerWin.setScore(playerScore+pack.scores);
        //table2d.showScoresAni(playerWin.getPlayerIndex(),pack.scores,1.5);
        //if(pack.isZiMo){
        //    for(var i=0;i<=3;i++){
        //        var playerLost=this.scene.getPlayerBySIndex(i);
        //        if(playerLost.getPlayerIndex()!=playerWin.getPlayerIndex()){
        //            playerScore=playerLost.getScore();
        //            playerLost.setScore(playerScore-pack.scores);
        //
        //            table2d.showScoresAni(playerLost.getPlayerIndex(),-pack.scores,1.5);
        //        }
        //    }
        //}
        //else{
        //    var playerLost=this.scene.getPlayerBySIndex(pack.lpos);//点炮玩家
        //    playerScore=playerLost.getScore();
        //    playerLost.setScore(playerScore-pack.scores);
        //
        //    table2d.showScoresAni(playerLost.getPlayerIndex(),-pack.scores,1.5);
        //}
    },

    clearCards:function(){
        this.toStates=[];
        //this.curState.state=PlayerState.NONE;

        if(this._playerIndex==0){
            this.removeDINGQUESelf();
            this.removeOpSelectionSelf();
            this.removeXUANPAIESelf();
        }
    },

    //解析听牌
    parseAndSetTingPai:function(packData){
        ngc.log.info("parseAndSetTingPai");
        var tingPaiData={};
        for(var key=0 in packData){
            if(packData[key]["a"]==opServerActionCodes.mjaTing){
                var paiData=packData[key]["e"].split(":");
                var chupai=paiData[0];
                tingPaiData[chupai]=tingPaiData[chupai]||[];

                var hupais=paiData[1].split(",");
                for(var i=0 in hupais){
                    var one=hupais[i].split("^");
                    tingPaiData[chupai].push(this.genhupaiData(one[0],one[1],one[2]));
                }
            }else if(packData[key]["a"]==opServerActionCodes.mjaTingChi||packData[key]["a"]==opServerActionCodes.mjaTingPeng){
                var paiData=packData[key]["e"].split(":");
                var chupai=paiData[1];
                tingPaiData[chupai]=tingPaiData[chupai]||[];

                var hupais=paiData[2].split(",");
                for(var i=0 in hupais){
                    var one=hupais[i].split("^");
                    tingPaiData[chupai].push(this.genhupaiData(one[0],one[1],one[2]));
                }
            }
        }
        this.scheduleOnce(function(){
            this.showHuPaiPrompt(tingPaiData);
        },0.5);
    },

    genhupaiData:function(hu,fan,num){
        return {"hu":hu,"fan":fan, "lnum":num};
    },
    showHuPaiPrompt:function(tingPaiData){
        if(!this.hupaiPrompt){
            var layer=new ngc.game.hupaiprompt();
            layer.myInit();
            this.addChild(layer);
            this.hupaiPrompt=layer;
        }
        this.hupaiPrompt.setData(tingPaiData);
        var cards=this.player.getCardsByIndex(0);
        var children3D=this.player.layerPart3d.layerCard1.getChildren();
        this.hupaiPrompt.showDirector(cards,children3D,this.scene);
    },
    showHuPaiCon:function(cardValue,mjCard){
        if(this.hupaiPrompt&&cardValue!=undefined){
            if(this.hupaiPrompt.hasHuPai())
                this.hupaiPrompt.showHuPai(cardValue,mjCard,this.scene);
        }
    },
    hideHuPaiPrompt:function(){
        if(this.hupaiPrompt){
            this.hupaiPrompt.setVisible(false);
            this.hupaiPrompt.clearInfo();
        }
    }
});