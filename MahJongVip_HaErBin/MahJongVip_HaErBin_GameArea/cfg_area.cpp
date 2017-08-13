/*----------------------------------------------------------------
// 模块名：cfg_area
// 模块描述：area相关配置信息。
//----------------------------------------------------------------*/


#include "cfg_area.h"
#include "type_mogo.h"
#include "logger.h"
#include "type_area.h"

#define CTotaRate 1000


SConfigRobot::SConfigRobot(): max_waitready_sec(0)
{

}

CConfigArea::CConfigArea() : robot_cfg(), area_num(0), bean_name(""), max_offline_sec(0), \
waitDongZuo_sec(0), discard_sec(0), table_remain_sec(0), gameRoomId(0), masterFsId(0)
{
    
}

CConfigArea::~CConfigArea()
{
}

void CConfigArea::InitCfg(CCfgReader* cfg)
{
	gameRoomId = atoi(cfg->GetValue("params", "gameRoomId").c_str());
	masterFsId = atoi(cfg->GetValue("params", "master_fs_id").c_str());
	area_num = atoi(cfg->GetValue("params", "area_num").c_str());
	if (area_num < 0)
		area_num = 0;
	if (area_num > 999)
		area_num = 999;
	bean_name = cfg->GetValue("params", "bean_name");
	max_offline_sec = atoi(cfg->GetValue("params", "max_offline_sec").c_str());
	max_leaveTime_sec = atoi(cfg->GetValue("params", "max_leaveTime_sec").c_str());
	discard_sec = atoi(cfg->GetValue("params", "discard_sec").c_str());
	waitDongZuo_sec = atoi(cfg->GetValue("params", "waitDongZuo_sec").c_str());
	swapCard_Sec = atoi(cfg->GetValue("params", "swapCard_Sec").c_str());
	selDelSuit_Sec = atoi(cfg->GetValue("params", "selDelSuit_Sec").c_str());
	dealCard_Sec = atoi(cfg->GetValue("params", "dealCard_Sec").c_str());
	table_remain_sec = atoi(cfg->GetValue("params", "table_remain_sec").c_str());
	if (table_remain_sec < 0)
		table_remain_sec = 0;
	specialGold3 = atoi(cfg->GetValue("params", "special_gold3").c_str());
	if (specialGold3 < 0)
		specialGold3 = 1;
	specialGold_name = cfg->GetValue("params", "specialgold_name");
	wait_answer_disband_sec = atoi(cfg->GetValue("params", "wait_answer_disband_sec").c_str());
	min_interval_quest_disband = atoi(cfg->GetValue("params", "min_interval_quest_disband").c_str());
	piao_value = atoi(cfg->GetValue("params", "piao_value").c_str());
	min_interval_reuse_table = atoi(cfg->GetValue("params", "min_interval_reuse_table").c_str());
	showLastCard_Sec = atoi(cfg->GetValue("params", "showLastCard_Sec").c_str());
	selectPiaoType_Sec = atoi(cfg->GetValue("params", "selectPiaoType_Sec").c_str());
	playTypeId = atoi(cfg->GetValue("params", "playTypeId").c_str());
	string tmpStr = cfg->GetValue("params", "specialGoldCfg");
	list<string> tmpList;
	SplitString(tmpStr, '|', tmpList);
	vector<string> tmpInnerList;
	for (list<string>::iterator it = tmpList.begin(); it != tmpList.end(); ++it)
	{
		SplitStringToVector(*it, ':', tmpInnerList);
		int roundNum = stoi(tmpInnerList[0]);
		int specialGoldNum = stoi(tmpInnerList[1]);
		specialGoldCfg.insert(make_pair(roundNum, specialGoldNum));
	}

	robot_cfg.max_waitready_sec = atoi(cfg->GetValue("cfgrobot", "max_waitready_sec").c_str());
}
