/*----------------------------------------------------------------
// 模块描述：区域服务器管理器逻辑
//----------------------------------------------------------------*/

#include "world_areamgr.h"
#include "mailbox.h"
#include "epoll_server.h"
#include "http.h"
#include <string.h>
#include <curl/curl.h> 



CWorldAreaMgr::CWorldAreaMgr()
{
}

CWorldAreaMgr::~CWorldAreaMgr()
{
}

int CWorldAreaMgr::init(const char* pszEtcFile)
{
    int ret = world::init(pszEtcFile);

    try
    {
        m_post_serverlist_url = m_cfg->GetValue("params", "post_serverlist_url");
		m_post_ontick_url = m_cfg->GetValue("params", "post_tick_url");
    }
    catch (CException & ex)
    {
        LogError("CWorldAreaMgr::init", "error: %s", ex.GetMsg().c_str());
        return -1;
    }

    return ret;
}

int CWorldAreaMgr::OnFdClosed(int fd)
{
    map<int, string>::iterator iter = m_fd2areainfo.find(fd);
    if(iter != m_fd2areainfo.end())
    {
        LogInfo("CWorldAreaMgr::OnFdClosed", "fd=%d;areainfo=%s", fd, iter->second.c_str());
        m_fd2areainfo.erase(iter);
    }

    return 0;
}

int CWorldAreaMgr::FromRpcCall(CPluto& u)
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
    case MSGID_AREAMGR_UPDATE_AREA:
        {
            nRet = UpdateArea(p, u.GetSrcFd());
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
	case MSGID_AREAMGR_START_REPORT:
		{
			nRet = ReportGameAreaStart2Fs(p, u.GetSrcFd());
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

    ClearTListObject(p);

    return 0;
}

void CWorldAreaMgr::OnThreadRun()
{
    world::OnThreadRun();

	// 没有用这种方法的原因是现在的fs不能解析原先的文本格式！！！
    //if (m_reportTime.GetPassMsTick() > 1000)
    //    ReportAreaServerList();
}

void CWorldAreaMgr::OnServerStart()
{
    world::OnServerStart();

    //ReportAreaServerList();
}

bool CWorldAreaMgr::IsCanAcceptedClient(const string& strClientAddr)
{
    // 对于areamgr和dbmgr，只有信任ip可以连接。
    return IsTrustedClient(strClientAddr);
}

int CWorldAreaMgr::UpdateArea(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 8)
	{
		LogError("CWorldAreaMgr::UpdateArea", "p->size() error ");
		return -1;
	}

	int index = 0;
	int32_t gameServerId = (*p)[index++]->vv.i32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
	uint32_t onlineNum = (*p)[index++]->vv.u32;
	int32_t cpuUseRate = (*p)[index++]->vv.i32;
	int64_t usedMemorySize = (*p)[index++]->vv.i64;
	int64_t leftMemorySize = (*p)[index++]->vv.i64;
	int32_t usedDeskCount = (*p)[index++]->vv.i32;
	int32_t status = (*p)[index++]->vv.i32;

	char buffer[256];
	snprintf(buffer, sizeof(buffer), "%d", gameServerId);
	string strGameServerId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
	string strGameRoomId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", onlineNum);
	string strOnlineNum(buffer);
	snprintf(buffer, sizeof(buffer), "%d", cpuUseRate);
	string strCpuUseRate(buffer);
	snprintf(buffer, sizeof(buffer), "%ld", usedMemorySize);
	string strUsedMemorySize(buffer);
	snprintf(buffer, sizeof(buffer), "%ld", leftMemorySize);
	string strLeftMemorySize(buffer);
	snprintf(buffer, sizeof(buffer), "%d", usedDeskCount);
	string strUsedDeskCount(buffer);
	snprintf(buffer, sizeof(buffer), "%d", status);
	string strStatus(buffer);

	string postData("gameServerId=");
	postData += strGameServerId;
	postData += "&gameRoomId=";
	postData += strGameRoomId;
	postData += "&onlineNum=";
	postData += strOnlineNum;
	postData += "&cpuUseRate=";
	postData += strCpuUseRate;
	postData += "&usedMemorySize=";
	postData += strUsedMemorySize;
	postData += "&leftMemorySize=";
	postData += strLeftMemorySize;
	postData += "&usedDeskCount=";
	postData += strUsedDeskCount;
	postData += "&status=";
	postData += strStatus;

	m_fd2areainfo[srcFd] = postData;

	string retStr;
	http_post(m_post_ontick_url.c_str(), postData.c_str(), retStr);

	LogInfo("CWorldAreaMgr::ReportAreaServerList", "心跳返回：%s", retStr.c_str());
	//返回的状态码如果有6的话，就重发一个启动上报

	return 0;
}

