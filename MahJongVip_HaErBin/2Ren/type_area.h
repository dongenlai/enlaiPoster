#ifndef __TYPE__AREA__HEAD__
#define __TYPE__AREA__HEAD__

#include "win32def.h"
#include "util.h"
#include "memory_pool.h"
#include "json_helper.h"
#include "type_mogo.h"
#include <stdlib.h>
#include <list>
using std::list;
#include <inttypes.h>

// 游戏相关
// 最少人数
#define MIN_TABLE_USER_COUNT 2
// 最多人数
#define MAX_TABLE_USER_COUNT 2
// 游戏中是否可以入座  百家乐、梭哈等
#define GAME_CAN_ENTER_WHEN_GAMING false
// 游戏中进入的人是否可以直接游戏，百家乐可以
#define GAME_CAN_DIRECT_GAME false
// 每人最多有多少牌
#define MAX_USER_CARD_COUNT 20
// 发牌动画时间
#define TIME_COUNT_DEAL_CARD 5

// 通用
#define MAX_TABLE_HANDLE_COUNT 1024
#define MAX_USE_TABLE_COUNT 889
#define MIN_CLIENT_VERSTION 1
#define ERROR_CODE_BEAN_TOO_LITTLE 800
#define ERROR_CODE_VERSION_TOO_LITTLE 801
#define ERROR_CODE_TO_MAX_ROUND 802
#define ERROR_CODE_SPECIALGOLD_TOO_LITTLE 803  
#define ERROR_CODE_SOMEONE_LEAVE 804
#define ERROR_CODE_CREATE_TABLE_FAILED 805
#define ERROR_CODE_USER_CLEAR_TABLE 806
#define INVALID_TIME_COUNT -1
#ifndef LLONG_MAX
#define LLONG_MAX    9223372036854775807LL
#endif


// 房间规则
struct TTableRuleInfo
{
    bool isChunJia;                 // 是否为纯夹
    bool isLaizi;                   // 是否带红中宝
    bool isGuaDaFeng;				// 是否带刮大风
    bool isSanQiJia;				// 是否带三期夹	
    bool isDanDiaoJia;              // 是否带单吊夹
    bool isZhiDuiJia;               // 是否带支对胡    
    bool isZhanLiHu;                // 是否带站立胡
    bool isMenQingJiaFen;           // 是否门清加分
    bool isAnKeJiaFen;              // 是否暗刻加分     
    bool isKaiPaiZha;               // 是否开牌炸
    bool isBaoZhongBao;             // 是否带宝中宝
    int  isHEBorDQ;                 // 0:哈尔滨玩法 1：大庆玩法

    TTableRuleInfo(){};
    TTableRuleInfo(TTableRuleInfo& other);
    // 初始化麻将规则
    void setTableRule(bool chunjia, bool hongzhongBao, bool guadafeng, bool sanqijia, bool dandiaojia, bool zhiduijia, bool zhanli, bool menqing, bool anke, bool kaipaizha, bool baozhongbao, int haerbinOrdaqing);
    // 发送当前桌子麻将规则
    void WriteTableRuleToPluto(CPluto& u);
};




// 游戏用户信息
class CPlayerUserInfo
{
public:
    CPlayerUserInfo();
    ~CPlayerUserInfo();
    void Clear();
    void RoundClear();
public:
};

#endif
