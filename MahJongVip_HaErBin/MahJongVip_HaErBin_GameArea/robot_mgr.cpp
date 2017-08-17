/*----------------------------------------------------------------
// 模块名：robot_mgr
// 模块描述：机器人管理器【配置、分配、释放、读取】。
//----------------------------------------------------------------*/


#include "robot_mgr.h"
#include "logger.h"
#include "type_area.h"
#include "mailbox.h"
#include "global_var.h"

// 每次读取几个机器人信息
#define READ_ROBOT_USER_COUNT 3

CRobotMgr::CRobotMgr(): m_isInit(false), m_isReading(false), m_readSuccessCount(0), m_allUserId(), m_allRobot(), m_idleRobot(), m_gameRobot()
{
}

CRobotMgr::~CRobotMgr()
{
    m_allUserId.clear();

    ClearMap(m_allRobot);
    // 3者共用内存
    m_idleRobot.clear();
    m_gameRobot.clear();
}

void CRobotMgr::InitCfg(CCfgReader* cfg)
{
    char buffer[100];
    for(int i = 0; ; i++)
    {
        snprintf(buffer, sizeof(buffer), "id%d", i);
        string sValue = cfg->GetOptValue("robotusers", buffer, "");
        if (sValue.size() < 1)
            break;
        int userId = atoi(sValue.c_str());
        if (userId <= 0)
            break;

        map<int, SUserInfo*>::iterator iter = m_allRobot.find(userId);
        if(m_allRobot.end() != iter)
        {
            LogError("CRobotMgr::InitCfg", "机器人Id重复 userId=%d", userId);
        }
        else
        {
            m_allRobot.insert(make_pair(userId, new SUserInfo()));
            m_allUserId.push_back(userId);
        }
    }

    if (m_allRobot.size() < MAX_TABLE_HANDLE_COUNT * (MAX_TABLE_USER_COUNT - 1))
    {
        LogError("CRobotMgr::InitCfg", "robot too little");
    }

    LogInfo("CRobotMgr::InitCfg", "robotUserCount=%d", m_allRobot.size());
}

void CRobotMgr::CheckStartReadUserInfo()
{
    if (m_isInit)
        return;
    if (m_isReading)
        return;
    if (m_allRobot.size() <= 0)
    {
        m_isInit = true;
        return;
    }

    StartReadRobotUserInfo();
}

void CRobotMgr::ReadUserInfoCallback(int retCode, const char* retMsg, int userIndex, SUserBaseInfo& baseInfo)
{
    if (!m_isReading)
    {
        LogWarning("CRobotMgr::ReadUserInfoCallback", "!m_isReading");
        return;
    }
    
    if (0 != retCode)
    {
        LogWarning("CRobotMgr::ReadUserInfoCallback", "retCode=%d, retMsg=%s", retCode, retMsg);
        Read1RobotUserInfo(userIndex, true);
        return;
    }

    map<int, SUserInfo*>::iterator iterFind = m_allRobot.find(baseInfo.userId);
    if (m_allRobot.end() == iterFind)
    {
        LogWarning("CRobotMgr::ReadUserInfoCallback", "find User failed: userId=%d", baseInfo.userId);
        return;
    }
    if (iterFind->first == iterFind->second->baseInfo.userId)
    {
        LogWarning("CRobotMgr::ReadUserInfoCallback", "user allready read: userId=%d", baseInfo.userId);
        return;
    }
    if (m_allUserId[userIndex] != iterFind->first)
    {
        LogWarning("CRobotMgr::ReadUserInfoCallback", "m_allUserId[userIndex] != userId");
        return;
    }

    SUserInfo* pUserInfo = iterFind->second;
    pUserInfo->baseInfo.CopyFrom(baseInfo);
    m_readSuccessCount++;

    if (m_readSuccessCount >= (int)m_allRobot.size())
    {
        // init idleRobot
        for(map<int, SUserInfo*>::iterator iter = m_allRobot.begin(); m_allRobot.end() != iter; ++iter)
        {
            m_idleRobot.push_back(iter->second);
        }

        m_isReading = false;
        m_isInit = true;
    }
    else
    {
        Read1RobotUserInfo(userIndex, false);
    }
}

bool CRobotMgr::IsRobot(int userId)
{
    return m_allRobot.find(userId) != m_allRobot.end();
}