int CWorldAreaMgr::ReportGameAreaStart2Fs(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 16)
	{
		LogError("CWorldAreaMgr::ReportGameAreaStart2Fs", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	int32_t gameServerId = (*p)[index++]->vv.i32;
	int32_t areaNum = (*p)[index++]->vv.i32;
	int32_t isMaster = (*p)[index++]->vv.i32;
	int32_t masterFsId = (*p)[index++]->vv.i32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
	int64_t totalMemorySize = (*p)[index++]->vv.i64;
	int32_t maxPlayers = (*p)[index++]->vv.i32;
	int32_t deskCount = (*p)[index++]->vv.i32;
	string& gameServerIp = *(*p)[index++]->vv.s;
	uint16_t gameServerPort = (*p)[index++]->vv.u16;
	string& maxJingDu = *(*p)[index++]->vv.s;
	string& minJingDu = *(*p)[index++]->vv.s;
	string& maxWeiDu = *(*p)[index++]->vv.s;
	string& minWeiDu = *(*p)[index++]->vv.s;
	string& minBean = *(*p)[index++]->vv.s;

	char buffer[256];
	snprintf(buffer, sizeof(buffer), "%d", gameServerId);
	string strGameServerId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", areaNum);
	string strAreaNum(buffer);
	snprintf(buffer, sizeof(buffer), "%d", isMaster);
	string strIsMaster(buffer);
	snprintf(buffer, sizeof(buffer), "%d", masterFsId);
	string strMasterFsId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
	string strGameRoomId(buffer);
	snprintf(buffer, sizeof(buffer), "%ld", totalMemorySize);
	string strTotalMemorySize(buffer);
	snprintf(buffer, sizeof(buffer), "%d", maxPlayers);
	string strMaxPlayer(buffer);
	snprintf(buffer, sizeof(buffer), "%d", deskCount);
	string strDeskCount(buffer);
	snprintf(buffer, sizeof(buffer), "%u", gameServerPort);
	string strGameServerPort(buffer);

	string strJingWeiDu("");
	snprintf(buffer, sizeof(buffer), "{maxJingDu: %s, minJingDu: %s, maxWeiDu: %s, minWeiDu: %s}",
		maxJingDu.c_str(), minJingDu.c_str(), maxWeiDu.c_str(), minWeiDu.c_str());
	strJingWeiDu += buffer;

	string strEntryRestriction("");
	//snprintf(buffer, sizeof(buffer), "{minBean: %s}", minBean.c_str());
	//strEntryRestriction += buffer;

	string postData("gameServerId=");
	postData += strGameServerId;
	postData += "&areaNum=";
	postData += strAreaNum;
	postData += "&isMaster=";
	postData += strIsMaster;
	postData += "&masterFsId=";
	postData += strMasterFsId;
	postData += "&gameRoomId=";
	postData += strGameRoomId;
	postData += "&totalMemorySize=";
	postData += strTotalMemorySize;
	postData += "&maxPlayers=";
	postData += strMaxPlayer;
	postData += "&deskCount=";
	postData += strDeskCount;
	postData += "&gameServerIp=";
	postData += gameServerIp;
	postData += "&gameServerPort=";
	postData += strGameServerPort;
	postData += "&jingWeiDu=";
	postData += strJingWeiDu;
	postData += "&entryRestriction=";
	postData += strEntryRestriction;

	string jsStr;
	LogInfo("游戏服务启动上报", postData.c_str());
	http_post(m_post_serverlist_url.c_str(), postData.c_str(), jsStr);

	int32_t retCode = 0;
	string retMsg = "";
	int32_t retFsId = 0;
	string retFsIdStr = "";
	int32_t retGameServerId = 0;
	try
	{
		LogInfo("游戏服务启动上报返回", jsStr.c_str());
		AutoJsonHelper aJs(jsStr);
		cJSON* pJs = aJs.GetJsonPtr();
		if (!pJs)
		{
			ThrowException(3, "游戏服务启动上报失败");
		}

		int jsRetCode;
		FindJsonItemIntValue(pJs, "retCode", jsRetCode);
		if (1 != jsRetCode)
		{
			ThrowException(4, "读取数据失败");
		}

		string pJsStr;
		FindJsonItemStrValueForObject(pJs, "ex", pJsStr);
		LogInfo("CWorldAreaMgr::ReportGameAreaStart2Fs", "pJsData : %s", pJsStr.c_str());
		AutoJsonHelper apJs(pJsStr);
		cJSON* pJsData = apJs.GetJsonPtr();

		FindJsonItemStrValue(pJsData, "fsId", retFsIdStr);
		retFsId = atoi(retFsIdStr.c_str());
		FindJsonItemIntValue(pJsData, "gameServerId", retGameServerId);
		LogInfo("CWorldAreaMgr::ReportGameAreaStart2Fs", "fsId = %d, gameServerId = %d", retFsId, retGameServerId);
	}
	catch (CException & ex)
	{
		retCode = ex.GetCode();
		retMsg = ex.GetMsg();

		LogError("CWorldAreaMgr::ReportGameAreaStart2Fs", "code = %d, error: %s", retCode, retMsg.c_str());
	}

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_AREA_START_REPORT_CALLBACK) << taskId << retCode << retMsg << retFsId << retGameServerId << EndPluto;

	GetServer()->SendPlutoByFd(srcFd, pu);

	return 0;
}

