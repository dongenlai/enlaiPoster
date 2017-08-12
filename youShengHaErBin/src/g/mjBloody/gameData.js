var SitDir={
    EAST:1,
    SOURTH:2,
    WEST:3,
    NORTH:4
}

var CardType={
    WAN:1,  //万
    TONG:2, //筒
    TIAO:3, //条
    FENG:4  //风
}

//根据玩法区别麻将类型,主要确定位置和旋转方向
var MJCardClass={
    SHOU:0,         //手牌
    MING:1,         //明牌
    HU:2,           //胡牌
    CHU:3,          //出牌
    HUAN:4,         //换牌
    QIANG:5,        //牌墙上的牌
    KOU:6           //扣掉，不给看的牌
}

var OPEventName="opevetnname";
var PackEventName="packeventname";

//自己的操作
var opSelfAction={
    mjSwap:1,
    mjAllLackTip:2,
    mjLack:3,
    mjDiscard:4,
    mjTakeCard:5,
    mjCancelTrust:6,
    mjContinueNextRound:7,  //开始下一小局
    mjQuit:8,
    mjChaTing:9,
}

//服务器的动作代号
var opServerActionCodes={
    mjaPass:1,
    mjaMo:2,
    mjaChi:3,
    mjaPeng:4,
    mjaDaMingGang:5,
    mjaChu:6,
    mjaAnGang:7,
    mjaJiaGang:8,
    mjaBuHua:9,
    mjaTing:10,
    mjaTingChi:11,     //听吃
    mjaTingPeng:12,    //听碰
    mjaHu:13,
    mjaCount:14,
    mjaTingGang:15,
    mjaSpecialGang:16,
}

//玩家状态
var PlayerState={
    NONE:0,         //没有轮到自己
    XUANPAIING:1,      //选牌中
    DINGQUEING:2,      //定缺中
    YAOPAIING:3,       //要牌思考中(吃，碰，杠)
    CHUPAIING:4,       //出牌中

    XUANPAISHOW:5,  //选牌显示
    DINGQUESHOW:6,  //定缺显示

    MOPAISHOW:7,   //摸牌
    YAPPAISHOW:8,   //要牌后的显示中（从别人打的牌中要）
    ZHUAPAISHOW:9,  //抓牌后的显示中（从牌堆里的牌中抓)
    CHUPAISHOW:10,   //出牌后的显示中
    HUPAISHOW:110,
}
var PlayerStateData=function(state,packData){
    this.state=state;
    this.packData=packData;
}

var PlayerNetState={
    tusNormal:2,
    tusOffline:3,
    tusFlee:4
}

ngc.game.gameSpeed = 7;

function getCardResByValue(cardValue){
    var prefix = "";
    if(cardValue <= 26) {
        var type = Math.floor(cardValue / 9) + 1;
        switch (type) {
            case 0:
            case CardType.WAN:
                prefix = "w_";
                break;
            case CardType.TONG:
                prefix = "tong_";
                break;
            case CardType.TIAO:
                prefix = "tiao_";
                break;
        }
        return prefix + ((cardValue % 9) + 1) + ".png";
    } else {
        var arr = {
            "27": "dong",
            "28": "nan",
            "29": "xi",
            "30": "bei",
            "31": "zhong",
            "32": "fa",
            "33": "bai"
        };

        prefix = arr[cardValue];
        return prefix + ".png";
    }
}

function getCardLocalResByValue(cardValue){
    return "res/g/mjBloody/card/" + getCardResByValue(cardValue);
}

cc.math.vec3Ride=function(v,num){
    return cc.math.vec3(v.x*num, v.y*num, v.z*num);
}
cc.math.vec3Mod=function(v,num){
    return cc.math.vec3(v.x%num, v.y%num, v.z%num);
}

