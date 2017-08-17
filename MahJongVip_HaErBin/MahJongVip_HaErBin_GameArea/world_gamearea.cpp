/*----------------------------------------------------------------
// 模块描述：区域服务器逻辑
//----------------------------------------------------------------*/

#include "world_gamearea.h"
#include "mailbox.h"
#include "epoll_server.h"
#include "global_var.h"
#include <string.h>
#include <curl/curl.h> 

CWorldGameArea::CWorldGameArea() : m_tryReportStart2FS(false), m_hasReportStart2TableMgr(false)
{
}

CWorldGameArea::~CWorldGameArea()
{
    ClearMap(m_fd2userInfo);
    // 两者公用内存
    m_userId2userInfo.clear();
}

int CWorldGameArea::init(const char* pszEtcFile)
{
    int ret = world::init(pszEtcFile);

    try
    {
        g_config_area->InitCfg(m_cfg);
	    //try rebot
		g_robot_mgr->InitCfg(m_cfg);
    }
    catch (CException & ex)
    {
        LogError("CWorldGameArea::init", "error: %s", ex.GetMsg().c_str());
        return -1;
    }

    return ret;
}

int CWorldGameArea::OnFdClosed(int fd)
{
    map<int, SUserInfo*>::iterator iter = m_fd2userInfo.find(fd);
    if(m_fd2userInfo.end() == iter)
    {
        LogInfo("CWorldGameArea::OnFdClosed", "not login fd=%d", fd);
        return -1;
    }

    SUserInfo* pUser = iter->second;
    m_fd2userInfo.erase(iter);
    int userId = pUser->baseInfo.userId;
    if (userId > 0)
    {
        m_userId2userInfo.erase(userId);
        g_table_mgr->OnUserOffline(userId);
    }

    LogInfo("CWorldLogin::OnFdClosed", "fd=%d;userId=%d", fd, userId);
    delete pUser;
    return 0;
}