int CWorldAreaMgr::SendBulletin(T_VECTOR_OBJECT* p)
{
    if(p->size() != 3)
    {
        LogError("CWorldAreaMgr::SendBulletin", "p->size() error");
        return -1;
    }

    int index = 0;
    int32_t areaId = (*p)[index++]->vv.i32;
    int32_t bltType = (*p)[index++]->vv.i32;
    string& btlMsg = *(*p)[index++]->vv.s;

    map<int, string>::iterator it = m_fd2areainfo.end();
    bool bSend1 = false;
    if(-1 == areaId)
    {
        it = m_fd2areainfo.begin();
    }
    else
    {
        it = m_fd2areainfo.find(areaId);
        bSend1 =true;
    }

    if(it != m_fd2areainfo.end())
    {
        for(; it != m_fd2areainfo.end(); ++it)
        {
            CPluto* pu = new CPluto();
            (*pu).Encode(MSGID_CLIENT_BULLETIN_NOTIFY) << areaId << bltType << btlMsg << EndPluto;
            GetServer()->SendPlutoByFd(it->first, pu);

            if(bSend1)
                break;
        }
    }
    else
    {
        LogError("CWorldAreaMgr::SendBulletin", "find areaId=%d failed", areaId);
    }

    return 0;
}

bool CWorldAreaMgr::CheckClientRpc(CPluto& u)
{
    return world::CheckClientRpc(u);
}

void CWorldAreaMgr::ReportAreaServerList()
{
    m_reportTime.SetNowTime();

    string postData("");
    map<int, string>::iterator iter = m_fd2areainfo.begin();
    for(;iter != m_fd2areainfo.end(); ++iter)
    {
        postData += iter->second + "|";
    }

    string retStr;
    http_post(m_post_serverlist_url.c_str(), postData.c_str(), retStr);

    if ("OK" != retStr)
    {
        LogWarning("CWorldAreaMgr::ReportAreaServerList", "http_post ret=%s", retStr.c_str());
    }
}
