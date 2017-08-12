ngc.game.gameLogic=function(cards){
    this.reset(cards);
}

ngc.game.gameLogic.prototype.reset=function(cards){
    this.cardMaps={
        "cards":cards,
        "hupaigroup":[]
    }
    this.colorCardCount=0;
    var color=0;
    for(var key=0 in cards){
        if(Math.floor(cards[key]/9)!=color){
            this.colorCardCount++;
            color=Math.floor(cards[key]/9);
        }
    }
}

ngc.game.gameLogic.prototype.parseCards=function(){
    if(this.colorCardCount>2){
        return;
    }
    for(var i=0;i<this.cardMaps.cards.length;i++){
        var group1=this.parseColorCardsFromIndex(i,1);
        var group2=this.parseColorCardsFromIndex(i,-1);
        if(group1.hupai.length>0)
            this.cardMaps.hupaigroup.push(group1);
        if(group2.hupai.length>0)
            this.cardMaps.hupaigroup.push(group2);
    }

    if(this.cardMaps.hupaigroup.length==0){
        var group=this.parseColorCardsDouble();//小7对
        if(group.hupai.length>0)
            this.cardMaps.hupaigroup.push(group);
    }
}

ngc.game.gameLogic.prototype.parseColorCardsFromIndex=function(fromIndex,order){
    var colorCards=this.cardMaps.cards;
    var group=this.generateGroup();
    var i=fromIndex;
    var z=0;
    while(i!=fromIndex||z==0){
        z=1;
        if(i+order!=fromIndex&&i+2*order!=fromIndex){
            if(colorCards[i+2*order]!=undefined&&colorCards[i]==colorCards[i+1*order]&&colorCards[i]==colorCards[i+2*order]){
                group.pairs.push([colorCards[i],colorCards[i+order],colorCards[i+2*order]]);
                i+=2*order;
            }
            else if(colorCards[i+2*order]!=undefined&&this.checkSerial(colorCards[i],colorCards[i+order],colorCards[i+2*order])){////colorCards[i]+order==colorCards[i+order]&&colorCards[i]+2*order==colorCards[i+2*order]
                group.pairs.push([colorCards[i],colorCards[i+1*order],colorCards[i+2*order]]);
                i+=2*order;
            }
            else if(colorCards[i]!=undefined){
                group.topair.push(colorCards[i]);
            }
        }
        else{
            group.topair.push(colorCards[i]);
        }

        if(order>0){
            if(++i>=colorCards.length){
                i=0;
            }
        }
        else if(order<0){
            if(--i<0){
                i=colorCards.length-1;
            }
        }
    }
    this.parseGroup(group);

    return group;
}

//小7对
ngc.game.gameLogic.prototype.parseColorCardsDouble=function(){
    var colorCards=this.cardMaps.cards;
    var group=this.generateGroup();
    for(var i=0;i<colorCards.length;i++){
        if(colorCards[i+1]!=undefined){
            if(colorCards[i]==colorCards[i+1]){
                group.pairs.push([colorCards[i],colorCards[i+1]]);
                i++;
            }
            else{
                group.topair.push(colorCards[i]);
            }
        }
        else{
            group.topair.push(colorCards[i]);
        }
    }
    if(group.pairs.length==6){
        this.parseGroup(group);
    }
    return group;
}

ngc.game.gameLogic.prototype.parseGroup=function(group){
    this.sortByAsc(group.topair);
    if(group.topair.length==2){
        if(group.topair[0]==group.topair[1])//已经胡牌
            ;
        else{
            group.hupai.push(group.topair[0],group.topair[1]);
            group.discard.push(group.topair[1],group.topair[0]);
        }
        return;
    }
    if(group.topair.length==5){
        var samePair=[];
        var serialPair=[];
        for(var i=0;i<group.topair.length;i++){
            if(i<group.topair.length-1){
                if(group.topair[i]==group.topair[i+1]){
                    samePair.push(group.topair[i],group.topair[i+1]);
                    i++;
                }
                else if(this.checkSerial(group.topair[i],group.topair[i+1])){
                    serialPair.push(group.topair[i],group.topair[i+1]);
                    i++;
                }
                else{
                    group.discard.push(group.topair[i]);
                }
            }
            else{
                group.discard.push(group.topair[i]);
            }
        }
        if(samePair.length>0){
            if(serialPair.length==2){
                if(this.checkSerial(serialPair[0]-1,serialPair[0])){
                    group.hupai.push(serialPair[0]-1);
                }
                if(this.checkSerial(serialPair[1],serialPair[1]+1))
                    group.hupai.push(serialPair[1]+1);
            }
            else if(serialPair.length==0&&samePair.length==4){
                group.hupai.push(samePair[0],samePair[2]);
            }
            for(var j=group.discard.length;j<group.hupai.length;j++){
                group.discard.push(group.discard[0]);
            }
        }
    }
}

ngc.game.gameLogic.prototype.checkSerial=function(){
    if(arguments.length<=1) return false;
    var gap=arguments[1]-arguments[0];
    if(Math.abs(gap)!=1) return false;
    for(var key=0 in arguments){
        if(arguments[parseInt(key)+1]!=undefined){
            if(arguments[parseInt(key)]+gap!=arguments[parseInt(key)+1]||Math.floor(arguments[parseInt(key)]/9)!=Math.floor(arguments[parseInt(key)+1]/9))
                return false;
        }
    }
    return true;
}

ngc.game.gameLogic.prototype.checkSame=function(){
    if(arguments.length<=1) return false;
    for(var key=0 in arguments){
        if(arguments[key+1]!=undefined){
            if(arguments[key]!=arguments[key+1])
                return false;
        }
    }
    return true;
}

ngc.game.gameLogic.prototype.generateGroup=function(){
    return {pairs:[],topair:[],hupai:[],discard:[]};
}

ngc.game.gameLogic.prototype.sortByAsc=function(cards){
    cards.sort(function(a,b){return a-b;});
}

ngc.game.gameLogic.prototype.checkInCard=function(cards,card){
    for(var key=0 in cards){
        if(cards[key]==card) return true;
    }
    return false;
}

ngc.game.gameLogic.prototype.getSuggestedCards=function(){
    if(this.cardMaps.hupaigroup.length>0){
        var suggestedMap={};
        for(var key=0 in this.cardMaps.hupaigroup){
            var discard=this.cardMaps.hupaigroup[key].discard;
            for(var j=0 in discard){
                if(!suggestedMap[discard[j].toString()])
                    suggestedMap[discard[j].toString()]={
                        hupai:[],
                        score:this.cardMaps.hupaigroup[key].score
                    };
                if(!this.checkInCard(suggestedMap[discard[j].toString()].hupai,this.cardMaps.hupaigroup[key].hupai[j])){
                    suggestedMap[discard[j].toString()].hupai.push(this.cardMaps.hupaigroup[key].hupai[j]);
                }
            }
        }
        for(var key =0 in suggestedMap){
            this.sortByAsc(suggestedMap[key].hupai);
        }
        return suggestedMap;
    }
}

//var cards=[
//    0,0,0,
//    1,2,3,4,5,6,7,
//    8,8,8,
//    12
//];
//
//var gameLogic=new ngc.game.gameLogic(cards);
//gameLogic.parseCards();
//var suggestedMap=gameLogic.getSuggestedCards();