//麻将模型位置
ngc.game.mjpos=[
    [
        {x:148, y:57, z:0},         //手牌     x:580,y:cc.winSize.height/2-45,z:271
        {x:840,y:cc.winSize.height/2-320,z:-42},   //明牌
        {x:808,y:cc.winSize.height/2-320,z:-76},    //胡牌
        {x:632,y:cc.winSize.height/2-320,z:-156},        //出牌

        {x:670,y:cc.winSize.height/2-300,z:-100},        //换牌
    ],
    [
        {x:494,y:cc.winSize.height/2-320,z:-332},
        {x:460,y:cc.winSize.height/2-320,z:-104},
        {x:527,y:cc.winSize.height/2-320,z:-80},
        {x:610,y:cc.winSize.height/2-320,z:-258},

        {x:582,y:cc.winSize.height/2-300,z:-194},
    ],
    [
        {x:770,y:cc.winSize.height/2-320,z:-400},
        {x:456,y:cc.winSize.height/2-320,z:-404},
        {x:534,y:cc.winSize.height/2-320,z:-367},
        {x:707,y:cc.winSize.height/2-320,z:-280},

        {x:670,y:cc.winSize.height/2-300,z:-290},
    ],
    [
        {x:848,y:cc.winSize.height/2-320,z:-112},
        {x:881,y:cc.winSize.height/2-320,z:-352},
        {x:849,y:cc.winSize.height/2-320,z:-360},
        {x:728,y:cc.winSize.height/2-320,z:-182},

        {x:754,y:cc.winSize.height/2-300,z:-194},
    ]
];


//麻将旋转方向(根据类型索引)
ngc.game.mjrotations=[
    [
        {x:270,y:0,z:0},                                      //手牌
        {x:180,y:0,z:0},                                      //明牌
        {x:180,y:0,z:0},                                      //胡牌
        {x:180,y:0,z:0},                                      //出牌
        {x:0,y:180,z:0},                                      //换牌
        {x:0,y:180,z:0},                                    //牌墙
        {x:0,y:180,z:0}                                       // 扣牌
    ],
    [
        {x:0,y:270,z:90},                                      //手牌
        {x:180,y:90,z:0},                                      //明牌
        {x:180,y:90,z:0},                                      //胡牌
        {x:180,y:90,z:0},                                      //出牌
        {x:0,y:270,z:0},                                      //换牌
        {x:0,y:270,z:0},                                    //牌墙
        {x:0,y:270,z:0}                                       // 扣牌
    ],
    [
        {x:90,y:0,z:0},                                      //手牌
        {x:180,y:0,z:0},                                      //明牌
        {x:180,y:0,z:0},                                      //胡牌
        {x:180,y:0,z:0},                                      //出牌
        {x:0,y:180,z:0},                                      //换牌
        {x:0,y:180,z:0},                                    //牌墙
        {x:0,y:180,z:0}                                       // 扣牌
    ],
    [
        {x:90,y:270,z:0},                                      //手牌
        {x:180,y:90,z:0},                                      //明牌
        {x:180,y:90,z:0},                                      //胡牌
        {x:180,y:90,z:0},                                      //出牌
        {x:0,y:270,z:0},                                      //换牌
        {x:0,y:270,z:0},                                    //牌墙
        {x:0,y:270,z:0}                                       //扣牌
    ]
];


//麻将纹理(根据类型索引)
ngc.game.mjtextures=[
    [
        "res/g/mjBloody/obj/i.png",                         //手牌
        "res/g/mjBloody/obj/c.png",                         //明牌
        "res/g/mjBloody/obj/c.png",                         //胡牌
        "res/g/mjBloody/obj/c.png",                         //出牌
        "res/g/mjBloody/obj/b.png",                         //换牌
        "res/g/mjBloody/obj/b.png",                         //牌墙
        "res/g/mjBloody/obj/b.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/f.png",                         //手牌
        "res/g/mjBloody/obj/d.png",                         //明牌
        "res/g/mjBloody/obj/d.png",                         //胡牌
        "res/g/mjBloody/obj/d.png",                         //出牌
        "res/g/mjBloody/obj/g.png",                         //换牌
        "res/g/mjBloody/obj/g.png",                         //牌墙
        "res/g/mjBloody/obj/g.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/e.png",                         //手牌
        "res/g/mjBloody/obj/c.png",                         //明牌
        "res/g/mjBloody/obj/c.png",                         //胡牌
        "res/g/mjBloody/obj/c.png",                         //出牌
        "res/g/mjBloody/obj/b.png",                         //换牌
        "res/g/mjBloody/obj/b.png",                         //牌墙
        "res/g/mjBloody/obj/b.png",                         //扣牌
    ],
    [
        "res/g/mjBloody/obj/h.png",                         //手牌
        "res/g/mjBloody/obj/d.png",                         //明牌
        "res/g/mjBloody/obj/d.png",                         //胡牌
        "res/g/mjBloody/obj/d.png",                         //出牌
        "res/g/mjBloody/obj/a.png",                         //换牌
        "res/g/mjBloody/obj/a.png",                         //牌墙
        "res/g/mjBloody/obj/a.png",                         //扣牌
    ]
]

