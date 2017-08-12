//重写netPack中的定义

//-----------------------------------发送
game_msgId_send.SIT = 54;
game_msgId_send.READY = 56;
game_msgId_send.TRUST = 57;                                 //托管，取消托管
game_msgId_send.SWAP_CARD = 58;
game_msgId_send.Lack = 60;                                  //定缺
game_msgId_send.CHU = 61;                                   //出牌
game_msgId_send.MJ_ACTION = 62;                             //吃碰杠胡
game_msgId_send.QUEST_CTRL_TABLE = 63;                      //请求散桌
game_msgId_send.Quit = 64;
game_msgId_send.ChaTing = 65;
game_msgId_send.SPECIAL_GANG = 66;
//----------------------------------


//---------------------------------接收
game_msgId_rcv.SIT_RESP = 4;
game_msgId_rcv.READY_RESP = 6;
game_msgId_rcv.TRUST_RES = 7;                               //托管
game_msgId_rcv.DISCARD_RESP = 9;                            //出牌返回
game_msgId_rcv.Lack_RES = 10;                               //换牌结果
game_msgId_rcv.CLIENT_QUEST_CTRL_TABLE_RESP = 11;           //再次请求是否散桌
game_msgId_rcv.LEAVE_RESP = 12;
game_msgId_rcv.CHATING_RESP = 13;
game_msgId_rcv.ERROR_ACTION_RESP = 14;                      //动作错误
game_msgId_rcv.BEGIN_NOTIFY = 21;
game_msgId_rcv.OTHER_ENTER_NOTIFY = 22;
game_msgId_rcv.OTHER_LEAVE_NOTIFY = 23;
game_msgId_rcv.CLIENT_FORCE_LEAVE_NOTIFY = 24;              //当房间解散的时候，在申请解散房间的时候 给个提示
game_msgId_rcv.OTHER_READY_NOTIFY = 26;
game_msgId_rcv.OTHER_STATE_NOTIFY = 27;
game_msgId_rcv.SYN_NOTIFY = 28;                             //整包
game_msgId_rcv.TRUST_NOTIFY = 29;                           //托管
game_msgId_rcv.DEALCARD_NOTIFY = 30;
game_msgId_rcv.MO_BAO_NOTIFY = 31;                       //摸宝
game_msgId_rcv.LackRS_NOTIFY = 32;                          //每家缺牌结果
game_msgId_rcv.RESULT_NOTIFY = 34;                          //当局结束
game_msgId_rcv.TINGGANG_NOTIFY = 36;                     //换牌结果
game_msgId_rcv.CONSUME_SPECIAL_GOLD_NOTIFY = 35;
game_msgId_rcv.MO_PAI_NOTIFY = 37;                          //摸牌
game_msgId_rcv.CHU_PAI_NOTIFY = 38;                         //出牌
game_msgId_rcv.PENG_GANG_NOTIFY = 39;                       //碰杠
game_msgId_rcv.HU_NOTIFY = 40;                              //胡牌
game_msgId_rcv.END_ROUND = 41;                              //当局结束
game_msgId_rcv.CLIENT_DISBAND_TABLE_NOTIFY = 42;            //服务器广播其他玩家是否同意散桌
game_msgId_rcv.CHI_NOTIFY = 43;
game_msgId_rcv.TING_CHI_NOTIFY = 44,									// 听吃
game_msgId_rcv.TING_PENG_NOTIFY = 45,									// 听碰
game_msgId_rcv.SPECIAL_GANG_NOTIFY = 46;
game_msgId_rcv.MSGID_CLIENT_G_TING_NOTIFY = 47; //听牌

game_msgId_rcv.MSGID_CLIENT_QUEST_CTRL_TABLE = 63,    //请求散桌
//-----------------------------------
/**
 * 登录包
 * @constructor
 */
game_pack_template_send.LOGIN=function(){
    this.action=game_msgId_send.LOGIN;
    this.accessToken="";
    this.mac="";
    this.whereFrom="";
    this.version="";
}
/**
 * 查找(创建)桌子
 * @constructor
 */
