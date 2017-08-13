/*----------------------------------------------------------------
// 模块描述：数据服务器逻辑
//----------------------------------------------------------------*/

#include "world_dbmgr.h"
#include "mailbox.h"
#include "epoll_server.h"
#include "db_task.h"
#include "http.h"
#include "json_helper.h"
#include <string.h>
#include <curl/curl.h> 

// 麻将游戏id
#define C_GAME_ID 6
// 宜昌麻将的 playTypeId
#define C_PLAY_TYPE_ID 601
// 默认房间
#define C_GAME_ROOM_ID_DEFAULT 60101


CWorldDbMgr::CWorldDbMgr(): m_task_thread_count(1)
{
}

CWorldDbMgr::~CWorldDbMgr()
{
}

int CWorldDbMgr::init(const char* pszEtcFile)
{
    int ret = world::init(pszEtcFile);

    try
    {
        m_task_thread_count = (uint8_t)atoi(m_cfg->GetValue("params", "task_thread_count").c_str());
        if(0 == m_task_thread_count)
            ThrowException(1, "0 == m_task_thread_count");
        m_cis_url = m_cfg->GetValue("params", "cis_url");
        m_cis_key = m_cfg->GetValue("params", "cis_key");
        m_aes_key = m_cfg->GetValue("params", "aes_key");
    }
    catch (CException & ex)
    {
        LogError("CWorldDbMgr::init", "error: %s", ex.GetMsg().c_str());
        return -1;
    }

    return ret;
}

int CWorldDbMgr::OnFdClosed(int fd)
{
    return 0;
}