int CWorldGameArea::FromRpcCall(CPluto& u)
{
    if (world::FromRpcCall(u) < 0)
        return -1;

    pluto_msgid_t msg_id = u.GetMsgId();
    if(!CheckClientRpc(u))
    {
        LogWarning("FromRpcCall", "invalid rpcall error.unknown msgid:%d\n", msg_id);
        return -1;
    }

    T_VECTOR_OBJECT* p = m_rpc.Decode(u);
    if(p == NULL)
    {
        LogWarning("FromRpcCall", "rpc decode error.unknown msgid:%d\n", msg_id);
        return -1;
    }

    if(u.GetDecodeErrIdx() > 0)
    {
        ClearTListObject(p);
        LogWarning("FromRpcCall", "rpc decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
        return -2;
    }

    int nRet = -1;
    switch(msg_id)
    {
    case MSGID_CLIENT_SIT:
        {
            nRet = ProcClientSit(p, u.GetSrcFd());
            break;
        }
    case MSGID_CLIENT_CHAT:
        {
            SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
            if(pUser)
            {
                int chairIndex = 0;
                CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
                if(pTable)
                    nRet = pTable->ProcClientChat(p, chairIndex);
            }

            break;
        }
    case MSGID_CLIENT_READY:
        {
            SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
            if(pUser)
            {
                int chairIndex = 0;
                CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
                if(pTable)
                    nRet = pTable->ProcClientReady(p, chairIndex);
            }

            break;
        }
    case MSGID_CLIENT_G_TRUST:
        {
            SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
            if(pUser)
            {
                int chairIndex = 0;
                CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
                if(pTable)
                    nRet = pTable->ProcClientTrust(p, chairIndex);
            }

            break;
        }
    case MSGID_CLIENT_G_SWAP_CARD:
        {
            SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
            if(pUser)
            {
                int chairIndex = 0;
                CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
                if(pTable)
                    nRet = pTable->ProcClientSwapCards(p, chairIndex);
            }

            break;
        }
	case MSGID_CLIENT_G_SEL_DEL_SUIT:
		{
			SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
			if (pUser)
			{
				int chairIndex = 0;
				CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
				if (pTable)
					nRet = pTable->ProcClientSelDelSuit(p, chairIndex);
			}

			break;
		}
	case MSGID_CLIENT_G_SPECIAL_GANG:
		{
			SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
			if (pUser)
			{
				int chairIndex = 0;
				CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
				if (pTable)
					nRet = pTable->ProcClientSpecialGang(p, chairIndex);
			}
			break;
		}
	case MSGID_CLIENT_G_CHU:
	{
		SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
		if (pUser)
		{
			int chairIndex = 0;
			CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
			if (pTable)
				nRet = pTable->procClientChu(p, chairIndex);
		}

		break;
	}
	case MSGID_CLIENT_G_MJ_ACTION:
	{
		SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
		if (pUser)
		{
			int chairIndex = 0;
			CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
			if (pTable)
				nRet = pTable->procClientMJAction(p, chairIndex);
		}

		break;
	}
	case MSGID_CLIENT_QUEST_CTRL_TABLE:
	{
		SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
		if (pUser)
		{
			int chairIndex = 0;
			CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
			if (pTable)
				nRet = pTable->ProcClientCtrlTable(p, chairIndex);
		}

		break;
	}
	case MSGID_CLIENT_QUEST_LEAVE:
	{
		SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
		if (pUser)
		{
			int chairIndex = 0;
			CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
			if (pTable)
			{
				nRet = pTable->ProcClientLeaveTable(p, chairIndex);
			}
		}

		break;
	}
	case MSGID_CLIENT_GET_TINGINFO:
	{
		SUserInfo* pUser = FindUserByFd(u.GetSrcFd());
		if (pUser)
		{
			int chairIndex = 0;
			CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
			if (pTable)
			{
				nRet = pTable->ProcClientGetTingInfo(p, chairIndex);
			}
		}

		break;
	}
    case MSGID_CLIENT_LOGIN:
        {
            nRet = ProcClientLogin(p, u.GetSrcFd());
            break;
        }
    case MSGID_CLIENT_UPDATE_USERINFO:
        {
            nRet = ProcClientUpdateUserInfo(p, u.GetSrcFd());
            break;
        }
    case MSGID_AREA_READ_USERINFO_CALLBACK:
        {
            nRet = ProcReadUserInfoCallback(p);
            break;
        }
    case MSGID_AREA_REPORT_SCORE_CALLBACK:
        {
            nRet = ProcScoreReportCallback(p);
            break;
        }
    case MSGID_AREA_CONSUME_SPECIAL_GOLD_CALLBACK:
        {
            nRet = ProcConsumeSpecialGoldCallBack(p);
            break;
        }
    case MSGID_AREA_REPORT_TOTAL_SCORE_CALLBACK:
        {
            nRet = ProcTotalScoreReportCallBack(p);
            break;
        }
	case MSGID_AREA_START_REPORT_CALLBACK:
		{
			nRet = ProcStartReportCallBack(p);
			break;
		}
	case MSGID_AREA_LOCK_GAMEROOM_CALLBACK:
		{
			nRet = ProcLockOrUnlockReportCallBack(p);
			break;
		}
	case MSGID_AREA_REPORT_TABlE_MANAGER_CALLBACK:
		{
			nRet = ProcReportToTableManagerCallBack(p);
			break;
		}
	case MSGID_AREA_REPORT_TABLE_START_CALLBACK:
		{
			nRet = ProcReportTableStartCallBack(p);
			break;
		}
    case MSGID_CLIENT_ONTICK:
        {
            nRet = ProcClientOnTick(p, u.GetSrcFd());
            break;
        }
    case MSGID_CLIENT_BULLETIN_NOTIFY:
        {
            nRet = SendBulletin(p);
            break;
        }
    case MSGID_ALLAPP_SHUTDOWN_SERVER:
        {
            nRet = ShutdownServer(p);
            break;
        }
    default:
        {
            LogWarning("CWorldLogin::from_rpc_call", "unknown msgid:%d\n", msg_id);
            break;
        }
    }

    if(nRet != 0)
    {
        LogWarning("from_rpc_call", "rpc error.msg_id=%d;ret=%d\n", msg_id, nRet);
    }
    else
    {
        CMailBox* mb = GetServer()->GetFdMailbox(u.GetSrcFd());
        if (mb)
            mb->SetLastPackTime();
    }

    ClearTListObject(p);

    return 0;
}
    
void CWorldGameArea::OnThreadRun()
{
    world::OnThreadRun();

    // 错开时间
	if (m_checkTaskTime.GetPassMsTick() > 1011)
	{
		if (!m_tryReportStart2FS)
		{
			ReportStart2FS();
		}
		CheckTaskListTimeOut();
	}
	//try rebot
	/*if (m_checkReadRobotUserInfoTime.GetPassMsTick() > 1015)
	{
		LogInfo("cWorldGameArea::OnThreadRun", "创建机器人任务");
		m_checkReadRobotUserInfoTime.SetNowTime();
		g_robot_mgr->CheckStartReadUserInfo();
	}*/

	if (m_reportNumTime.GetPassMsTick() > 5013)
	{
		if (!m_hasReportStart2TableMgr)
		{
			g_table_mgr->ReportToTableManager(nullptr, ftmClearAll, 0);
		}
		ReportAreaInfoToMgr();
	}
    if (m_checkUserTimeoutTime.GetPassMsTick() > 1018){
        m_checkUserTimeoutTime.SetNowTime();
        int count = GetServer()->CheckUserTimeout();
        if (count > 0)
            LogInfo("CWorldGameArea::OnThreadRun", "CheckUserTimeout count=%d", count);
    }
    // 桌子定时器
    g_table_mgr->RunTime();
}

void CWorldGameArea::OnServerStart()
{
    world::OnServerStart();
}

int CWorldGameArea::ProcClientLogin(T_VECTOR_OBJECT* p, int srcFd)
{
    if(p->size() != 4)
    {
        LogWarning("CWorldGameArea::ProcClientLogin", "p->size() error");
        return -1;
    }

    int index = 0;
    string& accessToken = VOBJECT_GET_SSTR((*p)[index++]);
    string& mac = VOBJECT_GET_SSTR((*p)[index++]);
    int32_t whereFrom = (*p)[index++]->vv.i32;
    int32_t version = (*p)[index++]->vv.i32;

    CMailBox* mb = GetServer()->GetFdMailbox(srcFd);
    if(!mb)
    {
        LogWarning("CWorldGameArea::ProcClientLogin", "!mb");
        return -1;
    }

    if(m_fd2userInfo.find(srcFd) != m_fd2userInfo.end())
    {
        //同一个连接上的重复认证,不给错误提示
        LogInfo("CWorldLogin::ProcClientLogin", "login is in progress;fd=%d", srcFd);
        return 0;
    }

    SUserInfo* pUser = new SUserInfo();
    pUser->activeInfo.fd = srcFd;
    pUser->activeInfo.whereFrom = whereFrom;
    pUser->activeInfo.mac = mac;

	char* clientIP = mb->GetClientIP();
	if (clientIP != NULL)
		pUser->activeInfo.ip = clientIP;// mb->GetIp();

    m_fd2userInfo.insert(make_pair(srcFd, pUser));

    CMailBox* mbDbmgr = this->GetServerMailbox(SERVER_DBMGR);
    if(mbDbmgr)
    {
        if(!mbDbmgr->IsConnected())
        {
            LogWarning("CWorldGameArea::ProcClientLogin", "!mbDbmgr->IsConnected()");
            ClientLoginResponse(srcFd, 100, "服务器维护中");
            return 0;
        }
        if (version < MIN_CLIENT_VERSTION)
        {
            ClientLoginResponse(srcFd, ERROR_CODE_VERSION_TOO_LITTLE, "您的客户端版本太低，请升级后再登录");
            return 0;
        }

		//try rebot
		/*if (!g_robot_mgr->GetIsInit())
		{
			LogWarning("CWorldGameArea::ProcClientLogin", "!g_robot_mgr->GetIsInit()");
			ClientLoginResponse(srcFd, 100, "服务器维护中");
		}*/


        //创建任务
        CAreaTaskReadUserInfo* task = new CAreaTaskReadUserInfo(MSGID_CLIENT_LOGIN, srcFd);
        m_taskList.insert(make_pair(task->GetTaskId(), task));

        LogInfo("CWorldLogin::ProcClientLogin", "client login ip=%s;fd=%d;usercount=%d;taskcount=%d", mb->GetIp().c_str(), srcFd, m_fd2userInfo.size(), m_taskList.size());

        //mbDbmgr->RpcCall(GetRpcUtil(), MSGID_DBMGR_READ_USERINFO, task->GetTaskId(), (int32_t)0, accessToken);
		int gameLock = 0;
		int gameRoomId = g_config_area->gameRoomId;

		CPluto* pu = new CPluto;
		(*pu).Encode(MSGID_DBMGR_READ_USERINFO) << task->GetTaskId() << (int32_t)0 << accessToken << gameLock << gameRoomId;
		(*pu) << EndPluto;
		mbDbmgr->PushPluto(pu);
    }
    else
    {
        LogError("CWorldGameArea::ProcClientLogin", "!mbDbmgr");
    }

    return 0;
}

int CWorldGameArea::ProcClientUpdateUserInfo(T_VECTOR_OBJECT* p, int srcFd)
{
    if(p->size() != 0)
    {
        LogWarning("CWorldGameArea::ProcClientUpdateUserInfo", "p->size() error");
        return -1;
    }

    CMailBox* mb = GetServer()->GetFdMailbox(srcFd);
    if(!mb)
    {
        LogWarning("CWorldGameArea::ProcClientUpdateUserInfo", "!mb");
        return -1;
    }

    SUserInfo* pUser = FindUserByFd(srcFd);
    if(!pUser)
    {
        LogWarning("CWorldLogin::ProcClientUpdateUserInfo", "cannot find user;fd=%d", srcFd);
        return -1;
    }

    int userId = pUser->baseInfo.userId;

    CMailBox* mbDbmgr = this->GetServerMailbox(SERVER_DBMGR);
    if(mbDbmgr)
    {
        if(!mbDbmgr->IsConnected())
        {
            LogWarning("CWorldGameArea::ProcClientUpdateUserInfo", "!mbDbmgr->IsConnected()");
            //直接登录失败
            ClientUpdateUserInfoResponse(srcFd, 100, "服务器维护中");
        }
        else
        {
            //创建任务
            CAreaTaskReadUserInfo* task = new CAreaTaskReadUserInfo(MSGID_CLIENT_UPDATE_USERINFO, srcFd);
            m_taskList.insert(make_pair(task->GetTaskId(), task));

            LogInfo("CWorldLogin::ProcClientUpdateUserInfo", "userId=%d;fd=%d;usercount=%d;taskcount=%d", userId, srcFd, m_fd2userInfo.size(), m_taskList.size());

            mbDbmgr->RpcCall(GetRpcUtil(), MSGID_DBMGR_READ_USERINFO, task->GetTaskId(), userId, "");
        }
    }
    else
    {
        LogError("CWorldGameArea::ProcClientUpdateUserInfo", "!mbDbmgr");
    }

    return 0;
}

int CWorldGameArea::ProcReadUserInfoCallback(T_VECTOR_OBJECT* p)
{
    if(p->size() != 16)
    {
        LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "p->size() error ");
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
    if(m_taskList.end() == iterTask)
    {
        LogWarning("CWorldGameArea::ProcReadUserInfoCallback", "m_taskList.end() == iter");
        return -1;
    }
    CAreaTaskReadUserInfo* task = (CAreaTaskReadUserInfo*)iterTask->second;
    m_taskList.erase(iterTask);
    // 自动释放内存
    auto_new1_ptr<CAreaTaskReadUserInfo> atask(task);
    int clientFd = task->GetClientFd();

    int32_t retCode = (*p)[index++]->vv.i32;
    string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);
    SUserBaseInfo baseInfo;
    baseInfo.ReadFromVObj(*p, index);
	//try rebot
	//if (MSGID_ROBOT_READ_USERINFO == task->GetMsgId())
	//{
	//	g_robot_mgr->ReadUserInfoCallback(retCode, retErrorMsg.c_str(), clientFd, baseInfo);
	//	return 0;
	//}
    CMailBox* mb = GetServer()->GetFdMailbox(clientFd);
    if(!mb)
    {
        LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "!mb");
        return -1;
    }

    SUserInfo* pUser = FindUserByFd(clientFd);
    if(!pUser)
    {
        LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "find user failed");
        return -1;
    }

    switch (task->GetMsgId())
    {
    case MSGID_CLIENT_LOGIN:
        {
            // 登录返回
            if(0 != retCode)
            {
                return ClientLoginResponse(clientFd, retCode, retErrorMsg.c_str());
            }
            else
            {
				if (m_fd2userInfo.size() >= 900)
				{
					retCode = 900;
					retErrorMsg = "服务器爆满";
					return ClientLoginResponse(clientFd, retCode, retErrorMsg.c_str());
				}


				// try rebot  机器人不让登录，否则会错乱
				if (g_robot_mgr->IsRobot(baseInfo.userId))
				{
					return ClientLoginResponse(clientFd, 1003, "帐号不存在");
				}

                if(EUS_NONE != pUser->activeInfo.userState)
                {
                    LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "EUS_NONE != pUser->ativeInfo.userState");
                    return -1;
                }

                map<int, SUserInfo*>::const_iterator iter = m_userId2userInfo.find(baseInfo.userId);
                if(iter != m_userId2userInfo.end())
                {
                    SUserInfo* pOldUser = iter->second;
                    int fdOld = pOldUser->activeInfo.fd;
                    if(clientFd == fdOld)
                    {
                        //同一个连接上的重复认证,不给错误提示
                        LogInfo("CWorldLogin::ProcReadUserInfoCallback", "login is in progress(2);userId=%d, fd=%d", baseInfo.userId, fdOld);
                        return 0;
                    }
                    else
                    {
                        LogInfo("CWorldLogin::ProcReadUserInfoCallback", "multilogin,kick off old;userId=%d;fd=%d;old=%d", \
                            baseInfo.userId, clientFd, fdOld);

                        GetServer()->CloseFdFromServer(fdOld);
                    }
                }

                //账号校验通过
                mb->SetAuthz(MAILBOX_CLIENT_AUTHZ);

                //添加帐号到对应关系
                pUser->baseInfo.CopyFrom(baseInfo);
                pUser->activeInfo.userState = EUS_AUTHED;
                m_userId2userInfo.insert(make_pair(pUser->baseInfo.userId, pUser));

                // 检测断线返回
                bool isOfflineRet = false;
                CGameTable* pTable = NULL;
                int chairIndex = 0;
                {
                    int userId = pUser->baseInfo.userId;
                    pTable = g_table_mgr->GetUserTable(userId, chairIndex);
                    if(pTable)
                    {
                        isOfflineRet = pTable->EnterTable(pUser, chairIndex, false);
                        if(!isOfflineRet)
                        {
                            LogError("CWorldGameArea::ProcReadUserInfoCallback", "EnterTable failed");
                        }
                    }
                }
                if (!isOfflineRet)
                {
                    return ClientLoginResponse(clientFd, retCode, retErrorMsg.c_str());
                }
                else
                {
                    // 先通知登录成功
                    ClientLoginResponse(clientFd, retCode, retErrorMsg.c_str());
                    // 通知开始游戏
                    pTable->SendStartGameNotify(chairIndex);
                    LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "offline return success userId=%d table=%d chairIndex=%d", \
                        pUser->baseInfo.userId, pTable->GetHandle(), chairIndex);

                    return 0;
                }
            }

            break;
        }
    case MSGID_CLIENT_UPDATE_USERINFO:
        {
            // 刷新用户信息返回
            if(0 != retCode)
            {
                return ClientUpdateUserInfoResponse(clientFd, retCode, retErrorMsg.c_str());
            }
            else
            {
                //刷新用户信息
                pUser->baseInfo.CopyFrom(baseInfo);
                int chairIndex = 0;
                CGameTable* pTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
                if(pTable)
                    pTable->ClientUpdateUserInfo(baseInfo, chairIndex);

                return ClientUpdateUserInfoResponse(clientFd, retCode, retErrorMsg.c_str());
            }

            break;
        }
    default:
        {
            LogInfo("CWorldGameArea::ProcReadUserInfoCallback", "task->GetMsgId() not found");
            return -1;

            break;
        }
    }
}