//模型长、宽、高
ngc.game.mjModelWidth=16;
ngc.game.mjModelLength=21;
ngc.game.mjModelHeight=10;

/**
 * 创建麻将模型
 * @param cIndex   位置索引
 * @param MJCardClass  根据玩法的麻将类型
 */
ngc.game.createMj=function(cIndex,mjCardClass){
    var mjModel = new jsb.Sprite3D(ngc.game.objRes.majiang);

    if(ngc.game.mjtextures[cIndex][mjCardClass]){
        var texture=cc.textureCache.addImage(ngc.game.mjtextures[cIndex][mjCardClass]);
        if(texture)
            mjModel.setTexture(texture);
    }

    var rotation=ngc.game.mjrotations[cIndex][mjCardClass];
    if(rotation)
        mjModel.setRotation3D(rotation);

    if(cIndex==0&&mjCardClass==MJCardClass.SHOU){
        mjModel.setScaleX(2.42);
        mjModel.setScaleY(2.42);
        mjModel.setScaleZ(2.42);
    }
    else{
        mjModel.setScale(0.5);
        mjModel.setScaleZ(0.5);
    }

    return mjModel;
}

//男性手动画帧范围
ngc.game.man_anis={
    "arrangecard1":[189,190],
    "arrangecard2":[220,280],

    "discard1":[124,132],
    "discard2":[132,172],
    "dice":[0,70],
    "penggang1":[301,310],
    "penggang2":[310,345],
    "swap1":[75,80],
    "swap2":[80,121],
    "hupai1":[351,357],
    "hupai2":[357,393]
}

//女性手动画帧范围
ngc.game.woman_anis={
    "arrangecard1":[189,190],
    "arrangecard2":[266,291],

    "discard1":[124,132],
    "discard2":[132,172],
    "dice":[0,67],
    "penggang1":[304,310],
    "penggang2":[310,345],
    "swap1":[75,80],
    "swap2":[80,121],
    "hupai1":[351,357],
    "hupai2":[357,393]
}


