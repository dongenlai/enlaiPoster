/*----------------------------------------------------------------
// 模块名：global_var
// 模块描述：全局变量的声明定义
//----------------------------------------------------------------*/


#include "global_var.h"
#include "world_gamearea.h"


world* g_pTheWorld = new CWorldGameArea();
CConfigArea* g_config_area = new CConfigArea();
CRobotMgr* g_robot_mgr = new CRobotMgr();
CGameTableMgr* g_table_mgr = new CGameTableMgr();
CMJLogicMgr* g_logic_mgr = new CMJLogicMgr();