game_pack_template_send.SIT=function(isFind){
    this.action=game_msgId_send.SIT;
    this.jingdu=0.0;
    this.weidu=0.0;
    this.isFind=1;
    if(isFind!=null&&isFind!=undefined) this.isFind=isFind;
    this.selScore=0;
    this.totalRound=0;
    this.vipRoomType=0;
    this.tableNum="";
    this.isChunJia = 1;// 是否带纯夹
    this.isLaizi = 1;// 是否带红中癞子
    this.isGuaDaFeng = 1;// 是否带刮大风
    this.isSanQiJia = 1;// 是否带三期夹
    this.isDanDiaoJia = 1;// 是否带单吊夹
    this.isZhiDuiJia = 1;// 是否带支对胡
    this.isZhanLiHu = 1;// 是否带站立胡
    this.isMenQing = 1;// 是否带门清
    this.isAnKe = 1;// 是否带暗刻
    this.isKaiPaiZha = 1;// 是否带开牌炸
    this.isBaoZhongBao = 1;// 是否带宝中宝
    this.isHEBorDQ = 0;// 0哈尔滨玩法  1大庆玩法
}
game_pack_template_send.READY=function(){
    this.action=game_msgId_send.READY;
    this.i64param=0;
}

game_pack_template_send.SWAP_CARD=function(){
    this.action=game_msgId_send.SWAP_CARD;
    this.cards=null;
}

game_pack_template_send.Lack=function(){
    this.action=game_msgId_send.Lack;
    this.delSuit=-1;
}

game_pack_template_send.Discard=function(){
    this.action=game_msgId_send.CHU;
    this.cardId=-1;
}

game_pack_template_send.MJ_ACTION=function(){
    this.action=game_msgId_send.MJ_ACTION;
    this.mjAction=-1;
    this.eS="";
}

game_pack_template_send.TRUST=function(){
    this.action=game_msgId_send.TRUST;
    this.isTrust=0;
}

game_pack_template_send.Quit=function(){
    this.action=game_msgId_send.Quit;
}

game_pack_template_send.ChaTing=function(){
    this.action=game_msgId_send.ChaTing;
}



/**
 * 登录返回包
 */
game_pack_template_rcv.LOGIN_RESP=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
    this.userState=data["userState"];
    this.baseInfo=data["baseInfo"];
    this.ip=data["ip"];
}
/**
入座返回
 */
game_pack_template_rcv.SET_RES=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
    this.discardDelay=data["discardDelay"];
    this.waitDongZuoDelay=data["waitDongZuoDelay"];
}

game_pack_template_rcv.LEAVE_RESP=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
}

game_pack_template_rcv.CHATING_RESP=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
    this.tingInfo=data["tingInfo"];
}

/**
 * 准备返回
 * @param data
 * @constructor
 */
game_pack_template_rcv.READY_RESP=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
}

game_pack_template_rcv.OTHER_READY_NOTIFY=function(data){
    this.userId=data["userId"];
}

game_pack_template_rcv.OTHER_LEAVE_NOTIFY=function(data){
    this.userId=data["userId"];
    this.place=data["place"];
}

game_pack_template_rcv.MSGID_CLIENT_G_TING_NOTIFY=function(data){
    this.pos =data["p"];
    this.card = data["c"];
    this.cpos=data["cP"];
    this.tingType = data["tingType"];
    this.tC =data["tC"];
    this.mjAction = data["mjAction"];
};

game_pack_template_rcv.OTHER_STATE_NOTIFY=function(data){
    this.tuserState=data["tuserState"];
    this.place=data["place"];
}

game_pack_template_rcv.OTHER_SWAP_CARD_NOTIFY=function(data){
    this.place=data["place"];
}

game_pack_template_rcv.CONSUME_SPECIAL_GOLD_NOTIFY=function(data){
    this.consumeSpecialGold=data["consumeSpecialGold"];
}