SUserInfo* CRobotMgr::AllocRobotUser(int selScore)
{
    int len = m_idleRobot.size();
    if (len < 1)
    {
        LogError("CRobotMgr::AllocRobotUser", "robot User all using");
        return NULL;
    }

    int index = rand() % len;
    // 为了用erase
    vector<SUserInfo*>::iterator iter = m_idleRobot.begin() + index;
    SUserInfo* ret = *iter;
    m_gameRobot.insert(make_pair(ret->baseInfo.userId, ret));
    m_idleRobot.erase(iter);

    // 随机bean
    {
        ret->baseInfo.bean = GetRandomRange(g_config_area->robot_min_bean,g_config_area->robot_max_bean);
    }
    //ret->activeInfo.robotReadyMs = GetRandomRange(g_config_area->robot_cfg.ready_min_sec*MS_PER_SEC, g_config_area->robot_cfg.ready_max_sec*MS_PER_SEC);
 
	//ret->activeInfo.selScore = selScore;

    LogInfo("CRobotMgr::AllocRobotUser", "userId=%d idleCount=%d gameCount=%d", ret->baseInfo.userId, m_idleRobot.size(), m_gameRobot.size());

    return ret;
}

bool CRobotMgr::FreeRobotUser(int userId)
{
    map<int, SUserInfo*>::iterator iter = m_gameRobot.find(userId);
    if(m_gameRobot.end() == iter)
    {
        LogError("CRobotMgr::FreeRobotUser", "find user failed. userId=%d", userId);
        return false;
    }

    m_idleRobot.push_back(iter->second);
    m_gameRobot.erase(iter);

    LogInfo("CRobotMgr::FreeRobotUser", "userId=%d idleCount=%d gameCount=%d", userId, m_idleRobot.size(), m_gameRobot.size());
    return true;
}

void CRobotMgr::Read1RobotUserInfo(int lastIndex, bool reRead)
{
    if (m_isInit)
        return;

    CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
    if(mbDbmgr)
    {
        // 找到一个未读用户信息的机器人
        int curIndex = lastIndex;
        if (!reRead)
            curIndex = lastIndex + READ_ROBOT_USER_COUNT;

        if (curIndex >= (int)m_allUserId.size())
        {
            LogInfo("CRobotMgr::Read1RobotUserInfo", "end read: UserIndex=%d", lastIndex);
            return;
        }
        int userId = m_allUserId[curIndex];
        //创建任务
        CAreaTaskReadUserInfo* task = new CAreaTaskReadUserInfo(MSGID_ROBOT_READ_USERINFO, curIndex);
        GetWorldGameArea()->AddTask(task);

        LogInfo("CRobotMgr::Read1RobotUserInfo", "userId=%d", userId);

        // 为了延续task，即使未连接，也要创建task
        if(!mbDbmgr->IsConnected())
        {
            LogWarning("CRobotMgr::Read1RobotUserInfo", "!mbDbmgr->IsConnected()");
        }
        else
        {
            mbDbmgr->RpcCall(GetWorldGameArea( )->GetRpcUtil(), MSGID_DBMGR_READ_USERINFO, task->GetTaskId( ), userId, 5, 0, g_config_area->gameRoomId, 50001001, "" );
        }
    }
    else
    {
        LogError("CRobotMgr::Read1RobotUserInfo", "!mbDbmgr");
    }
}

void CRobotMgr::StartReadRobotUserInfo()
{
    CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
    if(mbDbmgr)
    {
        if(!mbDbmgr->IsConnected())
        {
            LogWarning("CRobotMgr::StartReadRobotUserInfo", "!mbDbmgr->IsConnected()");
            return;
        }
        else
        {
            for(int i = 0; i < READ_ROBOT_USER_COUNT; ++i)
            {
                if (i >= (int)m_allUserId.size())
                    break;

                int userId = m_allUserId[i];
                //创建任务
                CAreaTaskReadUserInfo* task = new CAreaTaskReadUserInfo(MSGID_ROBOT_READ_USERINFO, i);
                GetWorldGameArea()->AddTask(task);

                LogInfo("CRobotMgr::StartReadRobotUserInfo", "userId=%d", userId);

                mbDbmgr->RpcCall( GetWorldGameArea()->GetRpcUtil( ), MSGID_DBMGR_READ_USERINFO, task->GetTaskId( ), userId, 5, 0, g_config_area->gameRoomId, 50001001, "" );

            }

            m_isReading = true;
        }
    }
    else
    {
        LogError("CRobotMgr::StartReadRobotUserInfo", "!mbDbmgr");
    }
}