int CWorldGameArea::ProcScoreReportCallback(T_VECTOR_OBJECT* p)
{
    if(p->size() != 4)
    {
        LogInfo("CWorldGameArea::ProcScoreReportCallback", "p->size() error");
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
    if(m_taskList.end() == iterTask)
    {
        LogWarning("CWorldGameArea::ProcScoreReportCallback", "m_taskList.end() == iter");
        return -1;
    }
    CAreaTaskReportScore* task = (CAreaTaskReportScore*)iterTask->second;
    m_taskList.erase(iterTask);
    // 自动释放内存
    auto_new1_ptr<CAreaTaskReportScore> atask(task);
    CGameTable* pTable = g_table_mgr->GetTableByHandle(task->GetTableHandle());
    if(!pTable)
    {
        LogError("CWorldGameArea::ProcScoreReportCallback", "find table failed!");
        return -1;
    }

    int32_t retCode = (*p)[index++]->vv.i32;
    string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);
    if(0 != retCode)
    {
        pTable->OnReportScoreError(retCode, retErrorMsg.c_str());
    }
    else
    {
        pTable->OnReportScoreSuccess(p, index);
    }

    return 0;
}

int CWorldGameArea::ProcConsumeSpecialGoldCallBack(T_VECTOR_OBJECT *p)
{
    if (p->size() != 4)
    {
        LogInfo("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "p->size() error");
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
    if (m_taskList.end() == iterTask)
    {
        LogWarning("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "m_taskList.end() == iter");
        return -1;
    }
    CAreaTaskConsumeSpecialGold* task = (CAreaTaskConsumeSpecialGold*)iterTask->second;
    m_taskList.erase(iterTask);
    // 自动释放内存
    auto_new1_ptr<CAreaTaskConsumeSpecialGold> atask(task);
    CGameTable* pTable = g_table_mgr->GetTableByHandle(task->GetTableHandle());
    if (!pTable)
    {
        LogError("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "find table failed!");
        return -1;
    }

    int32_t retCode = (*p)[index++]->vv.i32;
    string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);
    //目前是这样处理，之后可能会有变化
    if (0 != retCode)
    {
        // 一次失败，下次就不收取了。
        pTable->SetIsConsumeSpecialGold(true);
        LogError("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "consume specialGold failed!");
        pTable->OnReportConsumeSpecialGoldError(p, index);
    }
    else
    {
        pTable->SetIsConsumeSpecialGold(true);
        LogInfo("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "consume specialGold success!");
        pTable->OnReportConsumeSpecialGoldSuccess(p, index);
    }

    return 0;
}

int CWorldGameArea::ProcTotalScoreReportCallBack(T_VECTOR_OBJECT* p)
{
    if (p->size() != 3)
    {
        LogInfo("CWorldGameArea::ProcTotalScoreReportCallBack", "p->size() error");
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
    if (m_taskList.end() == iterTask)
    {
        LogWarning("CWorldGameArea::ProcTotalScoreReportCallBack", "m_taskList.end() == iter");
        return -1;
    }
    CAreaTaskReportTotalScore* task = (CAreaTaskReportTotalScore*)iterTask->second;
    m_taskList.erase(iterTask);
    // 自动释放内存
    auto_new1_ptr<CAreaTaskReportTotalScore> atask(task);
    CGameTable* pTable = g_table_mgr->GetTableByHandle(task->GetTableHandle());
    if (!pTable)
    {
        LogError("CWorldGameArea::ProcTotalScoreReportCallBack", "find table failed!");
        return -1;
    }

    int32_t retCode = (*p)[index++]->vv.i32;
    string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);
    pTable->OnReportTotalScoreCallBack(retCode, retErrorMsg.c_str());

    return 0;
}

int CWorldGameArea::ProcStartReportCallBack(T_VECTOR_OBJECT *p)
{
	if (p->size() != 5)
	{
		LogInfo("CWorldGameArea::ProcStartReportCallBack", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
	if (m_taskList.end() == iterTask)
	{
		LogWarning("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "m_taskList.end() == iter");
		return -1;
	}
	CAreaTaskStartReport2FS* task = (CAreaTaskStartReport2FS*)iterTask->second;
	m_taskList.erase(iterTask);
	// 自动释放内存
	auto_new1_ptr<CAreaTaskStartReport2FS> atask(task);

	int32_t retCode = (*p)[index++]->vv.i32;
	string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);
	int32_t fsId = (*p)[index++]->vv.i32;
	int32_t gameServerId = (*p)[index++]->vv.i32;


	if (0 != retCode)
	{
		// 向主FS上报失败，则直接关闭游戏服务器
		LogWarning("CWorldGameArea::ProcStartReportCallBack", "report to FS failed!");
		GetServer()->Shutdown();
	}
	else
	{
		m_tryReportStart2FS = true;
		LogInfo("CWorldGameArea::ProcStartReportCallBack", "report to FS success!, fsId = %d, gameServerId = %d", fsId, gameServerId);
	}

	return 0;
}

int CWorldGameArea::ProcLockOrUnlockReportCallBack(T_VECTOR_OBJECT *p)
{
	if (p->size() != 3)
	{
		LogInfo("CWorldGameArea::ProcLockOrUnlockReportCallBack", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
	if (m_taskList.end() == iterTask)
	{
		LogWarning("CWorldGameArea::ProcConsumeSpecialGoldCallBack", "m_taskList.end() == iter");
		return -1;
	}
	CAreaTaskStartReport2FS* task = (CAreaTaskStartReport2FS*)iterTask->second;
	m_taskList.erase(iterTask);
	// 自动释放内存
	auto_new1_ptr<CAreaTaskStartReport2FS> atask(task);

	int32_t retCode = (*p)[index++]->vv.i32;
	string& retErrorMsg = VOBJECT_GET_SSTR((*p)[index++]);

	if (0 != retCode)
	{
		LogError("CWorldGameArea::ProcLockOrUnlockReportCallBack", "%s", retErrorMsg.c_str());
		return -1;
	}

	return 0;
}

int CWorldGameArea::ProcReportToTableManagerCallBack(T_VECTOR_OBJECT *p)
{
	if (p->size() != 3)
	{
		LogInfo("CWorldGameArea::ProcReportToTableManagetCallBack", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	int32_t retCode = (*p)[index++]->vv.i32;
	string& retErrorMsg = *(*p)[index++]->vv.s;

	map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
	if (m_taskList.end() == iterTask)
	{
		LogWarning("CWorldGameArea::ProcReportToTableManagetCallBack", "m_taskList.end() == iter");
		return -1;
	}
	CAreaTaskReportTableManager* task = (CAreaTaskReportTableManager*)iterTask->second;
	m_taskList.erase(iterTask);
	// 自动释放内存
	auto_new1_ptr<CAreaTaskReportTableManager> atask(task);

	int tableHandle = task->GetTableHandle();
	int flag = task->GetFlag();

	if (ftmKaiZhuo == flag)
	{
		// 创建桌子的情况
		int clientFd = task->GetClientFd();
		ClientSitResponse(retCode, tableHandle, clientFd);
	}
	else
	{
		// 不是创建桌子的情况
		if (0 != retCode)
		{
			LogError("CWorldGameArea::ProcReportToTableManagetCallBack", "上报失败 flag = %d", flag);
		}
		else
		{
			LogInfo("CWorldGameArea::ProcReportToTableManagetCallBack", "上报成功 flag = %d", flag);
			if (ftmClearAll == flag)
				m_hasReportStart2TableMgr = true;
		}
	}

	return 0;
}

int CWorldGameArea::ProcReportTableStartCallBack(T_VECTOR_OBJECT *p)
{
	if (p->size() != 3)
	{
		LogInfo("CWorldGameArea::ProcReportTableStartCallBack", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	int32_t retCode = (*p)[index++]->vv.i32;
	string& retErrorMsg = *(*p)[index++]->vv.s;

	map<uint32_t, CAreaTaskItemBase*>::iterator iterTask = m_taskList.find(taskId);
	if (m_taskList.end() == iterTask)
	{
		LogWarning("CWorldGameArea::ProcReportTableStartCallBack", "m_taskList.end() == iter");
		return -1;
	}
	CAreaTaskReportTableStart* task = (CAreaTaskReportTableStart*)iterTask->second;
	m_taskList.erase(iterTask);
	// 自动释放内存
	auto_new1_ptr<CAreaTaskReportTableStart> atask(task);

	int tableHandle = task->GetTableHandle();

	if (retCode != 0)
		LogError("CWorldGameArea::ProcReportTableStartCallBack", "上报游戏开始状态失败 tableHandle = %d, errorMsg：%s", tableHandle, retErrorMsg.c_str());
	else
		LogInfo("CWorldGameArea::ProcReportTableStartCallBack", "上报游戏开始状态成功 tableHandle = %d", tableHandle);

	return 0;
}

void CWorldGameArea::ClientSitResponse(int retCode, int tableHandle, int clientFd)
{
	int tmpRetCode = 0;
	string tmpRetMsg("");
	int vipRoomType = vrtScoreOnePay;
	CGameTable* pEnterTable = nullptr;
	SUserInfo* pUser = nullptr;
	CMailBox* mb;
	int enterChair = 0;
	try
	{
		pEnterTable = g_table_mgr->GetTableByHandle(tableHandle);
		mb = GetServer()->GetFdMailbox(clientFd);
		if (!mb)
		{
			if (pEnterTable)
				pEnterTable->SetIsCreated(false);
			if (0 == retCode && pEnterTable)
			{
				// 需要退房
				if (pEnterTable->GetVipRoomType() == vrtScoreOnePay)
					g_table_mgr->ReportToTableManager(pEnterTable, ftmTuiZhuoTuiKa, clientFd);
				else
					g_table_mgr->ReportToTableManager(pEnterTable, ftmTuiZhuoBuTuiKa, clientFd);
			}
			LogInfo("CWorldGameArea::ClientSitResponse", "!mb");
			return;
		}

		pUser = FindUserByFd(clientFd);
		if (!pUser)
		{
			// 这里一定要把桌子置为not isCreated，否则桌子可能不会被复用
			pEnterTable->SetIsCreated(false);
			if (0 == retCode)
			{
				// 需要退房
				if (pEnterTable->GetVipRoomType() == vrtScoreOnePay)
					g_table_mgr->ReportToTableManager(pEnterTable, ftmTuiZhuoTuiKa, clientFd);
				else
					g_table_mgr->ReportToTableManager(pEnterTable, ftmTuiZhuoBuTuiKa, clientFd);
			}
			LogError("CWorldGameArea::ClientSitResponse", "find user find user fail");
			return;
		}

		if (!pEnterTable)
		{
			ThrowException(201, "创建牌局失败，找不到桌子");
		}

		if (0 != retCode)
		{
			// 这里一定要把桌子置为not isCreated，否则桌子可能不会被复用
			pEnterTable->SetIsCreated(false);
			ThrowException(202, "创建牌局失败，您不能再多开牌局");
		}

		int emptyChairAry[MAX_TABLE_USER_COUNT];
		int emptyCount = pEnterTable->GetEmptyChairAry(emptyChairAry);
		if (emptyCount < 1)
			ThrowException(11, "牌局已满");
		enterChair = emptyChairAry[0];
		if (!pEnterTable->EnterTable(pUser, enterChair, false))
			ThrowException(12, "入坐失败");

	}
	catch (CException& ex)
	{
		tmpRetCode = ex.GetCode();
		tmpRetMsg = ex.GetMsg();
	}

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_CLIENT_SIT_RESP) << tmpRetCode << tmpRetMsg << pUser->activeInfo.userState <<
		vipRoomType << g_config_area->discard_sec
		<< g_config_area->waitDongZuo_sec << EndPluto;
	mb->PushPluto(pu);

	if (0 == tmpRetCode && pEnterTable)
	{
		pEnterTable->SendStartGameNotify(enterChair);
		if (pEnterTable->GetVipRoomType() == vrtScoreOnePay)
		{
			// 如果是房主付费方式，需要房间的消费房卡bool值置为true
			// 因为房主付费的房卡扣除是在上报tableManager时扣除的，不是在consumeSpecialGold时扣除，
			// 置位是为了防止重复消费
			pEnterTable->SetIsConsumeSpecialGold(true);
		}
	}
}

int CWorldGameArea::ProcClientOnTick(T_VECTOR_OBJECT* p, int srcFd)
{
    if(p->size() != 1)
    {
        LogWarning("CWorldGameArea::ProcClientOnTick", "p->size() error");
        return -1;
    }

    int index = 0;
    uint32_t tick = (*p)[index++]->vv.u32;

    CMailBox* mb = GetServer()->GetFdMailbox(srcFd);
    if(!mb)
    {
        LogWarning("CWorldGameArea::ProcClientOnTick", "!mb");
        return -1;
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_CLIENT_ONTICK_RESP) << tick << EndPluto;
    mb->PushPluto(pu);

    return 0;
}

int CWorldGameArea::ProcClientSit(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 20)
    {
        LogWarning("CWorldGameArea::ProcClientSit", "p->size() error");
        return -1;
    }

    int index = 0;
    float64_t jingDu = (*p)[index++]->vv.f64;
    float64_t weiDu = (*p)[index++]->vv.f64;
    int32_t isFind = (*p)[index++]->vv.i32;
    int32_t selScore = (*p)[index++]->vv.i32;
    int32_t totalRound = (*p)[index++]->vv.i32;
    int32_t vipRoomType = (*p)[index++]->vv.i32;

    int32_t isChunJia = (*p)[index++]->vv.i32;
    int32_t isLaizi = (*p)[index++]->vv.i32;
    int32_t isGuaDaFeng = (*p)[index++]->vv.i32;
    int32_t isSanQiJia = (*p)[index++]->vv.i32;
    int32_t isDanDiaoJia = (*p)[index++]->vv.i32;
    int32_t isZhiDuiJia = (*p)[index++]->vv.i32;
    int32_t isZhanLiHu = (*p)[index++]->vv.i32;
    int32_t isMenQing = (*p)[index++]->vv.i32;
    int32_t isAnke = (*p)[index++]->vv.i32;
    int32_t isKaiPaiZha = (*p)[index++]->vv.i32;
    int32_t isBZB = (*p)[index++]->vv.i32;
    int32_t isHaOrHeiLongJiang = (*p)[index++]->vv.i32;
	int32_t isJiQiRen = (*p)[index++]->vv.i32;

    string tableNum = *(*p)[index++]->vv.s;
    
    LogInfo("ProcClientSit", "fd=%d, jingDu=%f, weiDu=%f, isFind=%d, selScore=%d totalRound=%d, tableNum=%s ", 
		srcFd, jingDu, weiDu, isFind, selScore, totalRound, tableNum.c_str());

    LogInfo("ProcClientSit", "isChunJia=%d, isLaizi=%d, isGuaDaFeng=%d, isSanQiJia=%d, isDanDiaoJia=%d isZhiDuiJia=%d, isZhanLiHu=%d, isBaoZhongBao=%d, isHEBorHeiLongJiang=%d",
		isChunJia, isLaizi, isGuaDaFeng, isSanQiJia, isDanDiaoJia, isZhiDuiJia, isZhanLiHu, isBZB, isHaOrHeiLongJiang);

    SUserInfo* pUser = FindUserByFd(srcFd);
    if(!pUser)
    {
        LogWarning("CWorldGameArea::ProcClientSit", "find user error");
        return -1;
    }

    CMailBox* mb = GetServer()->GetFdMailbox(srcFd);
    if(!mb)
    {
        LogWarning("CWorldGameArea::ProcClientSit", "!mb");
    }

    int32_t retCode = 0;
    string retMsg = "";
    CGameTable* pEnterTable = NULL;
    int enterChair = -1;
    try
    {
        if (0 == isFind)
        {
            // create table
            if (totalRound <= 0)
                ThrowException(101, "参数错误");
            if (vipRoomType < vrtBean || vipRoomType > vrtScoreOnePay)
                ThrowException(102, "参数错误");
			// 暂时不做现金局
			if (vipRoomType == vrtBean)
			{
				ThrowException(103, "不支持现金局");
			}
            // 判断房间规则参数
            if ((isChunJia != 0) && (isChunJia != 1))
				ThrowException(1001, "参数错误");
            if ((isLaizi != 0) && (isLaizi != 1))
				ThrowException(1002, "参数错误");
            if ((isGuaDaFeng != 0) && (isGuaDaFeng != 1))
                ThrowException(1003, "参数错误");
            if ((isSanQiJia != 0) && (isSanQiJia != 1))
                ThrowException(1004, "参数错误");
            if ((isDanDiaoJia != 0) && (isDanDiaoJia != 1))
                ThrowException(1005, "参数错误");
            if ((isZhiDuiJia != 0) && (isZhiDuiJia != 1))
                ThrowException(1006, "参数错误");
            if ((isZhanLiHu != 0) && (isZhanLiHu != 1))
                ThrowException(1007, "参数错误");
            if ((isMenQing != 0) && (isMenQing != 1))
                ThrowException(1008, "参数错误");
            if ((isAnke != 0) && (isAnke != 1))
                ThrowException(1009, "参数错误");
            if ((isKaiPaiZha != 0) && (isKaiPaiZha != 1))
                ThrowException(1010, "参数错误");
            if ((isMenQing == 1) && (isZhanLiHu != 1))
                ThrowException(1011, "参数错误");
			if ((isHaOrHeiLongJiang != 0) && (isHaOrHeiLongJiang != 1))
                ThrowException(1012, "参数错误");
            if ((isBZB != 0) && (isBZB != 1))
                ThrowException(1013, "参数错误");
			if ((isHaOrHeiLongJiang == 1) && (isMenQing == 1)) // 大庆玩法无门清选项
                ThrowException(1014, "参数错误");
			if ((isHaOrHeiLongJiang == 1) && (isAnke == 1))
                ThrowException(1015, "参数错误");    // 大庆玩法无暗刻选项
            int userId = pUser->baseInfo.userId;
            // 检测是否可以换桌
            int chairIndex = 0;
            CGameTable* pOldTable = g_table_mgr->GetPUserTable(pUser, chairIndex);
            if (pOldTable)
            {
                bool mayOffline = false;
                pOldTable->OnlyNomalLeaveTable(userId, mayOffline);
                if (mayOffline)
                    ThrowException(1, "您正在游戏中, 不能换桌");
            }

            if (pUser->activeInfo.userState == EUS_INTABLE)
                ThrowException(2, "您正在游戏中, 不能创建牌局");

            TTableRuleInfo tableRule;
			tableRule.setTableRule(isChunJia, isLaizi, isGuaDaFeng, isSanQiJia, isDanDiaoJia, isZhiDuiJia, isZhanLiHu, isMenQing, isAnke, isKaiPaiZha, isBZB, isHaOrHeiLongJiang, isJiQiRen);

            int errCode = 0;
            string errMsg = "";
            pEnterTable = g_table_mgr->CreateTable(pUser, tableRule, selScore, totalRound, vipRoomType, errCode, errMsg);
            if (!pEnterTable)
                ThrowException(errCode, "创建牌局失败：%s", errMsg.c_str());
			pUser->activeInfo.jingDu = jingDu;
			pUser->activeInfo.weiDu = weiDu;

			// 这里需要将table置成isCreated，否则桌子可能被其他人重复创建,
			// 且这里的调用要放在createtable之后，否则在createtable中会置为not isCreated
			pEnterTable->SetIsCreated(true);
			// 想后台服务请求是否能创建桌子
			g_table_mgr->ReportToTableManager(pEnterTable, ftmKaiZhuo, srcFd);
			return 0;
        }
        else
        {
            // find table
            int findHandle = -1;
            if (GetAreaNumBy6TableNum(tableNum, findHandle) != g_config_area->area_num)
                ThrowException(1, "未找到牌局");
            pEnterTable = g_table_mgr->GetTableByHandle(findHandle);
            if (!pEnterTable)
                ThrowException(2, "未找到牌局");
            if (!pEnterTable->GetIsActive())
                ThrowException(3, "未找到牌局");
            if (pEnterTable->GetTableNum() != tableNum)
                ThrowException(4, "未找到牌局.");

            // 找到桌子类型
            vipRoomType = pEnterTable->GetVipRoomType();
            if (vrtBean == vipRoomType)
            {
                int minBean = pEnterTable->GetMinBean();
                if (minBean > 0 && pUser->baseInfo.bean < minBean)
                    ThrowException(ERROR_CODE_BEAN_TOO_LITTLE, "您的游戏%s小于%d, 不能满足牌局要求", g_config_area->bean_name.c_str(), minBean);
            }
            else
            {
                // 已经收过费用的，不需要再判断进入条件
                if (!pEnterTable->GetIsConsumeSpecialGold())
                {
                    int minSpecialGold = pEnterTable->GetMinSpecialGold();
                    if (minSpecialGold > 0 && pUser->baseInfo.specialGold < minSpecialGold)
                    {
                        if (vrtScoreOnePay == vipRoomType)
                        {
                            // 单人收费的只判断房主进入。
                            if (pEnterTable->GetCreateUserId() == pUser->baseInfo.userId)
                                ThrowException(ERROR_CODE_SPECIALGOLD_TOO_LITTLE, "您的游戏%s小于%d，不能满足要求", g_config_area->specialGold_name.c_str(), minSpecialGold);
                        }
                        else if (vrtScoreAllPay == vipRoomType)
                        {
                            ThrowException(ERROR_CODE_SPECIALGOLD_TOO_LITTLE, "您的游戏%s小于%d，不能满足要求", g_config_area->specialGold_name.c_str(), minSpecialGold);
                        }
                        
                    }
                }
            }
        }

        pUser->activeInfo.jingDu = jingDu;
        pUser->activeInfo.weiDu = weiDu;

        int emptyChairAry[MAX_TABLE_USER_COUNT];
        int emptyCount = pEnterTable->GetEmptyChairAry(emptyChairAry);
        if (emptyCount < 1)
            ThrowException(11, "牌局已满");
        enterChair = emptyChairAry[0];
        if (!pEnterTable->EnterTable(pUser, enterChair, false))
            ThrowException(12, "入坐失败");
    }
    catch (CException& ex)
    {
        retCode = ex.GetCode();
        retMsg = ex.GetMsg();
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_CLIENT_SIT_RESP) << retCode << retMsg << pUser->activeInfo.userState << 
		vipRoomType << g_config_area->discard_sec
        << g_config_area->waitDongZuo_sec << EndPluto;
    mb->PushPluto(pu);

    if (0 == retCode && pEnterTable)
        pEnterTable->SendStartGameNotify(enterChair);

    return 0;
}

int CWorldGameArea::ClientLoginResponse(int clientFd, int32_t retCode, const char* retErrorMsg)
{
    CMailBox* mb = GetServer()->GetFdMailbox(clientFd);
    if(!mb)
    {
        LogInfo("CWorldGameArea::ClientLoginResponse", "!mb");
        return -1;
    }
    map<int, SUserInfo*>::iterator iter = m_fd2userInfo.find(clientFd);
    if(m_fd2userInfo.end() == iter)
    {
        LogInfo("CWorldGameArea::ClientLoginResponse", "m_fd2userInfo.end() == iter");
        return -1;
    }
    SUserInfo* pUser = iter->second;

    // 自动释放内存
    auto_new1_ptr<SUserInfo> autoUser(NULL);
    if(0 != retCode)
    {
        if(EUS_NONE != pUser->activeInfo.userState)
        {
            LogInfo("CWorldGameArea::ClientLoginResponse", "EUS_NONE != pUser->ativeInfo.userState");
            return -1;
        }

        // 登录失败，可以重试
        m_fd2userInfo.erase(iter);
        autoUser.OverridePtr(pUser);
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_CLIENT_LOGIN_RESP) << retCode << retErrorMsg << pUser->activeInfo.userState << pUser->baseInfo.ip;
    pUser->baseInfo.WriteToPluto(*pu);
    (*pu) << EndPluto;
    mb->PushPluto(pu);

    return 0;
}

int CWorldGameArea::ClientUpdateUserInfoResponse(int clientFd, int32_t retCode, const char* retErrorMsg)
{
    CMailBox* mb = GetServer()->GetFdMailbox(clientFd);
    if(!mb)
    {
        LogInfo("CWorldGameArea::ClientUpdateUserInfoResponse", "!mb");
        return -1;
    }
    SUserInfo* pUser = FindUserByFd(clientFd);
    if(!pUser)
    {
        LogInfo("CWorldGameArea::ClientUpdateUserInfoResponse", "find user failed");
        return -1;
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_CLIENT_UPDATE_USERINFO_RESP) << retCode << retErrorMsg;
    pUser->baseInfo.WriteToPluto(*pu);
    (*pu) << EndPluto;
    mb->PushPluto(pu);

    return 0;
}

bool CWorldGameArea::CheckClientRpc(CPluto& u)
{
    bool bbase = world::CheckClientRpc(u);
    if (bbase)
        return bbase;

    CMailBox* mb = u.GetMailbox();
    if(!mb)
    {
        return false;
    }

    uint8_t authz = mb->GetAuthz();

    if(authz == MAILBOX_CLIENT_UNAUTHZ)
    {
        pluto_msgid_t msg_id = u.GetMsgId();
        return msg_id == MSGID_CLIENT_LOGIN;
    }
    else
    {
        // 认证成功之后，可以发送哪些包
        pluto_msgid_t msg_id = u.GetMsgId();
        return msg_id > MSGID_CLIENT_MIN && msg_id < MSGID_CLIENT_MAX;
    }
    return false;
}

void CWorldGameArea::CheckTaskListTimeOut()
{
    m_checkTaskTime.SetNowTime();
        
    // 获得超时任务列表
    list<CAreaTaskItemBase*> lTimeout;
    for(map<uint32_t, CAreaTaskItemBase*>::iterator iter = m_taskList.begin(); iter != m_taskList.end(); ++iter)
    {
        CAreaTaskItemBase* item = iter->second;
        if(item->IsTimeout())
        {
            lTimeout.push_back(item);
        }
    }
    // 处理超时任务
    for(list<CAreaTaskItemBase*>::iterator iter = lTimeout.begin(); iter != lTimeout.end(); ++iter)
    {
        CAreaTaskItemBase* item = *iter;
        switch (item->GetMsgId())
        {
            case MSGID_DBMGR_REPORT_SCORE:
            {
                CAreaTaskReportScore* itemR = (CAreaTaskReportScore*)item;
                CGameTable* pTable = g_table_mgr->GetTableByHandle(itemR->GetTableHandle());

                if(pTable)
                    pTable->OnReportScoreError(101, "处理数据超时");
                else
                    LogError("CWorldGameArea::CheckTaskListTimeOut", "REPORT_SCORE find table failed!");

                break;
            }
            case MSGID_DBMGR_CONSUME_SPECIAL_GOLD:
            {
                CAreaTaskConsumeSpecialGold* itemR = (CAreaTaskConsumeSpecialGold*)item;
                CGameTable* pTable = g_table_mgr->GetTableByHandle(itemR->GetTableHandle());

                if (pTable)
                    pTable->SetIsConsumeSpecialGold(true);
                else
                    LogError("CWorldGameArea::CheckTaskListTimeOut", "CONSUME_SPECIAL_GOLD find table failed!");

                break;
            }
            case MSGID_DBMGR_REPORT_TOTAL_SCORE:
            {
                CAreaTaskReportTotalScore* itemR = (CAreaTaskReportTotalScore*)item;
                CGameTable* pTable = g_table_mgr->GetTableByHandle(itemR->GetTableHandle());

                if (pTable)
                    pTable->OnReportTotalScoreCallBack(101, "上报总成绩超时");
                else
                    LogError("CWorldGameArea::CheckTaskListTimeOut", "REPORT_TOTAL_SCORE find table failed!");

                break;
            }
            case MSGID_CLIENT_LOGIN:
            {
                CAreaTaskReadUserInfo* itemR = (CAreaTaskReadUserInfo*)item;
                ClientLoginResponse(itemR->GetClientFd(), 101, "验证超时");
                break;
            }
            case MSGID_CLIENT_UPDATE_USERINFO:
            {
                CAreaTaskReadUserInfo* itemR = (CAreaTaskReadUserInfo*)item;
                ClientUpdateUserInfoResponse(itemR->GetClientFd(), 101, "刷新超时");
                break;
            }
			case MSGID_AREAMGR_START_REPORT:
			{
				CAreaTaskStartReport2FS* itemR = (CAreaTaskStartReport2FS*)item;
				LogWarning("CWorldGameArea::CheckTaskListTimeOut", "cannot report to FS");
				break;
			}
			case MSGID_DBMGR_LOCK_GAMEROOM:
			{
				CAreaTaskLockOrUnlockUser* itemR = (CAreaTaskLockOrUnlockUser*)item;
				LogWarning("CWorldGameArea::CheckTaskListTimeOut", "给用户加解锁超时");
				break;
			}
			case  MSGID_DBMGR_REPORT_TABlE_MANAGER:
			{
				CAreaTaskReportTableManager* itemR = (CAreaTaskReportTableManager*)item;
				int flag = itemR->GetFlag();
				if (ftmKaiZhuo == flag)
				{
					// 通知客户桌子创建失败
					ClientSitResponse(205, itemR->GetTableHandle(), itemR->GetClientFd());
				}
				else
					LogError("CWorldGameArea::CheckTaskListTimeOut", "MSGID_DBMGR_REPORT_TABlE_MANAGER 上报超时 flag = %d", flag);
				break;
			}
			case MSGID_DBMGR_REPORT_TABLE_START:
			{
				CAreaTaskReportTableStart* itemR = (CAreaTaskReportTableStart*)item;
				LogWarning("CWorldGameArea::CheckTaskListTimeOut", "上报桌子开始状态超时 tableHandle = %d", itemR->GetTableHandle());
				break;
			}

			case MSGID_ROBOT_READ_USERINFO:
			{
				CAreaTaskReadUserInfo* itemR = (CAreaTaskReadUserInfo*)item;
				SUserBaseInfo baseInfo;
				g_robot_mgr->ReadUserInfoCallback(101, "读机器人超时", itemR->GetClientFd(), baseInfo);
				break;
			}
            default:
            {
                LogWarning("CWorldGameArea::CheckTaskListTimeOut", "not find msgid");
                break;
            }
        }
    }
    // 删除超时任务
    for(list<CAreaTaskItemBase*>::iterator iter = lTimeout.begin(); iter != lTimeout.end(); ++iter)
    {
        CAreaTaskItemBase* item = *iter;
        m_taskList.erase(item->GetTaskId());
        delete item;
    }
}

void CWorldGameArea::ReportAreaInfoToMgr()
{
	m_reportNumTime.SetNowTime();

	//int32_t gameServerId = GetWorldGameArea()->GetServer()->GetMailboxId();
	int32_t gameServerId = GetWorldGameArea()->GetServer()->GetMailboxId();;
	int32_t gameRoomId = g_config_area->gameRoomId;;
	uint32_t onlineNum = g_table_mgr->GetSitUserCount();
	int32_t cpuUseRate = 0;
	int64_t usedMemorySize = 0;
	int64_t leftMemorySize = 0;
	int32_t usedDeskCount = g_table_mgr->GetActiveTableCount();
	// status:主动告知状态,1为已经启动可分配新用户,2为暂不再分配新用户态
	int32_t status = ((225 - usedDeskCount) > 0 ? 1 : 2);

	CMailBox* mbAreamgr = this->GetServerMailbox(SERVER_AREAMGR);
	if (mbAreamgr)
	{
		if (!mbAreamgr->IsConnected())
		{
			LogWarning("CWorldGameArea::ReportAreaInfoToMgr", "!mbAreamgr->IsConnected()");
		}
		else
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MSGID_AREAMGR_UPDATE_AREA) << gameServerId << gameRoomId << onlineNum << cpuUseRate
				<< usedMemorySize << leftMemorySize << usedDeskCount << status << EndPluto;

			mbAreamgr->PushPluto(pu);
		}
	}
	else
	{
		LogWarning("CWorldGameArea::ReportAreaInfoToMgr", "!mbAreamgr");
	}
}


int CWorldGameArea::SendBulletin(T_VECTOR_OBJECT* p)
{
    if(p->size() != 3)
    {
        LogError("CWorldGameArea::SendBulletin", "p->size() error");
        return -1;
    }

    int index = 0;
    int32_t areaId = (*p)[index++]->vv.i32;
    int32_t bltType = (*p)[index++]->vv.i32;
    string& btlMsg = *(*p)[index++]->vv.s;

    for(map<int, SUserInfo*>::iterator it = m_fd2userInfo.begin(); it != m_fd2userInfo.end(); ++ it)
    {
        CPluto* pu = new CPluto();
        (*pu).Encode(MSGID_CLIENT_BULLETIN_NOTIFY) << bltType << btlMsg << EndPluto;
        GetServer()->SendPlutoByFd(it->first, pu);
    }

    return 0;
}

void CWorldGameArea::ReportStart2FS()
{
	CMailBox* mbAreamgr = this->GetServerMailbox(SERVER_AREAMGR);
	if (mbAreamgr)
	{
		if (mbAreamgr->IsConnected())
		{
			//m_tryReportStart2FS = true;

			int32_t gameServerId = GetWorldGameArea()->GetServer()->GetMailboxId();
			int32_t	areaNum = g_config_area->area_num;
			int32_t isMaster = 1;
			int32_t masterFsId = g_config_area->masterFsId;
			int32_t gameRoomId = g_config_area->gameRoomId;
			int64_t totalMemorySize = 0;
			int32_t maxPlayer = 900;
			int32_t deskCount = 225;
			string gameServerIp;
			uint16_t gameServerPort;
			GetWorldGameArea()->GetServer()->GetServerIpPort(gameServerIp, gameServerPort);
			string maxJingDu = "";
			string minJingDu = "";
			string maxWeiDu = "";
			string minWeiDu = "";
			string entryRestriction = "";

			// 创建任务
			CAreaTaskStartReport2FS* task = new CAreaTaskStartReport2FS();
			GetWorldGameArea()->AddTask(task);

			CPluto* pu = new CPluto;
			(*pu).Encode(MSGID_AREAMGR_START_REPORT) << task->GetTaskId() << gameServerId << areaNum << isMaster
				<< masterFsId << gameRoomId << totalMemorySize << maxPlayer << deskCount << gameServerIp << gameServerPort
				<< maxJingDu << minJingDu << maxWeiDu << minWeiDu << entryRestriction;
			(*pu) << EndPluto;

			mbAreamgr->PushPluto(pu);
		}
	}
}