int CWorldDbMgr::FromRpcCall(CPluto& u)
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
    //dbmgr数据包的处理过程不判断mailbox，可能已经被释放，因为是多线程的
    switch(msg_id)
    {
    case MSGID_DBMGR_READ_USERINFO:
        {
            nRet = ReadUserInfo(p, u.GetSrcFd());
            break;
        }
    case MSGID_DBMGR_REPORT_SCORE:
        {
            nRet = ScoreReport(p, u.GetSrcFd());
            break;
        }
    case MSGID_DBMGR_CONSUME_SPECIAL_GOLD:
        {
            nRet = ConsumeSpecialGold(p, u.GetSrcFd());
            break;
        }
    case MSGID_DBMGR_REPORT_TOTAL_SCORE:
        {
            nRet = TotalScoreReport(p, u.GetSrcFd());
            break;
        }
	case MSGID_DBMGR_LOCK_GAMEROOM:
		{
			nRet = LockOrUnLockUser(p, u.GetSrcFd());
			break;
		}
	case MSGID_DBMGR_REPORT_TABlE_MANAGER:
	{
			nRet = ReportToTableManager(p, u.GetSrcFd());
			break;
		}
	case MSGID_DBMGR_REPORT_TABLE_START:
		{
			nRet = ReportTableStartState(p, u.GetSrcFd());
			break;
		}
    case MSGID_ALLAPP_SHUTDOWN_SERVER:
        {
            g_bShutdown = true;
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

    ClearTListObject(p);

    return 0;
}

bool CWorldDbMgr::IsCanAcceptedClient(const string& strClientAddr)
{
    // 对于areamgr和dbmgr，只有信任ip可以连接。
    return IsTrustedClient(strClientAddr);
}

int CWorldDbMgr::ReadUserInfo(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 5)
    {
        LogError("CWorldDbMgr::ReadUserInfo", "p->size() != 3");
        return -1;
    }

    int32_t retCode = 0;
    string retMsg = "";
    SUserBaseInfo userInfo;

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    int32_t userId = (*p)[index++]->vv.i32;
    const char* pszAccessToken = VOBJECT_GET_STR((*p)[index++]);
	int32_t gameLock = (*p)[index++]->vv.i32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;

    string jsStr;
    try
    {
        // 如果有accessToken，验证下
        string accessToken(pszAccessToken);
        if(accessToken.size() > 0)
        {
            string decryptToken;
            AesDecryptStr(accessToken, m_aes_key, decryptToken);

            vector<string> spl;
            SplitStringToVector(decryptToken, '^', spl);
            if(spl.size() < 3)
                ThrowException(1, "验证失败");

            string data = "";
            if(spl.size() > 3)
                data = spl[3];

            string md5;
            GetStrMd5(spl[0]+spl[1]+data+m_aes_key, md5);
            data = md5;
            GetStrMd5(data, md5);
            if(spl[2] != md5)
                ThrowException(2, "验证失败");

            userId = atoi(spl[0].c_str());
        }

        if(userId <= 0)
            ThrowException(2, "验证失败");

        // read from cis
		CisGetUserInfo(userId, gameLock, gameRoomId, jsStr);

		LogInfo("CWorldDbMgr::ReadUserInfo", "接受到的数据: %s", jsStr.c_str());

        AutoJsonHelper aJs(jsStr);
        cJSON* pJs = aJs.GetJsonPtr();
        if(NULL == pJs)
        {
            ThrowException(3, "读取数据失败");
        }

        string jsRetCode;
        FindJsonItemStrValue(pJs, "retCode", jsRetCode);
        if ("ok" != jsRetCode)
            ThrowException(4, "读取数据失败");
        cJSON* pJsData = FindJsonItemArrayValue(pJs, "data");
        if (NULL == pJsData)
            ThrowException(5, "解析数据失败");
        if(1 != cJSON_GetArraySize(pJsData))
            ThrowException(6, "解析数据失败");

        userInfo.ReadFromJson(cJSON_GetArrayItem(pJsData, 0));
        if(userId != userInfo.userId)
            ThrowException(7, "解析数据失败");
    }
    catch (CException & ex)
    {
        retCode = ex.GetCode();
        retMsg = ex.GetMsg();

        LogError("CWorldDbMgr::ReadUserInfo", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
    }

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_AREA_READ_USERINFO_CALLBACK) << taskId << retCode << retMsg
		<< userInfo.userId << userInfo.userType << userInfo.score << userInfo.bean << userInfo.userName
		<< userInfo.nickName << userInfo.sex << userInfo.level << userInfo.faceId << userInfo.faceUrl 
		<< userInfo.specialGold << userInfo.ip << userInfo.isVip << EndPluto;
	pu->SetDstFd(srcFd);
	g_pluto_sendlist.PushPluto(pu);

    return 0;
}

