#ifndef __MJ_TYPE_DEFINE__HEAD__
#define __MJ_TYPE_DEFINE__HEAD__

#include <string>

using std::string;

const int INVALID_CARD_VALUE = -1;
const int MJDATA_COUNT = 112;                          // 麻将个数
const int MJDATA_TYPE_COUNT = 9 + 9 + 9 + 4 + 3;       // 
const int MJDATA_CARDID_ERROR = 255;                   // 错误的CARDID编号
const int MJDATA_CARDID_ANY = 254;                     // 代表任意一张牌

enum TMJCardSuit
{
	mjcsError = 0,
	mjcsCharacter,   // 万子
	mjcsDot,		 // 饼子	
	mjcsBam,		 //	条子bamboo
	mjcsWind,        // 风牌
	mjcsDragon,      // 箭牌
	mjcsFlower       // 花牌
};

enum TMJSpecialGangFlag
{
	sgfFeng = 0,
	sgfZi,
	sgfCount
};


// 麻将牌的各种动作,因为英文译法晦涩难懂，大量专业词汇用汉语拼音(麻将是国粹，哈哈)
// 注：广义上的明杠包括大明杠(别人出,本人杠)和小明杠(又称加杠)
enum TMJActionName
{
	mjaError,
	mjaPass,
	mjaMo,
	mjaChi,
	mjaPeng,
	mjaDaMingGang,
	mjaChu,
	mjaAnGang,
	mjaJiaGang,
	mjaBuHua,
	mjaTing,
    mjaTingChi,     //听吃
    mjaTingPeng,    //听碰
	mjaHu,
	mjaCount
};

enum TMJHuType
{
	htPingHu = 0,   //平胡
    htMoBao,        // 摸宝 
    htMoHongZhong,  //摸红中
    htKuaDaFeng,    // 刮大风
    htBaoZhongBao,  // 宝中宝
    htCount
};

// 番种枚举
enum TMJFanZhongName
{
    // 哈尔滨玩法
	mjfzHuType = 0,

    mjfzBaoTing,
    mjfzDianPao,
    mjfzKaiMen,

    mjfzZiMo,
	mjfzMenQing,
    mjfzAnKe,

    // 大庆玩法
    mjfzdpPingHu,
    mjfzdpJiaHu,
    mjfzdpZiMoHu,
    mjfzdpMoBaoHu,
    mjfzdpMengQing,
    mjfzdpBaoZhongBao,
    mjfzdpZhuangJia,

	mjfzCount
};


// 各动作的优先级
const int PRI_MJAction[mjaCount] = { 0,     // mjaError
5,									        // mjaPass 
1, 2, 3, 4,							        // mjaMo   mjaChi  mjaPeng  mjaDamingGang
5, 5, 5, 5, 5, 5 ,5,                        // mjaChu  mjaAnGang mjaJiaGang  mjaBuHua  mjaTing  mjaTingChi  mjaTingPeng
5                                           // mjaHu
};

const string CAPTION_MJAction[mjaCount] = {
	"error", "过", "摸牌", "吃牌", "碰", "大明杠", "出牌", "暗杠", "加杠", "补花", "听","听吃","听碰", "胡牌"
};


// 行牌状态各动作状态 等待出牌、出牌、   等待动作、      动作中  
enum TActionState
{
	asWaitChuPai,
	asChuPaiing,
	asWaitDongZuo,
	asDongZuoing
};

// 客户端显示提示动作动画支持的动作类型 吃、碰、杠、听、点炮、胡、自摸
enum THintActAnimType
{
	haatChi,
	haatPeng,
	haatGang,
	haatTing,
	haatDianPao,
	haatHu,
	haatZiMo
};

// 时钟状态     错误     等待开始      等待动作      等待出牌      等待网络事件
// 错误时不显示任何东西、等待动作时不显示箭头、等待网络事件时显示沙漏
enum TTimerState
{
	tsError, tsWaitReady, tsWaitDongZuo, tsWaitChuPai, tsWaitNetEvent
};

enum FlagOfReportToTableMgr
{
	ftmKaiZhuo = 1,
	ftmTuiZhuoTuiKa,
	ftmTuiZhuoBuTuiKa,
	ftmClearAll,
};
const string CAPTION_MJName[MJDATA_TYPE_COUNT] = {
	"一万", "二万", "三万", "四万", "五万", "六万", "七万", "八万", "九万", //万子
	//0     1     2     3     4     5     6     7     8
	"一饼", "二饼", "三饼", "四饼", "五饼", "六饼", "七饼", "八饼", "九饼", //饼子
	//9    10    11    12    13    14    15    16    17
	"一条", "二条", "三条", "四条", "五条", "六条", "七条", "八条", "九条", //条子
	//18   19    20    21    22    23    24    25    26
	"东风", "南风", "西风", "北风", //风牌
	//27      28     29      30
	"红中", "绿发", "白板" //箭牌
    //31      32      33
};

#endif