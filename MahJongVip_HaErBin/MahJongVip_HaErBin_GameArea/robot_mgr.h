#ifndef __ROBOT__MGR__HEAD__
#define __ROBOT__MGR__HEAD__

#include "win32def.h"
#include "util.h"
#include "memory_pool.h"
#include "json_helper.h"
#include "type_mogo.h"
#include "cfg_reader.h"
#include <stdlib.h>
#include <list>
using std::list;
#include <inttypes.h>

class CRobotMgr
{
public:
    CRobotMgr();
    ~CRobotMgr();

    void InitCfg(CCfgReader* cfg);
    void CheckStartReadUserInfo();
    void ReadUserInfoCallback(int retCode, const char*  retMsg, int userIndex, SUserBaseInfo& baseInfo);
    bool IsRobot(int userId);
    SUserInfo* AllocRobotUser(int selScore);
    bool FreeRobotUser(int userId);

    inline bool GetIsInit() const
    {
        return m_isInit;
    }
private:
    void Read1RobotUserInfo(int lastIndex, bool reRead);
    void StartReadRobotUserInfo();
private:
    bool m_isInit;
    bool m_isReading;
    int m_readSuccessCount;
    vector<int> m_allUserId;
    map<int, SUserInfo*> m_allRobot;
    vector<SUserInfo*> m_idleRobot;
    map<int, SUserInfo*> m_gameRobot;
};


#endif
