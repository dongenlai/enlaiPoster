#ifndef __GLOBAL__VAR__HEAD__
#define __GLOBAL__VAR__HEAD__

#include "world_select.h"  // g_pTheWorld class
#include "cfg_area.h"
#include "world_gamearea.h"
#include "table_mgr.h"
#include "mjLogic.h"

extern CConfigArea* g_config_area;
extern CGameTableMgr* g_table_mgr;
extern CMJLogicMgr* g_logic_mgr;

inline CWorldGameArea* GetWorldGameArea()
{
    return (CWorldGameArea*)g_pTheWorld;
}

#endif