/*
开始通知
*/
game_pack_template_rcv.BEGIN_NOTIFY=function(data){
    this.chairIndex=data["chairIndex"];
    this.eastP=data["eastP"];
    this.huNo3Suit = data["huNo3Suit"];
    this.specialGang = data["specialGang"];
    this.jiaFan = data["jiaFan"];
    this.ZScore=data["ZScore"];
    this.baseScore=data["baseScore"];
    this.curRound=data["curRound"];
    this.maxRound=data["maxRound"];
    this.tableNum=data["tableNum"];
    this.dyNum = data["dyNum"];
    this.dyType = data["dyTyep"];
    this.isMenQ = data["isMenQ"];

    this.isChunJia = data["isChunJia"];// 是否带纯夹
    this.isLaizi = data["isLaizi"];// 是否带红中癞子
    this.isGuaDaFeng = data["isGuaDaFeng"];// 是否带刮大风
    this.isSanQiJia = data["isSanQiJia"];// 是否带三期夹
    this.isDanDiaoJia = data["isDanDiaoJia"];// 是否带单吊夹
    this.isZhiDuiJia = data["isZhiDuiJia"];// 是否带支对胡
    this.isZhanLiHu = data["isZhanLiHu"];// 是否带站立胡
    this.isMenQing = data["isMenQing"];// 是否带站立胡
    this.isAnKe = data["isAnKe"];// 是否带站立胡
    this.isKaiPaiZha = data["isKaiPaiZha"];// 是否带站立胡
    this.isBaoZhongBao = data["isBaoZhongBao"];// 是否带站立胡
    this.isHEBorDQ = data["isHEBorDQ"];// 是否带站立胡

    this.userCount = data["userCount"];

}

game_pack_template_rcv.OTHER_ENTER_NOTIFY=function(data){
    this.ZScore=data["ZScore"];
    this.chairIndex=data["chairIndex"];
    this.tuserState=data["tuserState"];
    this.baseInfo=data["baseInfo"];
    this.ip=data["ip"];
}

game_pack_template_rcv.DEALCARD_NOTIFY=function(data){
    this.dice0=data["dice0"];
    this.dice1=data["dice1"];
    this.eastP=data["eastP"];
    this.startP=data["startP"];
    this.bankerP=data["bankerP"];
    this.PQCurrP=data["PQCurrP"];
    this.wallCount=data["wallCount"];
    this.leftWallCount=data["leftWallCount"];
    this.cards=data["cards"];
    this.curRound=data["curRound"];
    this.maxRound=data["maxRound"];
}

game_pack_template_rcv.MO_BAO_NOTIFY=function(data){
    this.wallPlace=data["wP"];// wallPlace 当前牌墙玩家
    this.wallCount=data["wC"];// wallCount 当前牌墙剩余的牌数量
    this.flag=data["flag"];// 0:首次产生宝牌  1：换宝
}

game_pack_template_rcv.SWAP_CARDRS_NOTIFY=function(data){
    this.swapDirction=data["swapDirction"];
    this.cards=data["cards"];
    this.addCards=data["addCards"];
    this.delCards=data["delCards"];
}

game_pack_template_rcv.Lack_RES=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
}