int CWorldDbMgr::ScoreReport(T_VECTOR_OBJECT* p, int srcFd)
{
    if(p->size() != 12)
    {
        LogError("CWorldDbMgr::ScoreReport", "p->size() error: %d", p->size());
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
	uint32_t serverId = (*p)[index++]->vv.u32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
	int32_t isLockGameRoom = (*p)[index++]->vv.i32;
    string& openSeriesNum = *(*p)[index++]->vv.s;
    string& gameStartMsStamp = *(*p)[index++]->vv.s;
    int32_t basescore = (*p)[index++]->vv.i32;
    int32_t roundFee = (*p)[index++]->vv.i32;
    int32_t isVipRoomEnd = (*p)[index++]->vv.i32;
	string& tableId = *(*p)[index++]->vv.s;
	int32_t curInning = (*p)[index++]->vv.i32;
    T_VECTOR_OBJECT* pAry = (*p)[index++]->vv.oOrAry;
    if(pAry->size() < 1)
    {
        LogError("CWorldDbMgr::ScoreReport", "pAry->size() < 1");
        return -1;
    }

    int32_t retCode = 0;
    string retMsg = "";
    vector<SCisScoreReportRetItem*> retList;

    char buffer[300];
    bool isLandWin = false;
    string strData("[");
    int len = pAry->size();
    for(int i = 0; i < len; i++)
    {
        T_VECTOR_OBJECT* item = (*pAry)[i]->vv.oOrAry;
        int32_t itemUserId = (*item)[0]->vv.i32;
        uint8_t itemIsFlee = (*item)[1]->vv.u8;
        int32_t bean = (*item)[2]->vv.i32;

		if (i != 0)
			strData += ",";

        snprintf(buffer, sizeof(buffer), "{\"userId\": %d, \"isFlee\": %d, \"isRobot\": 0, \"bean\": %d}", 
            itemUserId, itemIsFlee, bean);
        strData += buffer;
    }
    strData += "]";

    snprintf(buffer, sizeof(buffer), "{\"anteNum\": %d,\"roundFee\": %d, \"vipRoomType\":3, \"isVipRoomEnd\": %d, \"tableId\": \"%s\", \"curInning\": %d}",
        basescore, roundFee, isVipRoomEnd, tableId.c_str(), curInning);
    string strData2(buffer);

    uint64_t stamp = GetTimeStampInt64Ms();
    snprintf(buffer, sizeof(buffer), "%llu", stamp);
    string strStamp(buffer);
    snprintf(buffer, sizeof(buffer), "%u", serverId);
    string strServerId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
	string strRoomId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", isLockGameRoom);
	string strIsLockGameRoom(buffer);
    snprintf(buffer, sizeof(buffer), "%d", C_GAME_ID);
    string strGameId(buffer);
    string checkCode;
	GetStrMd5(strGameId + strRoomId  + openSeriesNum + strData + strData2 + strStamp + m_cis_key, checkCode);
    string postData("action=ReportGameResult&gameId=");
    postData += strGameId;
	postData += "&gameRoomId=";
	postData += strRoomId;
    postData += "&gameServerId=";
    postData += strServerId;
	postData += "&isLockGameRoom=";
	postData += strIsLockGameRoom;
    postData += "&openSeriesNum=";
    postData += openSeriesNum;
    postData += "&data=";
    postData += strData;
    postData += "&data2=";
    postData += strData2;
    postData += "&startTime=";
    postData += gameStartMsStamp;
    postData += "&timestamp=";
    postData += strStamp;
    postData += "&checkCode=";
    postData += checkCode;
    string jsStr;

	LogInfo("积分上报", "post: %s", postData.c_str()); // try
    http_post(m_cis_url.c_str(), postData.c_str(), jsStr);
	LogInfo("积分上报", "ret: %s", jsStr.c_str());     // try

    try
    {
        AutoJsonHelper aJs(jsStr);
        cJSON* pJs = aJs.GetJsonPtr();
        if(NULL == pJs)
        {
            ThrowException(3, "读取数据失败");
        }

        string jsRetCode;
        FindJsonItemStrValue(pJs, "retCode", jsRetCode);
        if ("ok" != jsRetCode)
            ThrowException(4, "读取数据失败");
        cJSON* pJsData = FindJsonItemArrayValue(pJs, "data");
        if (NULL == pJsData)
            ThrowException(5, "解析数据失败");
        len = cJSON_GetArraySize(pJsData);
        if(len < 1)
            ThrowException(6, "解析数据失败");
        for(int i = 0; i < len; i++)
        {
            SCisScoreReportRetItem* retInfo = new SCisScoreReportRetItem();
            retInfo->ReadFromJson(cJSON_GetArrayItem(pJsData, i));
            retList.push_back(retInfo);
        }
    }
    catch (CException & ex)
    {
        retCode = ex.GetCode();
        retMsg = ex.GetMsg();

        LogError("CWorldDbMgr::ScoreReport", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_AREA_REPORT_SCORE_CALLBACK) << taskId << retCode << retMsg;
    uint16_t aryLen = retList.size();
    (*pu) << aryLen;
    for(int i = 0; i < aryLen; i++)
    {
        SCisScoreReportRetItem* item = retList[i];
        item->WriteToPluto(*pu);
    }
    (*pu) << EndPluto;
    pu->SetDstFd(srcFd);
    g_pluto_sendlist.PushPluto(pu);

    ClearContainer(retList);

    return 0;
}

int CWorldDbMgr::ConsumeSpecialGold(T_VECTOR_OBJECT* p, int srcFd)
{
    if (p->size() != 6)
    {
        LogError("CWorldDbMgr::ConsumeSpecialGold", "p->size() error");
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
	uint32_t serverId = (*p)[index++]->vv.u32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
    uint32_t matchId = (*p)[index++]->vv.u32;
    string& openSeriesNum = *(*p)[index++]->vv.s;
    T_VECTOR_OBJECT* pAry = (*p)[index++]->vv.oOrAry;
    if (pAry->size() < 1)
    {
        LogError("CWorldDbMgr::ConsumeSpecialGold", "pAry->size() < 1");
        return -1;
    }

    int32_t retCode = 0;
    string retMsg = "";
    vector<SCisSpecialGoldComsumeRetItem*> retList;

    char buf[150];
    string strData("[");
    int len = pAry->size();
    for (int i = 0; i < len; i++)
    {
        T_VECTOR_OBJECT* item = (*pAry)[i]->vv.oOrAry;
        int32_t itemUserId = (*item)[0]->vv.i32;
        int64_t itemConsumeNum = (*item)[1]->vv.i64;
        string itemRemark = *(*item)[2]->vv.s;

        if (i != 0)
            strData += ",";

        snprintf(buf, sizeof(buf), "{\"userId\": %d, \"comsumeNum\": %lld, \"remark\": \"%s\"}", itemUserId, itemConsumeNum, itemRemark.c_str());
        strData += buf;
    }
    strData += "]";

    uint64_t stamp = GetTimeStampInt64Ms();
    snprintf(buf, sizeof(buf), "%llu", stamp);
    string strStamp(buf);
    snprintf(buf, sizeof(buf), "%u", serverId);
    string strServerId(buf);
    snprintf(buf, sizeof(buf), "%u", matchId);
    string strMatchId(buf);
    snprintf(buf, sizeof(buf), "%d", C_GAME_ID);
    string strGameId(buf);
	snprintf(buf, sizeof(buf), "%d", gameRoomId);
	string strRoomId(buf);
    string checkCode;
    GetStrMd5(strGameId + strRoomId + strMatchId + openSeriesNum + strData + strStamp + m_cis_key, checkCode);
    string postData("action=ComsumeSpecialGold&gameId=");
    postData += strGameId;
//     postData += "&gameServerId=";
//     postData += strServerId;
	postData += "&gameRoomId=";
	postData += strRoomId;
    postData += "&matchId=";
    postData += strMatchId;
    postData += "&serilaNo=";
    postData += openSeriesNum;
    postData += "&datas=";
    postData += strData;
    postData += "&timestamp=";
    postData += strStamp;
    postData += "&checkCode=";
    postData += checkCode;
    string jsStr;
    http_post(m_cis_url.c_str(), postData.c_str(), jsStr);

    try
    {
        AutoJsonHelper aJs(jsStr);
        cJSON* pJs = aJs.GetJsonPtr();
        if (NULL == pJs)
        {
            ThrowException(3, "读取数据失败");
        }

        string jsRetCode;
        FindJsonItemStrValue(pJs, "retCode", jsRetCode);
        if ("ok" != jsRetCode)
            ThrowException(4, "读取数据失败");
        cJSON* pJsData = FindJsonItemArrayValue(pJs, "data");
        if (NULL == pJsData)
            ThrowException(5, "解析数据失败");
        len = cJSON_GetArraySize(pJsData);
        if (len < 1)
            ThrowException(6, "解析数据失败");
        for (int i = 0; i < len; i++)
        {
            SCisSpecialGoldComsumeRetItem* retInfo = new SCisSpecialGoldComsumeRetItem();
            retInfo->ReadFromJson(cJSON_GetArrayItem(pJsData, i));
            retList.push_back(retInfo);
        }
    }
    catch (CException & ex)
    {
        retCode = ex.GetCode();
        retMsg = ex.GetMsg();

        LogError("CWorldDbMgr::ConsumeSpecialGold", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_AREA_CONSUME_SPECIAL_GOLD_CALLBACK) << taskId << retCode << retMsg;
    uint16_t aryLen = retList.size();
    (*pu) << aryLen;
    for (int i = 0; i < aryLen; i++)
    {
        SCisSpecialGoldComsumeRetItem* item = retList[i];
        item->WriteToPluto(*pu);
    }
    (*pu) << EndPluto;
    pu->SetDstFd(srcFd);
    g_pluto_sendlist.PushPluto(pu);

    ClearContainer(retList);

    return 0;
}

int CWorldDbMgr::LockOrUnLockUser(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 4)
	{
		LogError("CWorldDbMgr::LockOrUnLockUser", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
	int32_t userId = (*p)[index++]->vv.i32;
	int32_t type = (*p)[index++]->vv.i32;

	int32_t retCode = 0;
	string retMsg = "";

	char buffer[256];
	uint64_t stamp = GetTimeStampInt64Ms();
	snprintf(buffer, sizeof(buffer), "%ld", stamp);
	string strTimeStamp(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
	string strGameRoomId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", userId);
	string strUserId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", type);
	string strType(buffer);
	string checkCode;
	GetStrMd5(strUserId + strGameRoomId + strType + strTimeStamp + m_cis_key, checkCode);

	string postData("action=LockGameRoom&userId=");
	postData += strUserId;
	postData += "&gameRoomId=";
	postData += strGameRoomId;
	postData += "&type=";
	postData += strType;
	postData += "&timestamp=";
	postData += strTimeStamp;
	postData += "&checkCode=";
	postData += checkCode;


	LogInfo("CWorldDbMgr::LockOrUnLockUser", "上报的数据:%s", postData.c_str());
	string jsStr;
	http_post(m_cis_url.c_str(), postData.c_str(), jsStr);

	LogInfo("CWorldDbMgr::LockOrUnLockUser", "接受到的数据:%s", jsStr.c_str());

	try
	{
		AutoJsonHelper aJs(jsStr);
		cJSON* pJs = aJs.GetJsonPtr();
		if (NULL == pJs)
		{
			ThrowException(3, "读取数据失败");
		}

		string jsRetCode;
		FindJsonItemStrValue(pJs, "retCode", jsRetCode);
		if ("ok" != jsRetCode)
			ThrowException(4, "读取数据失败");

	}
	catch (CException & ex)
	{
		retCode = ex.GetCode();
		retMsg = ex.GetMsg();

		LogError("CWorldDbMgr::LockOrUnLockUser", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
	}

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_AREA_LOCK_GAMEROOM_CALLBACK) << taskId << retCode << retMsg;
	(*pu) << EndPluto;
	pu->SetDstFd(srcFd);
	g_pluto_sendlist.PushPluto(pu);

	return 0;
}

int CWorldDbMgr::TotalScoreReport(T_VECTOR_OBJECT* p, int srcFd)
{
    LogInfo("CWorldDbMgr::TotalScoreReport", "---------------- 总分上报测试 ----------------");

    if (p->size() != 11)
    {
        LogError("CWorldDbMgr::TotalScoreReport", "p->size() error: %d", p->size());
        return -1;
    }

    int index = 0;
    uint32_t taskId = (*p)[index++]->vv.u32;
    uint32_t serverId = (*p)[index++]->vv.u32;
    int32_t gameRoomId = (*p)[index++]->vv.i32;
    string& openSeriesNum = *(*p)[index++]->vv.s;
    string& openSeriesNums = *(*p)[index++]->vv.s;
    int32_t vipRoomType = (*p)[index++]->vv.i32;
    string& tableNum = *(*p)[index++]->vv.s;
    int32_t innings = (*p)[index++]->vv.i32;
    string& fstStartMsStamp = *(*p)[index++]->vv.s;
    string& gameEndMsStamp = *(*p)[index++]->vv.s;
    T_VECTOR_OBJECT* pAry = (*p)[index++]->vv.oOrAry;
    if (pAry->size() < 1)
    {
        LogError("CWorldDbMgr::TotalScoreReport", "pAry->size() < 1");
        return -1;
    }

    int32_t retCode = 0;
    string retMsg = "";

    char buffer[300];
    bool isLandWin = false;
    string strData("[");
    int len = pAry->size();
    for (int i = 0; i < len; i++)
    {
        T_VECTOR_OBJECT* item = (*pAry)[i]->vv.oOrAry;
        int32_t itemUserId = (*item)[0]->vv.i32;
        string& itemUserName = *(*item)[1]->vv.s;
        int32_t totalScores = (*item)[2]->vv.i32;

        if (i != 0)
            strData += ",";

        snprintf(buffer, sizeof(buffer), "{\"userId\": %d, \"userName\": %s, \"score\": %d}",
            itemUserId, itemUserName.c_str(), totalScores);
        strData += buffer;
    }
    strData += "]";

    uint64_t stamp = GetTimeStampInt64Ms();
    snprintf(buffer, sizeof(buffer), "%llu", stamp);
    string strStamp(buffer);
    snprintf(buffer, sizeof(buffer), "%u", serverId);
    string strServerId(buffer);
    snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
    string strRoomId(buffer);
    snprintf(buffer, sizeof(buffer), "%d", C_GAME_ID);
    string strGameId(buffer);
    snprintf(buffer, sizeof(buffer), "%d", vipRoomType);
    string strVipRoomType(buffer);
    snprintf(buffer, sizeof(buffer), "%d", innings);
    string strInnings(buffer);
    string checkCode;
    GetStrMd5(strGameId + strRoomId + openSeriesNum + strData + strStamp + m_cis_key, checkCode);
    string postData("action=ReportTotalResult&gameId=");
    postData += strGameId;
    postData += "&gameServerId=";
    postData += strServerId;
    postData += "&gameRoomId=";
    postData += strRoomId;
    postData += "&openSeriesNum=";
    postData += openSeriesNum;
    postData += "&openSeriesNums=";
    postData += openSeriesNums;
    postData += "&vipRoomType=";
    postData += strVipRoomType;
    postData += "&tableId=";
    postData += tableNum;
    postData += "&innings=";
    postData += strInnings;
    postData += "&data=";
    postData += strData;
    postData += "&startTime=";
    postData += fstStartMsStamp;
    postData += "&endTime=";
    postData += gameEndMsStamp;
    postData += "&timestamp=";
    postData += strStamp;
    postData += "&checkCode=";
    postData += checkCode;
    string jsStr;

    LogInfo("总分上报", "post: %s", postData.c_str()); // try
    http_post(m_cis_url.c_str(), postData.c_str(), jsStr);
    LogInfo("总分上报", "ret: %s", jsStr.c_str());     // try

    try
    {
        AutoJsonHelper aJs(jsStr);
        cJSON* pJs = aJs.GetJsonPtr();
        if (NULL == pJs)
        {
            ThrowException(3, "上报总成绩失败");
        }

        string jsRetCode;
        FindJsonItemStrValue(pJs, "retCode", jsRetCode);
        if ("ok" != jsRetCode)
            ThrowException(4, "上报总成绩失败");
    }
    catch (CException & ex)
    {
        retCode = ex.GetCode();
        retMsg = ex.GetMsg();

        LogError("CWorldDbMgr::TotalScoreReport", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
    }

    CPluto* pu = new CPluto;
    (*pu).Encode(MSGID_AREA_REPORT_TOTAL_SCORE_CALLBACK) << taskId << retCode << retMsg;
    (*pu) << EndPluto;
    pu->SetDstFd(srcFd);
    g_pluto_sendlist.PushPluto(pu);

    return 0;
}
int CWorldDbMgr::ReportToTableManager(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 11)
	{
		LogError("CWorldDbMgr::ReportToTableManager", "p->size() error!");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	int32_t flag = (*p)[index++]->vv.i32;
	int32_t playTypeId = (*p)[index++]->vv.i32;
	int32_t gameRoomId = (*p)[index++]->vv.i32;
	int32_t gameServerId = (*p)[index++]->vv.i32;
	int32_t userId = (*p)[index++]->vv.i32;
	string& tableNum = *(*p)[index++]->vv.s;
	int32_t maxRound = (*p)[index++]->vv.i32;
	int32_t minSpecialGold = (*p)[index++]->vv.i32;
	int32_t vipRoomType = (*p)[index++]->vv.i32;
	string optionStr = *(*p)[index++]->vv.s;

	char buffer[300];

	snprintf(buffer, sizeof(buffer), "%d", flag);
	string strFlag(buffer);
	snprintf(buffer, sizeof(buffer), "%d", playTypeId);
	string strPlayTypeId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameRoomId);
	string strGameRoomId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", gameServerId);
	string strGameServerId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", userId);
	string strUserId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", maxRound);
	string strMaxRound(buffer);
	snprintf(buffer, sizeof(buffer), "%d", minSpecialGold);
	string strMinSpecialGold(buffer);
	snprintf(buffer, sizeof(buffer), "%d", vipRoomType);
	string strVipRoomType(buffer);

	uint64_t stamp = GetTimeStampInt64Ms();
	snprintf(buffer, sizeof(buffer), "%llu", stamp);
	string strStamp(buffer);

	string checkCode;
	GetStrMd5(strPlayTypeId + strFlag + strStamp + m_cis_key, checkCode);

	string postData("action=PrivateTableManager&playTypeId=");
	postData += strPlayTypeId;
	postData += "&gameRoomId=";
	postData += strGameRoomId;
	postData += "&gameServerId=";
	postData += strGameServerId;
	postData += "&userId=";
	postData += strUserId;
	postData += "&tableId=";
	postData += tableNum;
	postData += "&totalInning=";
	postData += strMaxRound;
	postData += "&specialGold=";
	postData += strMinSpecialGold;
	postData += "&vipRoomType=";
	postData += strVipRoomType;
	postData += "&option=";
	postData += optionStr;
	postData += "&result=";
	postData += strFlag;
	postData += "&timestamp=";
	postData += strStamp;
	postData += "&checkCode=";
	postData += checkCode;

	LogInfo("CWorldDbMgr::ReportToTableManager", "post: %s", postData.c_str());

	string jsStr;
	http_post(m_cis_url.c_str(), postData.c_str(), jsStr);

	LogInfo("CWorldDbMgr::ReportToTableManager", "get: %s", jsStr.c_str());

	int32_t retCode = 0;
	string retMsg = "";
	try
	{
		AutoJsonHelper aJs(jsStr);
		cJSON* pJs = aJs.GetJsonPtr();
		if (nullptr == pJs)
			ThrowException(1, "返回数据为空");

		string jsRetCode;
		FindJsonItemStrValue(pJs, "retCode", jsRetCode);
		if ("ok" != jsRetCode)
		{
			ThrowException(2, "上报失败");
			LogError("CWorldDbMgr::ReportToTableManager", "get: %s", jsStr.c_str());
		}

	}
	catch (CException &ex)
	{
		retCode = ex.GetCode();
		retMsg = ex.GetMsg();
	}

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_AREA_REPORT_TABlE_MANAGER_CALLBACK) << taskId << retCode << retMsg << EndPluto;
	pu->SetDstFd(srcFd);
	g_pluto_sendlist.PushPluto(pu);

	return 0;
}

int CWorldDbMgr::ReportTableStartState(T_VECTOR_OBJECT* p, int srcFd)
{
	if (p->size() != 5)
	{
		LogError("CWorldDbMgr::ReportTableStartState", "p->size() error");
		return -1;
	}

	int index = 0;
	uint32_t taskId = (*p)[index++]->vv.u32;
	string tableNum = *(*p)[index++]->vv.s;
	int32_t userId = (*p)[index++]->vv.i32;
	int32_t playTypeId = (*p)[index++]->vv.i32;
	int32_t status = (*p)[index++]->vv.i32;

	char buffer[256];
	snprintf(buffer, sizeof(buffer), "%d", userId);
	string strUserId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", playTypeId);
	string strPlayTypeId(buffer);
	snprintf(buffer, sizeof(buffer), "%d", status);
	string strStatus(buffer);

	uint64_t stamp = GetTimeStampInt64Ms();
	snprintf(buffer, sizeof(buffer), "%llu", stamp);
	string strStamp(buffer);

	string checkCode;
	GetStrMd5(tableNum + strPlayTypeId + strUserId + strStamp + m_cis_key, checkCode);

	string postData("action=ReportPrivateTableStatus&tableId=");
	postData += tableNum;
	postData += "&userId=";
	postData += strUserId;
	postData += "&playTypeId=";
	postData += strPlayTypeId;
	postData += "&status=";
	postData += strStatus;
	postData += "&timestamp=";
	postData += strStamp;
	postData += "&checkCode=";
	postData += checkCode;


	LogInfo("CWorldDbMgr::ReportTableStartState", "上报的数据:%s", postData.c_str());
	string jsStr;
	http_post(m_cis_url.c_str(), postData.c_str(), jsStr);

	LogInfo("CWorldDbMgr::ReportTableStartState", "接受到的数据:%s", jsStr.c_str());


	int32_t retCode = 0;
	string retMsg = "";
	try
	{
		AutoJsonHelper aJs(jsStr);
		cJSON* pJs = aJs.GetJsonPtr();
		if (NULL == pJs)
		{
			ThrowException(3, "读取数据失败");
		}

		string jsRetCode;
		FindJsonItemStrValue(pJs, "retCode", jsRetCode);
		if ("ok" != jsRetCode)
			ThrowException(4, "读取数据失败");

	}
	catch (CException & ex)
	{
		retCode = ex.GetCode();
		retMsg = ex.GetMsg();

		LogError("CWorldDbMgr::ReportTableStartState", "code=%d, error: %s cisRet=%s", ex.GetCode(), ex.GetMsg().c_str(), jsStr.c_str());
	}

	CPluto* pu = new CPluto;
	(*pu).Encode(MSGID_AREA_REPORT_TABLE_START_CALLBACK) << taskId << retCode << retMsg;
	(*pu) << EndPluto;
	pu->SetDstFd(srcFd);
	g_pluto_sendlist.PushPluto(pu);

	return 0;
}

void CWorldDbMgr::CisGetUserInfo(int userId, int gameLock, int gameRoomId, string& retStr)
{
    uint64_t stamp = GetTimeStampInt64Ms();
    char buffer[150];
    snprintf(buffer, sizeof(buffer), "%d", C_GAME_ID);
    string strGameId(buffer);
    // 获得校验值
    snprintf(buffer, sizeof(buffer), "%d%s%d%d%llu%s", userId, strGameId.c_str(), gameLock, gameRoomId, stamp, m_cis_key.c_str());
    string tmpStr = buffer;
    string md5;
    GetStrMd5(tmpStr, md5);
    // postdata
    snprintf(buffer, sizeof(buffer), "action=GetUserInfos&userId=%d&gameId=%s&gameLock=%d&gameRoomId=%d&timestamp=%llu&checkCode=%s", userId, strGameId.c_str(), gameLock, gameRoomId, stamp, md5.c_str());
    tmpStr = buffer;

    http_post(m_cis_url.c_str(), tmpStr.c_str(), retStr);
    //LogInfo("CWorldDbMgr::CisGetUserInfo", "postRet=%s", retStr.c_str());
}

bool CWorldDbMgr::CheckClientRpc(CPluto& u)
{
    return world::CheckClientRpc(u);
}
