ngc.game.player=function(scene,dir,userInfo,ZScore,ip){
    this.scene=scene;
    this.dir=dir;
    this.playerIndex=0;
    this.userInfo=userInfo;
    this.score=ZScore;
    this.banker=0;
    this.ip=ip;

    this.toRefreshScoreArray=[];

    this.layerPart2d=new ngc.game.playerpart2d();
    this.layerPart3d=new ngc.game.playerpart3d();

    this.scene.addChild(this.layerPart2d);
    this.scene.addChild(this.layerPart3d);

    this.layerPart2d.setScene(this.scene);
    this.layerPart3d.setScene(this.scene);

    this.layerPart2d.setPlayer(this);
    this.layerPart3d.setPlayer(this);
    this.hasTing = 0;//0没听 1普通听 2吃听 3碰听
}

ngc.game.player.prototype.setState=function(state){
    this.layerPart2d.setState(state);
    this.layerPart3d.setState(state);
}
ngc.game.player.prototype.setSelf=function(){
    this.layerPart2d.setSelf();
    this.layerPart3d.setSelf();
}
ngc.game.player.prototype.get3DPart=function(){
    return this.layerPart3d;
}

ngc.game.player.prototype.setTempLackCardType=function(cardType){
    this.layerPart2d.setTempLackCardType(cardType);
}

ngc.game.player.prototype.parseAndSetTingPai=function(packData){
    this.layerPart2d.parseAndSetTingPai(packData);
}

ngc.game.player.prototype.setPlayerIndex=function(index){
    this.playerIndex=index;
    this.layerPart2d.setPlayerIndex(index);
    this.layerPart3d.setPlayerIndex(index);
}

ngc.game.player.prototype.getPlayerIndex=function(){
    return this.playerIndex;
}

ngc.game.player.prototype.refreshCardsInfo=function(serverTingIdx){
    this.layerPart3d.refreshCardsInfo(serverTingIdx);
}

ngc.game.player.prototype.addToCamera=function(cameraIndex){
    this.layerPart3d.setCameraMask(cameraIndex);
}


ngc.game.player.prototype.setTingState = function(state){
    this.hasTing = state;
};

ngc.game.player.prototype.getTingState = function(){
    return this.hasTing;
};

ngc.game.player.prototype.updateCards=function(cards,index,sort){
    this.layerPart3d.updateCards(cards,index,sort);
}

ngc.game.player.prototype.setAddedCards=function(cards){
    this.layerPart3d.setAddedCards(cards);
}

ngc.game.player.prototype.getSelectedCards=function(isValue){
    return this.layerPart3d.getSelectedCards(isValue);
}

ngc.game.player.prototype.getDarkCard=function(index,length){
    return this.layerPart3d.getDarkCard(index,length);
}

ngc.game.player.prototype.getCardsByIndex=function(index){
    return this.layerPart3d.getCardsByIndex(index);
}

ngc.game.player.prototype.receiveDealMjAni=function(num, isLastCard){
    this.layerPart3d.receiveDealMjAni(num, isLastCard);
}

ngc.game.player.prototype.movePointerToLastCard=function(){
    this.layerPart3d.movePointerToLastCard();
}

//摸牌动画
ngc.game.player.prototype.grabOneCardAni=function(){
    this.layerPart3d.grabOneCardAni();
}

//移除打出的牌
ngc.game.player.prototype.removeLastDiscard=function(card){
    this.layerPart3d.removeLastDiscard(card);
}

//检查打出的牌最后一张
ngc.game.player.prototype.getLastDiscardByValue=function(card){
    return this.layerPart3d.getLastDiscardByValue(card);
}

//将交换的牌放到桌上
ngc.game.player.prototype.putSelectedToSwap=function(){
    this.layerPart3d.putSelectedToSwap();
}

//定缺时的建议的花色
ngc.game.player.prototype.getSuggestedCardType=function(){
    return this.layerPart3d.getSuggestedCardType();
}

ngc.game.player.prototype.setScore=function(score){
    this.score=score;
    this.scene.table2d.refreshScore(this.playerIndex,this.score);
}
ngc.game.player.prototype.getScore=function(){
    return this.score;
}
ngc.game.player.prototype.pushToRefresh=function(score){
    this.toRefreshScoreArray.push(score);
}
ngc.game.player.prototype.getFromToRefresh=function(){
    if(this.toRefreshScoreArray.length>0){
        return this.toRefreshScoreArray.shift();
    }
}
ngc.game.player.prototype.clearToRefresh=function(){
    this.toRefreshScoreArray=[];
}

ngc.game.player.prototype.setBanker=function(){
    this.banker=1;
    this.scene.getTable2D().showBankerByCIndex(this.playerIndex,true);
}

ngc.game.player.prototype.setUnBanker=function(){
    this.banker=0;
    this.scene.getTable2D().showBankerByCIndex(this.playerIndex,false);

}
ngc.game.player.prototype.isBanker=function(){
    return this.banker;
}

ngc.game.player.prototype.clearCards=function(){
    this.layerPart2d.clearCards();
    this.layerPart3d.clearCards();
    this.banker=0;
    this.toRefreshScoreArray=[];
}