game_pack_template_rcv.LackRS_NOTIFY=function(data){
    this.pos=data["p"];
    this.U0=data["U0"];
    this.U1=data["U1"];
    this.U2=data["U2"];
    this.U3=data["U3"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
}

game_pack_template_rcv.MO_PAI_NOTIFY=function(data){
    this.pos=data["p"];
    this.cpos=data["cP"];
    this.card=data["c"];
    this.isGangMo=data["g"];//是否是杠上摸牌
    this.leftCardNum=data["wC"];//当前桌子上剩余的没有抓的牌的数量
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
}

game_pack_template_rcv.CHU_PAI_NOTIFY=function(data){
    this.pos=data["p"];
    this.cpos=data["cP"];
    this.card=data["c"];
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
    this.tingType = null;
}

game_pack_template_rcv.PENG_GANG_NOTIFY=function(data){
    this.pos=data["p"];
    this.lpos=data["lP"];
    this.cpos=data["cP"];
    this.card=data["c"];
    this.action=data["a"];
    this.mjAction=data["mjAction"];
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
};

game_pack_template_rcv.SPECIAL_GANG_NOTIFY = function(data){
    this.pos = data["p"];
    this.action = opServerActionCodes.mjaSpecialGang;
    this.mjAction = data["mjAction"];
    this.gangCards = data["gangCards"];
    this.specialGang = true;
    this.card = this.gangCards[0];
};

game_pack_template_rcv.CHI_NOTIFY=function(data){
    this.pos=data["p"];
    this.card=data["c"];
    this.mjAction=data["mjAction"];
    this.decTimeCount=data["dT"];
    this.clockSt=data["tS"];
    this.lpos=data["lP"];
    this.cpos=data["cP"];
    this.action=data["a"];
    this.order = data["order"];
}

game_pack_template_rcv.TING_CHI_NOTIFY=function(data){
    this.pos=data["p"];
    this.card=data["c"];
    this.order = data["order"];
    this.action=data["a"];
    this.chuCard = data["cc"];
    this.chuPlace = data["chuP"];
    this.lpos=data["lP"];
    this.cpos=data["cP"];
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
}
game_pack_template_rcv.TING_PENG_NOTIFY=function(data){
    this.pos=data["p"];
    this.card=data["c"];
    this.order = data["order"];
    this.action=data["a"];
    this.chuCard = data["cc"];
    this.chuPlace = data["chuP"];
    this.lpos=data["lP"];
    this.cpos=data["cP"];
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
}


game_pack_template_rcv.DISCARD_RESP=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
    this.curCards=data["curCards"];
}
game_pack_template_rcv.HU_NOTIFY=function(data){
    this.pos=data["p"];
    this.lpos=data["lP"];
    this.cpos=data["cP"];
    this.isZiMo=data["isZiMo"];
    this.card=data["lC"];       //胡的牌
    this.decTimeCount=data["dT"];
    this.isQiangGang = data["isQ"]; // 是否是抢杠胡
    //this.scores=data["scores"];
    this.scores=data["zScores"];
    this.huCount=data["huCount"];//一炮几响
    this.clockSt=data["tS"];
    this.decTimeCount=data["dT"];
    this.mjAction=data["mjAction"];
}
game_pack_template_rcv.TRUST_NOTIFY=function(data){
    this.userId=data["userId"];
    this.isTrust=data["isTrust"];
}
game_pack_template_rcv.TRUST_RES=function(data){
    this.code=data["code"];
    this.msg=data["msg"];
    this.isTrust=data["isTrust"];
}
game_pack_template_rcv.RESULT_NOTIFY=function(data){
    this.baseScore=data["baseScore"];
    this.curRound=data["curRound"];
    this.scores=data["scores"];
    this.openCards = data["openCards"];
    this.openFishCards = data["openFishCards"];
    this.result0=data["result0"];
    this.result1=data["result1"];
    this.result2=data["result2"];
    this.result3=data["result3"];
    this.cards0=data["cards0"];
    this.cards1=data["cards1"];
    this.cards2=data["cards2"];
    this.cards3=data["cards3"];
    this.createPlace=data["createPlace"];
};

game_pack_template_rcv.TINGGANG_NOTIFY = function(data){
    this.pos = data["p"];
    this.cP = data["cP"];
    this.tingType = data["tingType"];
    this.gangCards = data["gangCards"];
    this.action = data["a"];
    this.exPandStr = data["e"];
    this.mjAction = data["mjAction"];
};

game_pack_template_rcv.END_ROUND=function(data){
    this.countInfo=data["countInfo"];
    this.isForceLeave=data["isForceLeave"];
    this.needShow=data["needShow"];
    this.createPlace=data["createPlace"];
}

game_pack_template_rcv.SYN_NOTIFY=function(data){
    this.curPlace=data["curPlace"];
    this.decTimeCount=data["decTimeCount"];
    this.tS=data["tS"];
    this.eastP=data["eastP"];
    this.startP=data["startP"];
    this.bankerP=data["bankerP"];
    this.lastChuPaiPlace=data["lastChuPaiPlace"];
    this.leftWallCount=data["leftWallCount"];
    this.wallCount=data["wallCount"];
    this.selfCards=data["selfCards"];
    this.mjAction=data["mjAction"];
    this.mingPai=data["mingPai1"];
    this.zhuoPai=data["zhuoPai"];
    this.users=data["users"];
    this.tbState=data["tbState"];
    this.hasSwaped=data["hasSwaped"];
    this.curRound=data["curR"];
    this.totalRound=data["totalR"];
    this.SDirect=data["SDirect"];
    this.selfGetSwapCds=data["selfGetSwapCds"];
    this.peopleNum = data["peopleNum"];
}
