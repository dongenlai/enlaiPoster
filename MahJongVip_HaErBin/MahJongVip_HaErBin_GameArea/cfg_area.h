#ifndef __CFG__AREA__HEAD__
#define __CFG__AREA__HEAD__

#include "win32def.h"
#include "util.h"
#include "memory_pool.h"
#include "json_helper.h"
#include "cfg_reader.h"
#include "pluto.h"
#include <stdlib.h>
#include <list>
using std::list;
#include <inttypes.h>

struct TMinMax
{
    int Min;
    int Max;

    inline int GetRandom()
    {
        return Min + rand() % (Max - Min);
    }
};

struct SConfigRobot
{
    int max_waitready_sec;

    SConfigRobot();
};

class CConfigArea
{
public:
    CConfigArea();
    ~CConfigArea();

    void InitCfg(CCfgReader* cfg);
public:
	int gameRoomId;
    int area_num;
	int64_t robot_min_bean;
	int64_t robot_max_bean;
	int masterFsId;
    string bean_name;
	int dealCard_Sec;
	int swapCard_Sec;
	int selDelSuit_Sec;
    int max_offline_sec;
	int max_leaveTime_sec;
    int waitDongZuo_sec;
    int discard_sec;
    int table_remain_sec;
	int wait_answer_disband_sec;			// 等待玩家选择是否同意散桌的时间
	int min_interval_quest_disband;			// 申请散桌的最小间隔
	int piao_value;							// 飘值
    int specialGold3;						// 3局扣多少房卡
	int showLastCard_Sec;					// 显示最后一张牌的时间
    string specialGold_name;				// 记分局台费的名字
	uint32_t min_interval_reuse_table;		// 桌子复用的最小时间间隔
	int selectPiaoType_Sec;					// 选择飘类型的时间
    SConfigRobot robot_cfg;
	map<int, int> specialGoldCfg;			// 房卡消费配置

	int playTypeId;
};


#endif