ngc.game.man_anipros=[
    {
        "dice":{
            "pos":cc.math.vec3(663,310,199),
            "rotation":cc.math.vec3(-28,-104,0),
            "scale":cc.math.vec3(57*22.33/57,57*22.33/57,57*22.33/57)
        },
        "swap":{
            "pos":cc.math.vec3(649,310,150),
            "rotation":cc.math.vec3(-42,-107,0),
            "scale":cc.math.vec3(52*22.33/57,52*22.33/57,52*22.33/57)
        },
        "penggang":{
            "pos":cc.math.vec3(732,5,19),
            "rotation":cc.math.vec3(-56,-99,-9),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "hupai":{
            "pos":cc.math.vec3(777,78,146),
            "rotation":cc.math.vec3(-79,-102,-25),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "discard":{
            "pos":cc.math.vec3(524,-193,170),
            "rotation":cc.math.vec3(85,-64,134),
            "scale":cc.math.vec3(191*22.33/57,191*22.33/57,191*22.33/57)
        }
    },
    {
        "dice":{
            "pos":cc.math.vec3(525,310,42),
            "rotation":cc.math.vec3(-25,167,5),
            "scale":cc.math.vec3(57*22.33/57,57*22.33/57,57*22.33/57)
        },
        "swap":{
            "pos":cc.math.vec3(575,310,49),
            "rotation":cc.math.vec3(-44,170,17),
            "scale":cc.math.vec3(60*22.33/57,60*22.33/57,60*22.33/57)
        },
        "penggang":{
            "pos":cc.math.vec3(397,15,-220),
            "rotation":cc.math.vec3(-54,168,6),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "hupai":{
            "pos":cc.math.vec3(311,108,-132),
            "rotation":cc.math.vec3(-60,164,3),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "discard":{
            "pos":cc.math.vec3(275,7,-357),
            "rotation":cc.math.vec3(133,-341,193),
            "scale":cc.math.vec3(159*22.33/57,159*22.33/57,159*22.33/57)
        },
        "arrangecard":{
            "pos":cc.math.vec3(306,30,-241),
            "rotation":cc.math.vec3(141,4,-166),
            "scale":cc.math.vec3(136*22.33/57,136*22.33/57,136*22.33/57)
        },
    },
    {
        "dice":{
            "pos":cc.math.vec3(686,340,-111),
            "rotation":cc.math.vec3(24,-300,-52),
            "scale":cc.math.vec3(57*22.33/57,57*22.33/57,57*22.33/57)
        },
        "swap":{
            "pos":cc.math.vec3(692,310,-80),
            "rotation":cc.math.vec3(-154,130,118),
            "scale":cc.math.vec3(64*22.33/57,64*22.33/57,64*22.33/57)
        },
        "penggang":{
            "pos":cc.math.vec3(571,17,-453),
            "rotation":cc.math.vec3(-26,79,-24),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "hupai":{
            "pos":cc.math.vec3(594,139,-574),
            "rotation":cc.math.vec3(-27,70,-25),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "discard":{
            "pos":cc.math.vec3(851,-32,-631),
            "rotation":cc.math.vec3(147,-246,165),
            "scale":cc.math.vec3(176*22.33/57,176*22.33/57,176*22.33/57)
        },
        "arrangecard":{
            "pos":cc.math.vec3(702,8,-618),
            "rotation":cc.math.vec3(44,65,-75),
            "scale":cc.math.vec3(136*22.33/57,136*22.33/57,136*22.33/57)
        },
    },
    {
        "dice":{
            "pos":cc.math.vec3(807,310,31),
            "rotation":cc.math.vec3(-28,0,0),
            "scale":cc.math.vec3(57*22.33/57,57*22.33/57,57*22.33/57)
        },
        "swap":{
            "pos":cc.math.vec3(757,310,95),
            "rotation":cc.math.vec3(-44,-13,-7),
            "scale":cc.math.vec3(60*22.33/57,60*22.33/57,60*22.33/57)
        },
        "penggang":{
            "pos":cc.math.vec3(936,45,-218),
            "rotation":cc.math.vec3(-58,-19,-27),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "hupai":{
            "pos":cc.math.vec3(1070,95,-312),
            "rotation":cc.math.vec3(-60,-16,3),
            "scale":cc.math.vec3(158*22.33/57,158*22.33/57,158*22.33/57)
        },
        "discard":{
            "pos":cc.math.vec3(1065,-38,-127),
            "rotation":cc.math.vec3(133,-169,176),
            "scale":cc.math.vec3(159*22.33/57,159*22.33/57,159*22.33/57)
        },
        "arrangecard":{
            "pos":cc.math.vec3(1097,-58,-216),
            "rotation":cc.math.vec3(150,-184,-191),
            "scale":cc.math.vec3(150*22.33/57,150*22.33/57,150*22.33/57)
        },
    }
]



ngc.game.woman_anipros=[
    {
        "dice":{
            "pos":cc.math.vec3(803,310,164),
            "rotation":cc.math.vec3(34,-89,51),
            "scale":cc.math.vec3(21.66,21.66,21.66)
        },
        "swap":{
            "pos":cc.math.vec3(759,310,123),
            "rotation":cc.math.vec3(-102,-110,-75),
            "scale":cc.math.vec3(17.10,17.10,17.10)
        },
        "penggang":{
            "pos":cc.math.vec3(882,-222,23),
            "rotation":cc.math.vec3(-55,-106,-6),
            "scale":cc.math.vec3(53.49,53.49,53.49)
        },
        "hupai":{
            "pos":cc.math.vec3(1034,38,88),
            "rotation":cc.math.vec3(-13,-93,-11),
            "scale":cc.math.vec3(43.09,43.09,43.09)
        },
        "discard":{
            "pos":cc.math.vec3(742,-381,14),
            "rotation":cc.math.vec3(94,-46,135),
            "scale":cc.math.vec3(58.46,58.46,58.46)
        }
    },
    {
        "dice":{
            "pos":cc.math.vec3(547,310,179),
            "rotation":cc.math.vec3(-16,178,6),
            "scale":cc.math.vec3(57*21.66/54,57*21.66/54,57*21.66/54)
        },
        "swap":{
            "pos":cc.math.vec3(570,310,165),
            "rotation":cc.math.vec3(-19,163,17),
            "scale":cc.math.vec3(19.37,19.37,19.37)
        },
        "penggang":{
            "pos":cc.math.vec3(364,-178,-70),
            "rotation":cc.math.vec3(-52,160,9),
            "scale":cc.math.vec3(45.83,45.83,45.83)
        },
        "hupai":{
            "pos":cc.math.vec3(403,108,134),
            "rotation":cc.math.vec3(-3,173,2),
            "scale":cc.math.vec3(33.07,33.07,33.07)
        },
        "discard":{
            "pos":cc.math.vec3(190,14,42),
            "rotation":cc.math.vec3(175,-343,195),
            "scale":cc.math.vec3(58.77,58.77,58.77)
        },
        "arrangecard":{
            "pos":cc.math.vec3(280,-166,225),
            "rotation":cc.math.vec3(187,26,-197),
            "scale":cc.math.vec3(52.66,52.66,52.66)
        },
    },
    {
        "dice":{
            "pos":cc.math.vec3(537,340,3),
            "rotation":cc.math.vec3(37,-261,-52),
            "scale":cc.math.vec3(20.05,20.05,20.05)
        },
        "swap":{
            "pos":cc.math.vec3(561,310,-1),
            "rotation":cc.math.vec3(-141,101,123),
            "scale":cc.math.vec3(18.04,18.04,18.04)
        },
        "penggang":{
            "pos":cc.math.vec3(395,-163,-517),
            "rotation":cc.math.vec3(-15,63,-24),
            "scale":cc.math.vec3(47.09,47.09,47.09)
        },
        "hupai":{
            "pos":cc.math.vec3(246,24,-591),
            "rotation":cc.math.vec3(-25,86,22),
            "scale":cc.math.vec3(55.16,55.16,55.16)
        },
        "discard":{
            "pos":cc.math.vec3(618,-137,-679),
            "rotation":cc.math.vec3(168,-236,165),
            "scale":cc.math.vec3(56.78,56.78,56.78)
        },
        "arrangecard":{
            "pos":cc.math.vec3(377,-150,-622),
            "rotation":cc.math.vec3(24,71,-37),
            "scale":cc.math.vec3(40.36,40.36,40.36)
        },
    },
    {
        "dice":{
            "pos":cc.math.vec3(768,310,-59),
            "rotation":cc.math.vec3(-22,0,0),
            "scale":cc.math.vec3(20.05,20.05,20.05)
        },
        "swap":{
            "pos":cc.math.vec3(744,310,0),
            "rotation":cc.math.vec3(-32,-13,-13),
            "scale":cc.math.vec3(16.04,16.04,16.04)
        },
        "penggang":{
            "pos":cc.math.vec3(976,-214,-445),
            "rotation":cc.math.vec3(-37,-23,1),
            "scale":cc.math.vec3(55.24,55.24,55.24)
        },
        "hupai":{
            "pos":cc.math.vec3(1114,26,-598),
            "rotation":cc.math.vec3(-1,-14,3),
            "scale":cc.math.vec3(53.22,53.22,53.22)
        },
        "discard":{
            "pos":cc.math.vec3(1171,-215,-206),
            "rotation":cc.math.vec3(139,-146,168),
            "scale":cc.math.vec3(60.24,60.24,60.24)
        },
        "arrangecard":{
            "pos":cc.math.vec3(1083,-241,-536),
            "rotation":cc.math.vec3(159,-170,-188),
            "scale":cc.math.vec3(49.45,49.45,49.45)
        },
    }
]

