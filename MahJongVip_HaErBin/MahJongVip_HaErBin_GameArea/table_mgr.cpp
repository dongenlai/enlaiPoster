/*----------------------------------------------------------------
// 模块名：table_mgr
// 模块描述：桌子（包含机器人处理）桌子列表【包含分桌处理、断线用户列表（可以返回）、激活桌子定时器】
//----------------------------------------------------------------*/

#include <limits.h>
#include "table_mgr.h"
#include "type_area.h"
#include "util.h"
#include "logger.h"
#include "global_var.h"
#include <sstream>


#define CTimerInterval 200

CGameTable::CGameTable(int handle) : m_handle(handle), m_isActive(false), m_endGameTick(0), m_lastRunTick(), m_userList(), m_sitUserList(), 
    m_curRound(0), m_createUserId(INVALID_USERID), m_clearRemainSec(INVALID_TIME_COUNT), m_minSpecialGold(0), m_vipRoomType(vrtNone), 
    m_isConsumeSpecialGold(false), m_totalScore()
{
    for(int i = 0; i < MAX_TABLE_USER_COUNT; i++)
    {
        m_userList.push_back(new CTableUser());
    }
	m_diceValue.resize(3);

	m_mjActionMgr.init(this, &m_mjDataMgr);
	m_mjDataMgr.init(this, &m_mjActionMgr);

	m_eastPlace = 0;
	m_bankerPlace = 0;
	m_lastDisbandTime = 0;
    RoundStopClearData();
    NoUserClearData();
}

CGameTable::~CGameTable()
{
    m_sitUserList.clear();
    ClearContainer(m_userList);
}

int CGameTable::ProcClientChat(T_VECTOR_OBJECT* p, int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
        return -1;
    if(p->size() != 4)
    {
        LogError("CGameTable::ProcClientChat", "p->size() error");
        return -1;
    }
    int index = 0;
    int32_t chatType = (*p)[index++]->vv.i32;
    int32_t isSplit = (*p)[index++]->vv.i32;
    int32_t packOrder = (*p)[index++]->vv.i32;
    string chatMsg = *(*p)[index++]->vv.s;
    if(chatMsg.size() < 1)
    {
        LogError("CGameTable::ProcClientChat", "chatMsg empty");
        return -1;
    }
    

    CTableUser* pTUser = m_userList[chairIndex];
    {
        CPluto* puResp = new CPluto();
        (*puResp).Encode(MSGID_CLIENT_CHAT_RESP) << (int)0 << "" << chatType << isSplit << packOrder << chatMsg << EndPluto;
        SendPlutoToUser(puResp, pTUser);
    }
    
    {
        int userId = pTUser->userInfo.baseInfo.userId;
        CPluto* puBroad = new CPluto();
        (*puBroad).Encode(MSGID_CLIENT_OTHER_CHAT_NOTIFY) << userId << chatType << isSplit << packOrder << chatMsg << EndPluto;
        SendBroadTablePluto(puBroad, userId);
    }

    return 0;
}

int CGameTable::ProcClientCtrlTable(T_VECTOR_OBJECT* p, int chairIndex)
{
	if (!IsChairIndexValid(chairIndex))
		return -1;
	if (p->size() != 2)
	{
		LogError("CGameTable::ProcClientCtrlTable", "p->size() error");
		return -1;
	}

	int index = 0;
	int32_t ctrlCode = (*p)[index++]->vv.i32;
	int32_t isAgree = (*p)[index++]->vv.i32;

	CTableUser* pTUser = m_userList[chairIndex];
	int code = 0;
	string retMsg = "";
	try
	{
		if (ctrlCode == 0)
		{
			// 请求散桌
			isAgree = 1;
			if (m_isQuestDisband)
				ThrowException(1, "正在处理上一个散桌请求");
			if (GetMsTickDiff(pTUser->lastQuestDisbandTick, GetNowMsTick()) < 
					(uint32_t)g_config_area->min_interval_quest_disband * MS_PER_SEC)
				ThrowException(2, "频繁申请散桌，请稍等");
		}
		else
		{
			// 是否同意散桌
			if (!m_isQuestDisband)
				ThrowException(1, "当前无散桌请求或者散桌请求过期");
		}

	}
	catch (CException& ex)
	{
		code = ex.GetCode();
		retMsg = ex.GetMsg();
	}

	{
		CPluto* puResp = new CPluto();
		(*puResp).Encode(MSGID_CLIENT_QUEST_CTRL_TABLE_RESP) << code << retMsg << EndPluto;
		SendPlutoToUser(puResp, pTUser);
	}

	if (code == 0)
	{
		DoUserDisbandTable(pTUser, ctrlCode, isAgree);
	}

	return 0;
}

int CGameTable::ProcClientLeaveTable(T_VECTOR_OBJECT* p, int chairIndex)
{
	if (!IsChairIndexValid(chairIndex))
		return -1;
	if (p->size() != 0)
	{
		LogError("CGameTable::ProcClientLeaveTable", "p->size() error");
		return -1;
	}

	CTableUser* pTUser = m_userList[chairIndex];
	int code = 0;
	string retMsg = "";
	try
	{
		if (m_curRound > 1 || IsGaming() || GetCurUserCount() >= MAX_TABLE_USER_COUNT)
		{
			ThrowException(1, "不是第一局的准备阶段，不能退出，请选择散桌！");
		}
		/*if (GetCreateUserId() == pTUser->userInfo.baseInfo.userId)
		{
		ThrowException(2, "您为房主，不能退出，请选择散桌！");
		}*/
		LogInfo("CGameTable::ProcClientLeaveTable", "userId=%d, isVip=%d", pTUser->userInfo.baseInfo.userId, pTUser->userInfo.baseInfo.isVip);
		if (GetCreateUserId() == pTUser->userInfo.baseInfo.userId && !pTUser->userInfo.baseInfo.isVip)
		{
			ThrowException(2, "您是房主，不能退出房间，请选择散桌！");
		}
		
	}
	catch (CException& ex)
	{
		code = ex.GetCode();
		retMsg = ex.GetMsg();
	}

	{
		CPluto* puResp = new CPluto();
		(*puResp).Encode(MSGID_CLIENT_G_LEAVE_RESP) << code << retMsg << EndPluto;
		SendPlutoToUser(puResp, pTUser);
	}

	if (code == 0)
	{
		//LogInfo("CGameTable::ProcClientLeaveTable", "clearUser userID = %d", pTUser->userInfo.baseInfo.userId);
		ClearUser(pTUser);
	}

	return 0;
}

int CGameTable::ProcClientGetTingInfo(T_VECTOR_OBJECT* p, int chairIndex)
{
	if (!IsChairIndexValid(chairIndex))
		return -1;
	if (p->size() != 0)
	{
		LogError("CGameTable::ProcClientGetTingInfo", "p->size() error");
		return -1;
	}

	CTableUser* pTUser = m_userList[chairIndex];
	int code = 0;
	string retMsg = "";
	try
	{
		if (!pTUser->tingPaiInfoArr.size())
		{
			ThrowException(1, "您还没有听牌");
		}
	}
	catch (CException& ex)
	{
		code = ex.GetCode();
		retMsg = ex.GetMsg();
	}

	string tingInfo = "";
	stringstream tmpStream;
	int tingCount = 0;
	if (code == 0)
	{
		for (auto tingItem = pTUser->tingPaiInfoArr.begin(); tingItem != pTUser->tingPaiInfoArr.end(); ++tingItem)
		{
			int remainCount = m_mjDataMgr.getRemaindCount(chairIndex, (*tingItem).huCardId);
			if (tingCount > 0)
				tmpStream << ",";
			tmpStream << (*tingItem).huCardId << "^" << (*tingItem).huFan << "^" << remainCount;
			tingCount++;
		}
	}
	tingInfo = tmpStream.str();

	{
		CPluto* puResp = new CPluto();
		(*puResp).Encode(MSGID_CLIENT_G_GET_TINGINFO_RESP) << code << retMsg << tingInfo << EndPluto;
		SendPlutoToUser(puResp, pTUser);
	}

	return 0;
}

int CGameTable::ProcClientSpecialGang(T_VECTOR_OBJECT* p, int chairIndex)
{
	return 0;
}

void CGameTable::DoUserDisbandTable(CTableUser* pTUser, int ctrlCode, int isAgree)
{
	{
		// 告知玩家散桌请求
		CPluto* puNotify = new CPluto();
		(*puNotify).Encode(MSGID_CLIENT_DISBAND_TABLE_NOTIFY) << ctrlCode << pTUser->userInfo.baseInfo.userId << 
			isAgree << g_config_area->wait_answer_disband_sec << EndPluto;
		SendBroadTablePluto(puNotify, pTUser->userInfo.baseInfo.userId);
	}

	if (ctrlCode == 0)
	{
		if (m_curRound == 1 && 
			m_tstate == tbsNone &&
			GetCurUserCount() < MAX_TABLE_USER_COUNT &&
			GetCreateUserId() == pTUser->userInfo.baseInfo.userId)
		{
			// 在第一局开局等待阶段，房间还没有坐满的情况下，房主请求散桌，则直接散桌，不需要等待他人同意
			DisBandTable(0);
		}
		else
		{
			m_decTimeQuestDisband = g_config_area->wait_answer_disband_sec;
			m_questDisbandUserId = pTUser->userInfo.baseInfo.userId;
			pTUser->lastQuestDisbandTick = GetNowMsTick();
			m_isQuestDisband = true;
			pTUser->agreeEnd = 1;       // 请求散桌的玩家当然同意散桌
		}
	}
	else
	{
		pTUser->agreeEnd = isAgree;

		if (!isAgree)
		{
			// 有人不同意散桌，则本次散桌请求结束询问
			endQuestDisband();
		}
		else
		{
			// 检测是否可以散桌
			CheckAllUserAgreeClearTable();
		}
	}
}

void CGameTable::endQuestDisband()
{
	LogInfo("散桌", "结束散桌"); // try

	// 结束本次散桌请求。
	m_isQuestDisband = false;
	m_decTimeQuestDisband = -1;
	for (auto it = m_userList.begin(); it != m_userList.end(); it++)
	{
		(*it)->agreeEnd = 0;
	}
}


void CGameTable::CheckAllUserAgreeClearTable()
{
	bool allAgree = true;
	for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
	{
		CTableUser* pTUser = iter->second;
		if (tusNomal == pTUser->ustate)
		{
			if (pTUser->agreeEnd == 0)
			{
				allAgree = false;
				break;
			}
		}
	}

	if (allAgree)
	{
		DisBandTable(1);
	}
}

/*
	needShowEndRound：是否需要显示最后的牌局结果
*/
void CGameTable::DisBandTable(int needShowEndRound)
{
	LogInfo("散桌", "执行散桌"); // try

	// 在第一局准备阶段散桌的才进行散桌时间设置
	if ((tbsNone == m_tstate) && (m_curRound == 1))
	{
		m_lastDisbandTime = GetNowMsTick();
		if (0 == m_lastDisbandTime)
			m_lastDisbandTime = 1;
	}

	// 解散桌子
	m_curRound = 0;
	endQuestDisband();

	SendEndRound2User(1, needShowEndRound);
	ClearTableUser(ERROR_CODE_USER_CLEAR_TABLE, "房间解散，系统强制您退出游戏");

	SetNotActive();
}

int CGameTable::ProcClientReady(T_VECTOR_OBJECT* p, int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
        return -1;
    if(p->size() != 1)
    {
        LogError("CGameTable::ProcClientReady", "p->size() error");
        return -1;
    }
    int index = 0;
    int64_t i64Param = (*p)[index++]->vv.i64;

    CTableUser* pTUser = m_userList[chairIndex];
    int code = 0;
    string retMsg = "";
    try
    {
        if(IsGaming())
            ThrowException(1, "游戏已经开始");
        if(pTUser->isReady)
            ThrowException(2, "您已经准备");
        if (m_curRound <= 0)
            ThrowException(ERROR_CODE_TO_MAX_ROUND, "对不起，创建的牌局已经结束");
    }
    catch(CException& ex)
    {
        code = ex.GetCode();
        retMsg = ex.GetMsg();
    }

    {
        CPluto* puResp = new CPluto();
        (*puResp).Encode(MSGID_CLIENT_READY_RESP) << code << retMsg << EndPluto;
        SendPlutoToUser(puResp, pTUser);
    }

    if(0 == code)
    {
        DoUserReady(pTUser);
    }

    return 0;
}

int CGameTable::ProcClientTrust(T_VECTOR_OBJECT* p, int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
        return -1;
    if(p->size() != 1)
    {
        LogError("CGameTable::ProcClientTrust", "p->size() error");
        return -1;
    }
    int index = 0;
    int32_t isTrust = (*p)[index++]->vv.i32;

    CTableUser* pTUser = m_userList[chairIndex];
    int code = 0;
    string retMsg = "";
    try
    {
        if(!IsGaming())
        {
            ThrowException(1, "游戏还没有开始");
        }
        if(0 != isTrust && 1 != isTrust)
        {
            ThrowException(2, "参数错误");
        }
        if(pTUser->isTrust == isTrust)
        {
            ThrowException(3, "参数错误");
        }
    }
    catch(CException& ex)
    {
        code = ex.GetCode();
        retMsg = ex.GetMsg();
    }

    if(0 == code)
    {
        DoUserTrust(pTUser, isTrust, pTUser->userInfo.baseInfo.userId);
		pTUser->manualTrust = isTrust;
    }

    {
        // 返回包 发送当前isTrust状态
        CPluto* puResp = new CPluto();
        (*puResp).Encode(MSGID_CLIENT_G_TRUST_RESP) << code << retMsg << pTUser->isTrust << EndPluto;
        SendPlutoToUser(puResp, pTUser);
    }

    return 0;
}

int CGameTable::ProcClientSwapCards(T_VECTOR_OBJECT* p, int chairIndex)
{
    return 0;
}

int CGameTable::ProcClientSelDelSuit(T_VECTOR_OBJECT* p, int chairIndex)
{
	return 0;
}

int CGameTable::procClientMJAction(T_VECTOR_OBJECT* p, int chairIndex)
{
	if (!IsChairIndexValid(chairIndex))
		return -1;
	if (p->size() != 2)
	{
		LogError("CGameTable::procClientMJAction", "p->size() error");
		return -1;
	}
	int index = 0;
	int32_t tmpI = (*p)[index++]->vv.i32;
	string expandStr = *(*p)[index++]->vv.s;
	if ((tmpI < 0) || (tmpI >= mjaCount))
	{
		LogWarning("CGameTable::procClientMJAction", "mjAction: %d", tmpI);
		return 0;
	}
	TMJActionName mjAction = TMJActionName(tmpI);

	if (m_tstate != tbsDiscard)
	{
		LogInfo("procClientMJAction", "state error");
		return 0;
	}

	bool result = false;
	if (m_mjActionMgr.hasAcitonExact(chairIndex, mjAction, expandStr))
		result = m_mjActionMgr.applyAction(chairIndex, mjAction, expandStr);

	if (!result && (mjAction != mjaPass))
	{
		stringstream tmpStream;
		tmpStream << "动作失败: place: " << chairIndex << ", mjAction: " << CAPTION_MJAction[mjAction] << ", expandStr: " << expandStr << ";  ";
		m_mjActionMgr.debugStr(tmpStream);

		LogWarning("procClientMJAction", tmpStream.str().c_str()); // try
	}

	return 0;
}

int CGameTable::procClientChu(T_VECTOR_OBJECT* p, int chairIndex)
{
	if (!IsChairIndexValid(chairIndex))
		return -1;
	if (p->size() != 1)
	{
		LogError("CGameTable::procClientChu", "p->size() error");
		return -1;
	}
	int index = 0;
	int32_t cardId = (*p)[index++]->vv.i32;
	if (!isCardValid(cardId))
	{
		LogWarning("CGameTable::procClientChu", "cardId: %d", cardId);
		return 0;
	}

	if (m_tstate != tbsDiscard)
	{
		LogInfo("procClientChu", "state error");
		return 0;
	}
	
	CTableUser* pTUser = m_userList[chairIndex];

	// 胡牌玩家，服务端帮助做动作，客户端没有权限了。
	if (pTUser->hasHu)
		return 0;

	bool result = false;
	if (m_mjActionMgr.hasAciton(pTUser->userInfo.activeInfo.chairIndex, mjaChu))
		result = m_mjActionMgr.applyAction(pTUser->userInfo.activeInfo.chairIndex, mjaChu, to_string(cardId));

	if (!result)
	{
		stringstream tmpStream;
		tmpStream << "出牌失败: place: " << pTUser->userInfo.activeInfo.chairIndex << ", cardId: " << cardId << "   ";
		m_mjActionMgr.debugStr(tmpStream);
		
		LogWarning("procClientChu", tmpStream.str().c_str()); // try

		// todo: 给玩家发完整信息包同步一下。
	}

	return 0;
}

void CGameTable::OnReportScoreError(int code, const char* errorMsg)
{
    if(tbsCalcResult != m_tstate)
    {
        LogError("CGameTable::OnReportScoreError", "table state error");
        return;
    }

    LogWarning("CGameTable::OnReportScoreError", "code=%d errorMsg=%s", code, errorMsg);

	SendRoundResult2User();
    AddGameRound();
    RoundStopClearData();
}

void CGameTable::OnReportScoreSuccess(T_VECTOR_OBJECT* p, int index)
{
    if(tbsCalcResult != m_tstate)
    {
        LogError("CGameTable::OnReportScoreSuccess", "table state error");
        return;
    }

    SCisScoreReportRetItem tmpReportItem;
    T_VECTOR_OBJECT* pAry = (*p)[index++]->vv.oOrAry;
	uint16_t len = pAry->size();
    for(uint16_t i = 0; i < len; ++i)
    {
        T_VECTOR_OBJECT* pItem = (*pAry)[i]->vv.oOrAry;
        int indexItem = 0;
        tmpReportItem.ReadFromVObj(*pItem, indexItem);

        CTableUser* pTUser = FindUserById(tmpReportItem.userId);
        if(!pTUser)
        {
            LogError("CGameTable::OnReportScoreSuccess", "find userId=%d failed", tmpReportItem.userId);
        }
        else
        {
            pTUser->userInfo.baseInfo.score = tmpReportItem.score;
            pTUser->userInfo.baseInfo.bean = tmpReportItem.bean;
            pTUser->userInfo.baseInfo.level = tmpReportItem.level;
			// 对于积分局，incBean是积分而不是bean，是假象
            int64_t incZSCore = tmpReportItem.incBean;
//             AddUserTotalScore(tmpReportItem.userId, incZSCore);
            LogInfo("CGameTable::OnReportScoreSuccess", "userId = %d, incZscore = %lld", pTUser->userInfo.baseInfo.userId, incZSCore);

            // 同步内存信息
            SUserInfo* pUser = GetWorldGameArea()->FindUserById(tmpReportItem.userId);
            if(pUser)
            {
                pUser->baseInfo.score = tmpReportItem.score;
                pUser->baseInfo.bean = tmpReportItem.bean;
                pUser->baseInfo.level = tmpReportItem.level;
            }
        }
    }

	SendRoundResult2User();
    AddGameRound();
    RoundStopClearData();
}

void CGameTable::OnReportConsumeSpecialGoldError(T_VECTOR_OBJECT* p, int index)
{
    CPluto* pu = new CPluto();
    uint16_t len = m_sitUserList.size();
    (*pu).Encode(MSGID_CLIENT_G_CONSUME_SPECIAL_GOLD_NOTIFY) << len;

    for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
    {
        CTableUser* pTUser = iter->second;

        (*pu) << pTUser->userInfo.baseInfo.userId << (int64_t)0;
    }
    (*pu) << EndPluto;
    SendBroadTablePluto(pu, INVALID_USERID);
}

void CGameTable::OnReportConsumeSpecialGoldSuccess(T_VECTOR_OBJECT* p, int index)
{
    CPluto* pu = new CPluto();

    T_VECTOR_OBJECT* pAry = (*p)[index++]->vv.oOrAry;
    uint16_t len = pAry->size();
    (*pu).Encode(MSGID_CLIENT_G_CONSUME_SPECIAL_GOLD_NOTIFY) << len;

    SCisSpecialGoldComsumeRetItem tmpConsumeItem;
    for (uint16_t i = 0; i < len; ++i)
    {
        T_VECTOR_OBJECT* pItem = (*pAry)[i]->vv.oOrAry;
        int indexItem = 0;
        tmpConsumeItem.ReadFromVObj(*pItem, indexItem);

        CTableUser* pTUser = FindUserById(tmpConsumeItem.userId);
        if (!pTUser)
        {
            LogError("CGameTable::OnReportConsumeSpecialGoldSuccess", "find userId=%d failed", tmpConsumeItem.userId);
        }
        else
        {
            pTUser->userInfo.baseInfo.specialGold = tmpConsumeItem.specialGold;
            // 同步内存信息
            SUserInfo* pUser = GetWorldGameArea()->FindUserById(tmpConsumeItem.userId);
            int64_t incSpecialGold = 0;
            if (pUser)
            {
                incSpecialGold = tmpConsumeItem.specialGold - pUser->baseInfo.specialGold;
                pUser->baseInfo.specialGold = tmpConsumeItem.specialGold;
            }
            (*pu) << tmpConsumeItem.userId << incSpecialGold;
			LogInfo("CGameTable::OnReportConsumeSpecialGoldSuccess", "userId = %d, incSpecialGold = %lld", tmpConsumeItem.userId, incSpecialGold);
        }
    }
    (*pu) << EndPluto;

    SendBroadTablePluto(pu, INVALID_USERID);
}

void CGameTable::OnReportTotalScoreCallBack(int code, const char* errorMsg)
{
    if (0 != code)
    {
        LogWarning("CGameTable::OnReportTotalScoreCallBack", "code=%d errorMsg=%s", code, errorMsg);
    }
    else
    {
        LogInfo("CGameTable::OnReportTotalScoreCallBack", "ReportTotalScore is Success!!!");
    }
}


bool CGameTable::CheckRunTime()
{
    if (m_isActive)
    {
        if (m_lastRunTick.GetPassMsTick() >= 1000)
        {
            m_lastRunTick.AddMsTick(1000);
            RobotAction();
            RunTime();
        }

        return true;
    }
    else
    {
		if (GetDisBandInterval() > g_config_area->min_interval_reuse_table)
		{
			// 当解散时间大于解散时间限制时，才说明桌子是notActive的
			return false;
		}
		else
			return true;
    }
}

void CGameTable::SetNotActive()
{
    if (m_isActive)
    {
        m_isActive = false;
		// 退房
		if (GetVipRoomType() == vrtScoreOnePay)
		{
			if (GetIsConsumeSpecialGold())
			{
				if (m_hasReportScore)
				{
					// 说明游戏开始才散的桌，不能退房卡
					g_table_mgr->ReportToTableManager(this, ftmTuiZhuoBuTuiKa, 0);
				}
				else
				{
					// 说明没有开始就散桌了，需要退还房卡
					g_table_mgr->ReportToTableManager(this, ftmTuiZhuoTuiKa, 0);
				}
			}
			else
				g_table_mgr->ReportToTableManager(this, ftmTuiZhuoBuTuiKa, 0);
		}
		else
		{
			g_table_mgr->ReportToTableManager(this, ftmTuiZhuoBuTuiKa, 0);
		}

        RoundStopClearData();
        NoUserClearData();
		// 在这里设置一下房间没有被创建
		SetIsCreated(false);

        LogInfo("CGameTable::SetNotActive", "NoUserClearData handle=%d", m_handle);
    }
}

bool CGameTable::EnterTable(SUserInfo* pUser, int chairIndex)
{
    CTableUser* pTOldUser = FindUserById(pUser->baseInfo.userId);
    CTableUser* pTSitUser = FindUserByChairIndex(chairIndex);
    if(!pTSitUser)
    {
        LogError("CGameTable::EnterTable", "cannot find chairIndex");
        return false;
    }

    if(pTOldUser)
    {
        // 判断是否可以返回
        if(pTOldUser->ustate < tusNomal)
        {
            LogError("CGameTable::EnterTable", "user exists userId=%d", pTOldUser->userInfo.baseInfo.userId);
            return false;
        }
        if(pTOldUser != pTSitUser)
        {
            LogError("CGameTable::EnterTable", "offline return chairIndex error");
            return false;
        }

        SetIsActive();
        LogInfo("CGameTable::EnterTable", "offline return success userId= %d", pUser->baseInfo.userId);
        AddUser(pUser, chairIndex);
        pTOldUser->ustate = tusNomal;
        pTOldUser->userInfo.CopyFrom(*pUser);

        // 通知他人用户状态变化
        SendUserStateNotify(pUser->baseInfo.userId, chairIndex,  pTOldUser->ustate, pUser->baseInfo.bean);
        return true;
    }
    else
    {
        if (pTSitUser->ustate != tusNone)
        {
            LogError("CGameTable::EnterTable", "chairIndex=%d has a user", chairIndex);
            return false;
        }

        if (IsGaming())
        {
            if(!GAME_CAN_ENTER_WHEN_GAMING)
            {
                LogError("CGameTable::EnterTable", "table is gaming handle=%d", m_handle);
                return false;
            }
            
            if(GAME_CAN_DIRECT_GAME)
                pTSitUser->ustate = tusNomal;
            else
                pTSitUser->ustate = tusWaitNextRound;
        }
        else
        {
            pTSitUser->ustate = tusNomal;
        }

        SetIsActive();
        LogInfo("CGameTable::EnterTable", "sit success userId= %d handle=%d chairIndex=%d", pUser->baseInfo.userId, m_handle, chairIndex);
        AddUser(pUser, chairIndex);
        pTSitUser->userInfo.CopyFrom(*pUser);
        pTSitUser->userInfo.activeInfo.enterTableTick = GetNowMsTick();

		if (m_createUserId == pUser->baseInfo.userId)
		{
			m_eastPlace = chairIndex;
			m_bankerPlace = chairIndex;
		}
        // 通知其他人有人入座
		// try
		LogInfo("CGameTable::EnterTable", "sit success userId= %d ip=%s", pUser->baseInfo.userId, pTSitUser->userInfo.activeInfo.ip.c_str());
        CPluto* pu = new CPluto();
        (*pu).Encode(MSGID_CLIENT_OTHER_ENTER_NOTIFY) << chairIndex << pTSitUser->isReady << pTSitUser->ustate 
			<< GetUserTotalScore(pTSitUser->userInfo.baseInfo.userId) << pTSitUser->userInfo.baseInfo.ip;
        pTSitUser->userInfo.baseInfo.WriteToPluto(*pu);
        (*pu) << EndPluto;
        SendBroadTablePluto(pu, pUser->baseInfo.userId);

        return true;
    }
}

bool CGameTable::LeaveTable(int userId)
{
    bool isOffline = false;
    CTableUser* pTUser = OnlyNomalLeaveTable(userId, isOffline);

    if (isOffline)
    {
        pTUser->ustate = tusOffline;
        pTUser->offlineTick = GetNowMsTick();
        // 通知用户状态改变
        SendUserStateNotify(userId, pTUser->userInfo.activeInfo.chairIndex,  pTUser->ustate, pTUser->userInfo.baseInfo.bean);
    }

    return true;
}

CTableUser* CGameTable::OnlyNomalLeaveTable(int userId, bool& mayOffline)
{
    mayOffline = false;
    CTableUser* pTUser = FindUserById(userId);
    if(!pTUser)
    {
        LogError("CGameTable::OnlyNomalLeaveTable", "not find user");
        return NULL;
    }
    if(pTUser->ustate > tusNomal)
    {
        LogError("CGameTable::OnlyNomalLeaveTable", "user state not normal");
        return NULL;
    }

	// 注释掉之后相当于下面的约局没结束不能清除玩家就没有用了
    if(IsGaming())
    {
        if (!CanLeaveWhenGaming(pTUser))
        {
            mayOffline = true;
        }
    }

    if (!mayOffline)
    {
		if (m_curRound <= 0)
		{
			// 约局结束清除玩家
			ClearUser(pTUser);
		}
		else
		{
			// 约局没结束不能直接清除玩家
			mayOffline = true;
		}
    }

    return pTUser;
}

void CGameTable::ClientUpdateUserInfo(SUserBaseInfo& baseInfo, int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
    {
        LogError("CGameTable::ClientUpdateUserInfo", "chairIndex error");
        return;
    }
    CTableUser* pTUser = m_userList[chairIndex];
    if(tusNone == pTUser->ustate || baseInfo.userId != pTUser->userInfo.baseInfo.userId)
    {
        LogError("CGameTable::ClientUpdateUserInfo", "no user or userId error");
        return;
    }

    pTUser->userInfo.baseInfo.CopyFrom(baseInfo);
    SendUserStateNotify(baseInfo.userId, chairIndex,  pTUser->ustate, baseInfo.bean);
}

void CGameTable::SendStartGameNotify(int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
    {
        LogError("CGameTable::SendStartGameNotify", "chairIndex error");
        return;
    }
    CTableUser* pTUser = m_userList[chairIndex];
    CMailBox* mb = GetTUserMailBox(pTUser);
    if(!mb)
    {
        LogError("CGameTable::SendStartGameNotify", "!mb");
        return;
    }

    // 通知开始游戏
    {
        CPluto* puStart = new CPluto();
        (*puStart).Encode(MSGID_CLIENT_BEGINGAME_NOTIFY) << m_handle << m_tstate << chairIndex << pTUser->isReady << pTUser->ustate << GetUserTotalScore(pTUser->userInfo.baseInfo.userId)
			<< m_curBaseScore << m_minBean << m_curRound << m_maxRound << m_tableNum << m_eastPlace << int32_t(MAX_TABLE_USER_COUNT);
        m_tableRule.WriteTableRuleToPluto(*puStart);
        (*puStart) << EndPluto;
        mb->PushPluto(puStart);
    }

    // 通知用户列表
    for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
    {
        CTableUser* pItem = iter->second;
        if(pItem != pTUser)
        {
			// try
			LogInfo("CGameTable::SendStartGameNotify", "userId = %d, ip = %s", pTUser->userInfo.baseInfo.userId, pTUser->userInfo.activeInfo.ip.c_str());
            CPluto* pu = new CPluto();
            (*pu).Encode(MSGID_CLIENT_OTHER_ENTER_NOTIFY) << pItem->userInfo.activeInfo.chairIndex << pItem->isReady << pItem->ustate
				<< GetUserTotalScore(pItem->userInfo.baseInfo.userId) << pItem->userInfo.baseInfo.ip;
            pItem->userInfo.baseInfo.WriteToPluto(*pu);
            (*pu) << EndPluto;
            mb->PushPluto(pu);
        }
    }

    if(IsGaming())
    {
		int decTimeCount = m_decTimeCount;
		if (m_tstate == tbsDiscard)
			decTimeCount = m_mjActionMgr.getDecTimeCount();
		// 通知完整信息 开始游戏和用户列表已经发送的数据就不用重复了
        int isMoBao = (m_mjDataMgr.FBaoPaiCardID != MJDATA_CARDID_ERROR) ? 1 : 0;
		CPluto* puSyn = new CPluto();
		(*puSyn).Encode(MSGID_CLIENT_G_SYN_NOTIFY) << m_tstate << m_mjDataMgr.FCurrPlace << decTimeCount <<
			int32_t(m_mjActionMgr.FTimerState) << m_eastPlace << m_bankerPlace << m_mjDataMgr.FLastChuPaiPlace 
			<< m_mjDataMgr.FLastCardID << int32_t(pTUser->isSwaped) << m_swapDirection << m_curRound << m_maxRound << isMoBao << int32_t(MAX_TABLE_USER_COUNT);
		m_mjDataMgr.FMJPaiQiang->WriteToPluto(*puSyn);
		m_mjDataMgr.FMJShouPai->WriteToPluto(pTUser->userInfo.activeInfo.chairIndex, *puSyn);
		WriteCardsToPluto(pTUser->selSwapCards, *puSyn);
		m_mjDataMgr.FMJActionMgr->writeUserAction2Pluto(pTUser->userInfo.activeInfo.chairIndex, puSyn);
		m_mjDataMgr.FMJMingPai->WriteToPluto(*puSyn);
		m_mjDataMgr.FMJZhuoPai->WriteToPluto(*puSyn);

	/*	(*puSyn) << uint16_t(MAX_TABLE_USER_COUNT);
		for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
		{
			CTableUser* pTUser = FindUserByChairIndex(i);
			(*puSyn) << pTUser->userInfo.baseInfo.userId << pTUser->isTrust << int32_t(pTUser->hasHu) << int32_t(pTUser->hasTing) << pTUser->piaoType;
			if (pTUser->hasHu)
			{
				uint16_t count = 0;
				for (auto it = pTUser->huPaiInfo.begin(); it != pTUser->huPaiInfo.end(); it++)
				{
					if ((*it).isWinner)
						count++;
				}
				(*puSyn) << count;
				if (count > 0)
				{
					for (auto it = pTUser->huPaiInfo.begin(); it != pTUser->huPaiInfo.end(); it++)
					{
						if ((*it).isWinner)
							(*puSyn) << (*it).lastCardId;
					}
				}
			}
			else
			{
				(*puSyn) << uint16_t(0);
			}
			(*puSyn) << int32_t(m_mjDataMgr.FMJShouPai->getUserCardList(i).size());
		}*/

		(*puSyn) << uint16_t(MAX_TABLE_USER_COUNT);
		for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
		{
			CTableUser* pTUser = FindUserByChairIndex(i);
			(*puSyn) << pTUser->userInfo.baseInfo.userId << int32_t(m_mjDataMgr.FMJShouPai->getUserCardList(i).size());
		}


		(*puSyn) << EndPluto;
		mb->PushPluto(puSyn);
    }
	else
	{
		if (!pTUser->isReady)
		{
			CPluto* puReady = new CPluto();
			(*puReady).Encode(MSGID_CLIENT_G_DO_READY_NOTIFY) << EndPluto;
			SendPlutoToUser(puReady, pTUser);
		}
	}

	// 正在散桌过程中，重新发送散桌请求
	if (m_isQuestDisband)
	{
		if (pTUser->agreeEnd == 0)
		{
			CPluto* puNotify = new CPluto();
			(*puNotify).Encode(MSGID_CLIENT_DISBAND_TABLE_NOTIFY) << 0 << m_questDisbandUserId <<
				0 << m_decTimeQuestDisband << EndPluto;
			SendPlutoToUser(puNotify, pTUser);
		}
	}
}

int CGameTable::GetEmptyChairAry(int* chairAry)
{
    int len = 0;
    int maxLen = m_userList.size();
    // 优先进入空位置
    for(int i = 0; i < maxLen; ++i)
    {
        CTableUser* pItem = m_userList[i];
        if(tusNone == pItem->ustate)
        {
            chairAry[len] = i;
            ++len;
        }
    }

    return len;
}

void CGameTable::RunTime()
{
    if (m_clearRemainSec != INVALID_TIME_COUNT)
    {
        // 处理定时清理桌子
        --m_clearRemainSec;
        if (m_clearRemainSec <= 0)
            SetNotActive();

        return;
    }

	// 请求散桌倒计时
	if (m_isQuestDisband)
	{
		--m_decTimeQuestDisband;
		if (m_decTimeQuestDisband < 0)
		{
			for (auto it = m_userList.begin(); it != m_userList.end(); it++)
			{
				if ((*it)->agreeEnd == 0)
				{
					DoUserDisbandTable(*it, 1, 1);
				}
			}
		}
		else
		{
			CheckAllUserAgreeClearTable();
		}
	}

	// 在第一局准备阶段清除掉线三分钟之后的人
	if (m_tstate == tbsNone && m_curRound == 1)
	{
		uint32_t nowTick = GetNowMsTick();
		int len = m_userList.size();
		for (int i = 0; i < len; ++i)
		{
			CTableUser* pItem = m_userList[i];
			if (pItem->ustate == tusOffline && 
				GetMsTickDiff(pItem->offlineTick, nowTick) >= (uint32_t)g_config_area->max_leaveTime_sec * MS_PER_SEC &&
				GetCreateUserId() != pItem->userInfo.baseInfo.userId)
			{
				ClearUser(pItem);
			}
		}
	}

    switch (m_tstate)
    {
    case tbsNone:
        {
			--m_decTimeCount;
			int readyCount = 0;
			for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
			{
				if (iter->second->isReady)
					++readyCount;
			}
			bool isEnd = readyCount >= MIN_TABLE_USER_COUNT;
			if (m_decTimeCount <= 0)
			{
				isEnd = true;
				for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
				{
					if (!iter->second->isReady)
						DoUserReady(iter->second);
				}
			}
			if (isEnd)
			{
				CheckCanDealCard();
				// 所有人准备，向cis上报桌子游戏已经开始的状态
				ReportTableStartState();
			}
	            
            break;
        }
    case tbsDealCard:
        {
            --m_decTimeCount;
			if (m_decTimeCount <= 0)
				StartDiscard();
            break;
        }
    case tbsDiscard:
        {
			m_mjActionMgr.doActionStateRunTime();
			break;
        }
	case tbsShowTheLastCard:
        {
			--m_decTimeCount;
			if (m_decTimeCount <= 0)
			{
				StartReportScore();
				m_tstate = tbsCalcResult;
			}
			break;
        }
    case tbsCalcResult:
        {
            break;
        }
    }


    {
        // 处理断线超时
        uint32_t nowTick = GetNowMsTick();
        for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
        {
            CTableUser* pItem = iter->second;
            if(tusOffline == pItem->ustate)
            {
                if(GetMsTickDiff(pItem->offlineTick, nowTick) >= (uint32_t)g_config_area->max_offline_sec * MS_PER_SEC)
                {
                    LogInfo("CGameTable::RunTime", "断线超时 userId = %d", pItem->userInfo.baseInfo.userId);
                    pItem->ustate = tusFlee;
                    SendUserStateNotify(pItem->userInfo.baseInfo.userId, pItem->userInfo.activeInfo.chairIndex,
						tusFlee, pItem->userInfo.baseInfo.bean);
                }
            }
        }
    }
}

void CGameTable::RobotAction()
{
    if(!IsGaming())
    {
        {
            // 暂时不踢出长时间不ready的人
        }

    }
}

void CGameTable::SetIsActive()
{
    // 有人进入则倒计时结束。
    m_clearRemainSec = INVALID_TIME_COUNT;

    if(!m_isActive)
    {
        m_isActive = true;
        m_lastRunTick.SetNowTime();
        m_endGameTick = GetNowMsTick();
        for(vector<CTableUser*>::iterator iter = m_userList.begin(); iter != m_userList.end(); ++iter)
        {
            (*iter)->readyOrLeaveTick = GetNowMsTick();
        }
    }
}

void CGameTable::ClearTableUser(int errCode, const char* errMsg)
{
    int len = m_userList.size();
    for (int i = 0; i < len; i++)
    {
        CTableUser* pItem = m_userList[i];
        if (pItem->ustate != tusNone)
        {
            SendForceLeaveNotify(pItem, errCode, errMsg);
            ClearUser(pItem);
        }
    }
}

void CGameTable::NoUserClearData()
{
    // 桌子的人都离开，清理信息，比如统计信息
    m_tstate = tbsNone;
    m_curBaseScore = -1;
	/*if (m_createUserId != INVALID_USERID)
		g_table_mgr->RemoveUserCreateTable(m_createUserId);*/
    m_createUserId = INVALID_USERID;
    m_maxRound = 0;
    m_minBean = 0;
    m_tableNum = "";
    m_curRound = 0;
    m_clearRemainSec = INVALID_TIME_COUNT;
    m_minSpecialGold = 0;
    m_vipRoomType = vrtNone;
    m_isConsumeSpecialGold = false;
	m_isQuestDisband = false;
	m_decTimeQuestDisband = -1;
    m_openSeriesNums.clear();
    ClearTotalScore();
	m_hasReportScore = false;
	m_optionStr.clear();
}

void CGameTable::RoundStopClearData()
{
    // 每局结束清理信息，比如断线和逃跑玩家、游戏状态
    m_tstate = tbsNone;
    m_endGameTick = GetNowMsTick();
    m_decTimeCount = 600;
    m_roundFee = 0;

    int len = m_userList.size();
   
	// 清理断线用户
	if (m_curRound <= 0)
	{
		for (int i = 0; i < len; i++)
		{
			CTableUser* pItem = m_userList[i];
			if (pItem->ustate > tusNomal)
			{
				ClearUser(pItem);
			}
		}
	}

    // 清理游戏豆不足用户 机器人正常踢出，下次分桌机器人就自动加豆
    if (vrtBean == m_vipRoomType)
    {
        for (int i = 0; i < len; i++)
        {
            CTableUser* pItem = m_userList[i];
            if (pItem->ustate != tusNone)
            {
                // 进入条件判断
                int minBean = m_minBean;
                if (pItem->userInfo.baseInfo.bean < minBean)
                {
                    char buffer[100];
                    snprintf(buffer, sizeof(buffer), "您的%s不足%d，系统强制您退出游戏", g_config_area->bean_name.c_str(), minBean);
                    SendForceLeaveNotify(pItem, ERROR_CODE_BEAN_TOO_LITTLE, buffer);

                    ClearUser(pItem);
                }
            }
        }
    }
    
    // 清理游戏数据
    for(int i = 0; i < len; i++)
    {
        CTableUser* pItem = m_userList[i];
        if(pItem->ustate != tusNone)
        {
			pItem->RoundStopClearData();
            if(tusWaitNextRound == pItem->ustate)
            {
                pItem->ustate = tusNomal;
                SendUserStateNotify(pItem->userInfo.baseInfo.userId, pItem->userInfo.activeInfo.chairIndex,  pItem->ustate, pItem->userInfo.baseInfo.bean);
            }
        }
    }

	m_mjDataMgr.RoundStopClearData();
}

void CGameTable::AddGameRound()
{
    //++m_curRound;
    CTableUser* pNorthTUser = FindUserByChairIndex(3);
    if (m_bankerPlace == 3 && !pNorthTUser->hasHu)
        ++m_curRound;

    // 判断下局庄家位置
    CTableUser* pTUser = FindUserByChairIndex(m_bankerPlace);
    if (pTUser && !pTUser->hasHu)
    {
		m_bankerPlace = (m_bankerPlace + 1) % MAX_TABLE_USER_COUNT;
    }
    if (m_curRound > m_maxRound)
    {
        SendEndRound2User(0, 1);
        m_curRound = 0;
    }
}

void CGameTable::AddUser(SUserInfo* pUser, int chairIndex)
{
    pUser->activeInfo.userState = EUS_INTABLE;
    pUser->activeInfo.tableHandle = m_handle;
    pUser->activeInfo.chairIndex = chairIndex;

    int userId = pUser->baseInfo.userId;
    if(m_sitUserList.find(userId) == m_sitUserList.end())
    {
        m_sitUserList.insert(make_pair(userId, m_userList[chairIndex]));
        g_table_mgr->AddSitUser(userId, m_handle, chairIndex);
    }
}

void CGameTable::UnlockUser(CTableUser* pTUser)
{

	CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
	if (mbDbmgr)
	{
		//创建任务
		CAreaTaskLockOrUnlockUser* task = new CAreaTaskLockOrUnlockUser();
		GetWorldGameArea()->AddTask(task);

		LogInfo("CGameTable::UnlockUser", "handle=%d", m_handle);

		// 为了延续task，即使未连接，也要创建task
		if (!mbDbmgr->IsConnected())
		{
			LogWarning("CGameTable::UnlockUser", "!mbDbmgr->IsConnected()");
		}
		else
		{
			int32_t gameRoomId = g_config_area->gameRoomId;
			int32_t userId = pTUser->userInfo.baseInfo.userId;
			int32_t type = -1;

			CPluto* pu = new CPluto;
			(*pu).Encode(MSGID_DBMGR_LOCK_GAMEROOM) << task->GetTaskId() << gameRoomId << userId << type;
			(*pu) << EndPluto;
			mbDbmgr->PushPluto(pu);
		}
	}
	else
	{
		LogError("CGameTable::UnlockUser", "!mbDbmgr");
	}

}

void CGameTable::ClearUser(CTableUser* pTUser)
{
    int userId = pTUser->userInfo.baseInfo.userId;
	int place = pTUser->userInfo.activeInfo.chairIndex;
    m_sitUserList.erase(userId);
    g_table_mgr->RemoveSitUser(userId);

	// 放在这里不知道对不对！！
	UnlockUser(pTUser);

    pTUser->Clear();
    SUserInfo* pUser = GetWorldGameArea()->FindUserById(userId);
    if(pUser)
    {
        pUser->activeInfo.userState = EUS_AUTHED;
        pUser->activeInfo.tableHandle = -1;
        pUser->activeInfo.chairIndex = -1;
    }

    // 给其他人发送离开桌子包
    CPluto* pu = new CPluto();
    (*pu).Encode(MSGID_CLIENT_OTHER_LEAVE_NOTIFY) << userId << place << EndPluto;
    SendBroadTablePluto(pu, userId);

    if(m_sitUserList.size() <= 0)
    {
        if (m_curRound <= 0)
            m_clearRemainSec = 0;
        else
            m_clearRemainSec = g_config_area->table_remain_sec;
    }

    LogInfo("CGameTable::ClearUser", "userId=%d left user count=%d", userId, m_sitUserList.size());
}

CTableUser* CGameTable::FindUserById(int userId)
{
    map<int, CTableUser*>::iterator iter = m_sitUserList.find(userId);
    if (m_sitUserList.end() == iter)
        return NULL;

    return iter->second;
}

CTableUser* CGameTable::FindUserByChairIndex(int chairIndex)
{
    if(!IsChairIndexValid(chairIndex))
        return NULL;

    return m_userList[chairIndex];
}

CTableUser* CGameTable::FindSitUserByChairIndex(int chairIndex)
{
    if(!(IsChairIndexValid(chairIndex)))
        return NULL;

    CTableUser* ret = m_userList[chairIndex];
    if (ret->ustate == tusNone)
        return NULL;

    return ret;
}

void CGameTable::SetTableRule(TTableRuleInfo tableRule)
{
    m_tableRule = tableRule;
    m_mjDataMgr.RoundStopClearData();
}

CMailBox* CGameTable::GetTUserMailBox(CTableUser* pTUser)
{
    CMailBox* ret = NULL;
    if(HasFd(pTUser))
    {
        CMailBox* mb = GetWorld()->GetServer()->GetFdMailbox(pTUser->userInfo.activeInfo.fd);
        if(mb)
        {
            ret = mb;
        }
        else
        {
            LogError("CGameTable::GetTUserMailBox", "find mb failed. userId=%d", pTUser->userInfo.baseInfo.userId);
        }
    }

    return ret;
}

void CGameTable::ClearTotalScore()
{
    m_totalScore.clear();
}

void CGameTable::CheckMayClearTotalScore()
{
    // 新人加入，开始游戏后，判断是否清理统计
    for (map<int, int64_t>::iterator iter = m_totalScore.begin(); iter != m_totalScore.end(); ++iter)
    {
        if (!FindUserById(iter->first))
        {
            ClearTotalScore();
            LogInfo("CGameTable::CheckMayClearTotalScore", "clear TotalScore handle=%d", m_handle);
            return;
        }
    }
}

int32_t CGameTable::GetUserTotalScore(int userId)
{
    map<int, int64_t>::iterator iter = m_totalScore.find(userId);
    if (m_totalScore.end() == iter)
        return 0;
    else
        return iter->second;
}

void CGameTable::AddUserTotalScore(int userId, int64_t incScore)
{
    map<int, int64_t>::iterator iter = m_totalScore.find(userId);
    if (m_totalScore.end() == iter)
        m_totalScore.insert(make_pair(userId, incScore));
    else
        iter->second += incScore;
}

void CGameTable::SendBroadTablePluto(CPluto* pu, int ignoreUserId)
{
    for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
    {
        CTableUser* pTUser = iter->second;
        if(pTUser->userInfo.baseInfo.userId != ignoreUserId)
        {
            CMailBox* mb = GetTUserMailBox(pTUser);
            if(mb)
            {
                CPluto* pSend = new CPluto(pu->GetLen());
                pSend->OverrideBuffer(pu->GetBuff(), pu->GetLen());
                mb->PushPluto(pSend);
            }
        }
    }

    delete pu;
}

void CGameTable::SendPlutoToUser(CPluto* pu, CTableUser* pTUser)
{
    CMailBox* mb = GetTUserMailBox(pTUser);
    if(mb)
    {
        mb->PushPluto(pu);
    }
    else
    {
        delete pu;
    }
}

void CGameTable::SendForceLeaveNotify(CTableUser* pTUser, int code, const char* errorMsg)
{
    CPluto* pu = new CPluto();
    (*pu).Encode(MSGID_CLIENT_FORCE_LEAVE_NOTIFY) << code << errorMsg << EndPluto;
    SendPlutoToUser(pu, pTUser);
}

void CGameTable::DoUserReady(CTableUser* pTUser)
{
    if(!pTUser->isReady)
    {
        pTUser->isReady = true;
        pTUser->readyOrLeaveTick = GetNowMsTick();

        int userId = pTUser->userInfo.baseInfo.userId;
        CPluto* pu = new CPluto();
        (*pu).Encode(MSGID_CLIENT_OTHER_READY_NOTIFY) << pTUser->userInfo.activeInfo.chairIndex << EndPluto;
        SendBroadTablePluto(pu, -1);
    }
    else
    {
        LogError("CGameTable::DoUserReady", "isReady");
    }
}

void CGameTable::DoUserTrust(CTableUser* pTUser, int isTrust, int ignoreUserId)
{
    if(pTUser->isTrust != isTrust)
    {
        pTUser->isTrust = isTrust;

        int userId = pTUser->userInfo.baseInfo.userId;
        CPluto* pu = new CPluto();
        (*pu).Encode(MSGID_CLIENT_G_OTHER_TRUST_NOTIFY) << userId << isTrust << EndPluto;
        SendBroadTablePluto(pu, ignoreUserId);
    }
    else
    {
        LogError("CGameTable::DoUserTrust", "trust state error");
    }
}

void CGameTable::DoUserSwapCard(CTableUser* pTUser, vector<int>& selCardList)
{
	pTUser->isSwaped = true;
	pTUser->selSwapCards.resize(selCardList.size());
	copy(selCardList.begin(), selCardList.end(), pTUser->selSwapCards.begin());
}

void CGameTable::CheckCanDealCard()
{
    if(tbsNone != m_tstate)
    {
        LogError("CGameTable::CheckCanDealCard", "state error");
        return;
    }

    int readyCount = 0;
    for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
    {
        if(iter->second->isReady)
            ++readyCount;
        else
            return;
    }

    if(readyCount < MIN_TABLE_USER_COUNT)
        return;

    // 房主单人付费，第一局不在，不能开局，散桌
	/* if (1 == m_curRound && vrtScoreOnePay == m_vipRoomType)
	 {
	 if (!FindUserById(m_createUserId))
	 {
	 char buffer[100];
	 snprintf(buffer, sizeof(buffer), "房主[%d]不在，系统强制您退出游戏", GetCreateUserId());
	 ClearTableUser(ERROR_CODE_SOMEONE_LEAVE, buffer);
	 return;
	 }
	 }*/

    uint64_t stamp = GetTimeStampInt64Ms();
    snprintf(m_gameStartMsStamp, sizeof(m_gameStartMsStamp), "%llu", stamp);

    // 记录整个桌子的游戏开始时间
    if (1 == m_curRound)
    {
        snprintf(m_fstStartMsStamp, sizeof(m_fstStartMsStamp), "%llu", stamp);
    }

    m_tstate = tbsDealCard;
	m_decTimeCount = g_config_area->dealCard_Sec; 

	// dice dealCards
	{
		m_diceValue[0] = GetRandomRange(1, 6);
		m_diceValue[1] = GetRandomRange(1, 6);
		
		m_startReaminedPaiQiangCnt = m_diceValue[0] < m_diceValue[1] ? m_diceValue[0] : m_diceValue[1];
		m_startZhuaPlace = (m_bankerPlace + m_diceValue[0] + m_diceValue[1] - 1) % MIN_TABLE_USER_COUNT;
		m_mjDataMgr.procZhuaPai(m_bankerPlace, m_startZhuaPlace, m_startReaminedPaiQiangCnt);
	}

    // send pack
    for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
    {
        CTableUser* pTUser = iter->second;

        CPluto* pu = new CPluto();
		(*pu).Encode(MSGID_CLIENT_G_DEALCARD_NOTIFY) << m_diceValue[0] << m_diceValue[1] << m_eastPlace <<
			m_bankerPlace << m_curRound << m_maxRound;
		m_mjDataMgr.FMJPaiQiang->WriteToPluto(*pu);
		m_mjDataMgr.FMJShouPai->WriteToPluto(pTUser->userInfo.activeInfo.chairIndex, *pu);
        (*pu) << EndPluto;
        SendPlutoToUser(pu, pTUser);
    }

    // 游戏开局就扣费（现改成第一局结束时扣费）
    //StartConsumeSpecialGold();
    CheckMayClearTotalScore();
}

void CGameTable::startSwapCard()
{
	
}

void CGameTable::swapUserCard()
{
	for (int i = 0; i < MAX_TABLE_USER_COUNT; ++i)
	{
		CTableUser* pTUser = m_userList[i];
		CTableUser* pFromTUser;
		// 换牌方向，0：对家换牌，1：上家拿下家，2：下家拿上家
		if (m_swapDirection == 0)
			pFromTUser = m_userList[(i + 2) % MAX_TABLE_USER_COUNT];
		else if (m_swapDirection == 2)
			pFromTUser = m_userList[(i + 3) % MAX_TABLE_USER_COUNT];
		else
			pFromTUser = m_userList[(i + 1) % MAX_TABLE_USER_COUNT];

   		m_mjDataMgr.FMJShouPai->swapCards(pTUser->userInfo.activeInfo.chairIndex, pFromTUser->selSwapCards,
   			pTUser->selSwapCards);   // try， 测试，先去掉

		pTUser->selDelSuit = mjcsError;

		pTUser->getSwapCards.clear();
		pTUser->getSwapCards.resize(pFromTUser->selSwapCards.size());
		copy(pFromTUser->selSwapCards.begin(), pFromTUser->selSwapCards.end(), pTUser->getSwapCards.begin());

		CPluto* pu = new CPluto();
		(*pu).Encode(MSGID_CLIENT_G_SWAP_CARD_NOTIFY) << m_diceValue[2] << m_swapDirection << m_decTimeCount;

		WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(pTUser->userInfo.activeInfo.chairIndex), *pu);
		WriteCardsToPluto(pFromTUser->selSwapCards, *pu);
		WriteCardsToPluto(pTUser->selSwapCards, *pu);
		(*pu) << EndPluto;
		SendPlutoToUser(pu, pTUser);
	}
}

void CGameTable::startSelDeleterCard()
{
	
}

void CGameTable::StartSelectPiaoTypeByUser()
{
	
}

void CGameTable::StartDiscard()
{
	LogInfo("StartDiscard", "开始出牌");
    m_tstate = tbsDiscard;
	m_decTimeCount = g_config_area->discard_sec;

	m_mjActionMgr.beginXingPai();

    {
		vector<int> tmpVector;
		for (auto it = m_userList.begin(); it != m_userList.end(); it++)
		{
			tmpVector.push_back((*it)->selDelSuit);
		}

		for (auto it = m_userList.begin(); it != m_userList.end(); it++)
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MSGID_CLIENT_G_SEL_DEL_SUIT_NOTIFY) << tmpVector[0] << tmpVector[1] <<
				tmpVector[2] << tmpVector[3] << m_mjDataMgr.FCurrPlace << m_mjActionMgr.getDecTimeCount();
			m_mjActionMgr.writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
			(*pu) << EndPluto;
			SendPlutoToUser(pu, (*it));
		}
    }
}

void CGameTable::debugTotalScore()
{
	stringstream tmpStream;
	tmpStream << "有分数变化，当前各玩家分数 --- " << endl;
	for (int i = 0; i < 4; i++)
	{
		CTableUser* pTUser = FindUserByChairIndex(i);
		if (pTUser)
		{
			tmpStream << i << ": " << GetUserTotalScore(pTUser->userInfo.baseInfo.userId) << "  ; " << endl;
		}
	}
	LogInfo("分数", "%s", tmpStream.str().c_str());
}

void CGameTable::writeTotalScore2Pluto(CPluto* pu)
{
	(*pu) << uint16_t(MAX_TABLE_USER_COUNT);
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		CTableUser* pTUser = FindUserByChairIndex(i);
		if (pTUser)
		{
			(*pu) << GetUserTotalScore(pTUser->userInfo.baseInfo.userId);
		}
		else
		{
			LogError("writeTotalScore2Pluto", "noPlayer: %d", i);
		}
	}
}

void CGameTable::StartReportScore()
{
    CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
    if(mbDbmgr)
    {
        //创建任务
        CAreaTaskReportScore* task = new CAreaTaskReportScore(m_handle);
        GetWorldGameArea()->AddTask(task);

        LogInfo("CGameTable::StartReportScore", "handle=%d", m_handle);

        // 为了延续task，即使未连接，也要创建task
        if(!mbDbmgr->IsConnected())
        {
            LogWarning("CGameTable::StartReportScore", "!mbDbmgr->IsConnected()");
        }
        else
        {
			uint32_t areaId = GetWorldGameArea()->GetServer()->GetMailboxId();
			int32_t gameRoomId = g_config_area->gameRoomId;
			//1表示这是个需要锁定场
			int32_t isLockGameRoom = 0;

            char openSeriesNum[100];
            uint64_t stamp = GetTimeStampInt64Ms();
            snprintf(openSeriesNum, sizeof(openSeriesNum), "%uA%dA%llu", areaId, m_handle, stamp);

            if (1 == m_curRound)
            {
                // 此时是第一局
                m_openSeriesNums.clear();
                m_openSeriesNums += string(openSeriesNum);
            }
            else
            {
                // 每局之间用逗号隔开
                m_openSeriesNums += "," + string(openSeriesNum);
            }

			//这里值为0表示整桌游戏没有全部结束，为1代表结束
			int isVipRoomEnd = 0;
			if (m_curRound + 1 > m_maxRound)
				isVipRoomEnd = 1;

			m_hasReportScore = true;

			int baseScore = m_curBaseScore;
			CPluto* pu = new CPluto;
			(*pu).Encode(MSGID_DBMGR_REPORT_SCORE) << task->GetTaskId() << areaId << gameRoomId << isLockGameRoom << openSeriesNum << m_gameStartMsStamp \
				<< baseScore << m_roundFee << isVipRoomEnd << m_tableNum << m_curRound;
            uint16_t len = m_sitUserList.size();
            (*pu) << len;
            for(map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
            {
                CTableUser* pTItem = iter->second;
                int userId = pTItem->userInfo.baseInfo.userId;
                uint8_t isFlee = (tusFlee == pTItem->ustate);
                (*pu) << userId << isFlee  << pTItem->winFan;
            }
			(*pu) << EndPluto;
			mbDbmgr->PushPluto(pu);
        }
    }
    else
    {
        LogError("CGameTable::StartReportScore", "!mbDbmgr");
    }
}

void CGameTable::StartConsumeSpecialGold()
{
    //是记分局才要扣除specialGold
    if (m_vipRoomType > vrtBean)
    {
        if (!m_isConsumeSpecialGold)
        {
            CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
            if (mbDbmgr)
            {
                CAreaTaskConsumeSpecialGold* task = new CAreaTaskConsumeSpecialGold(m_handle);
                GetWorldGameArea()->AddTask(task);

                LogInfo("CGameTable::StartConsumeSpecialGold", "handle = %d", m_handle);

                //为了延续task，即使未连接，也要创建task
                if (!mbDbmgr->IsConnected())
                {
                    LogWarning("CGameTable::StartConsumeSpecialGold", "!mbDbmgr->isConnected()");
                }
                else
                {
					uint32_t areaId = GetWorldGameArea()->GetServer()->GetMailboxId();
					int32_t gameRoomId = g_config_area->gameRoomId;

                    char openSeriesNum[100];
                    uint64_t stamp = GetTimeStampInt64Ms();
                    snprintf(openSeriesNum, sizeof(openSeriesNum), "%uA%dA%llu", areaId, m_handle, stamp);

                    int matchId = m_handle;
                    CPluto* pu = new CPluto;
                    (*pu).Encode(MSGID_DBMGR_CONSUME_SPECIAL_GOLD) << task->GetTaskId() << areaId << gameRoomId << matchId << openSeriesNum;
                    uint16_t len = m_sitUserList.size();
                    (*pu) << len;
                    int creatorRoundFee = 0;
                    int otherRoundFee = 0;
                    if (vrtScoreOnePay == m_vipRoomType)
                    {
                        creatorRoundFee = m_minSpecialGold;
                        otherRoundFee = 0;
                    }
                    else
                    {
                        creatorRoundFee = otherRoundFee = m_minSpecialGold;
                    }
                    for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
                    {
                        CTableUser* pTItem = iter->second;
                        int userId = pTItem->userInfo.baseInfo.userId;
                        if (userId == m_createUserId)
                        {
                            (*pu) << userId << creatorRoundFee << "私局局费";
                        }
                        else
                        {
                            (*pu) << userId << otherRoundFee << "私局局费";
                        }
                    }
                    (*pu) << EndPluto;
                    mbDbmgr->PushPluto(pu);
                }
            }
            else
            {
                LogError("CGameTable::StartConsumeSpecialGold", "!mbDbmgr");
            }
        }
    }
}

void CGameTable::SendUserStateNotify(int userId, int place, int tuserState, int64_t& bean)
{
    CPluto* pu = new CPluto();
    (*pu).Encode(MSGID_CLIENT_OTHER_STATE_NOTIFY) << userId << place << tuserState << bean << EndPluto;
    SendBroadTablePluto(pu, userId);
}

// 上报牌局的最后结果给后台
void CGameTable::StartReportTotalScore()
{
    CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
    if (mbDbmgr)
    {
        //创建任务
        CAreaTaskReportTotalScore* task = new CAreaTaskReportTotalScore(m_handle);
        GetWorldGameArea()->AddTask(task);

        LogInfo("CGameTable::StartReportTotalScore", "handle=%d", m_handle);

        // 为了延续task，即使未连接，也要创建task
        if (!mbDbmgr->IsConnected())
        {
            LogWarning("CGameTable::StartReportTotalScore", "!mbDbmgr->IsConnected()");
        }
        else
        {
            uint32_t areaId = GetWorldGameArea()->GetServer()->GetMailboxId();
            int32_t gameRoomId = g_config_area->gameRoomId;

            char openSeriesNum[100];
            uint64_t stamp = GetTimeStampInt64Ms();
            snprintf(openSeriesNum, sizeof(openSeriesNum), "%uA%dA%llu", areaId, m_handle, stamp);
            char endTimeStamp[100];
            snprintf(endTimeStamp, sizeof(endTimeStamp), "%llu", stamp);

            CPluto* pu = new CPluto;
            (*pu).Encode(MSGID_DBMGR_REPORT_TOTAL_SCORE) << task->GetTaskId() << areaId << gameRoomId << openSeriesNum
                << m_openSeriesNums << m_vipRoomType << m_tableNum << m_curRound << m_fstStartMsStamp << endTimeStamp;
            uint16_t len = m_sitUserList.size();
            (*pu) << len;
            for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
            {
                CTableUser* pTItem = iter->second;
                int userId = pTItem->userInfo.baseInfo.userId;
                (*pu) << userId << pTItem->userInfo.baseInfo.nickName << GetUserTotalScore(userId);
            }
            (*pu) << EndPluto;
            mbDbmgr->PushPluto(pu);
        }
    }
    else
    {
        LogError("CGameTable::StartReportTotalScore", "!mbDbmgr");
    }
}


void CGameTable::ReportTableStartState()
{
	int readyCount = 0;
	for (map<int, CTableUser*>::iterator iter = m_sitUserList.begin(); iter != m_sitUserList.end(); ++iter)
	{
		if (iter->second->isReady)
			++readyCount;
		else
			return;
	}
	if (readyCount < MIN_TABLE_USER_COUNT)
		return;

	// 只有第一局开始的时候需要上报
	if (m_curRound != 1)
		return;

	CMailBox* mbDbmgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
	if (mbDbmgr)
	{
		//创建任务
		CAreaTaskReportTableStart* task = new CAreaTaskReportTableStart(m_handle);
		GetWorldGameArea()->AddTask(task);

		LogInfo("CGameTable::ReportTableStartState", "handle=%d", m_handle);

		// 为了延续task，即使未连接，也要创建task
		if (!mbDbmgr->IsConnected())
		{
			LogWarning("CGameTable::ReportTableStartState", "!mbDbmgr->IsConnected()");
		}
		else
		{
			int32_t playTypeId = g_config_area->playTypeId;
			int32_t status = 1;
			CPluto* pu = new CPluto;
			(*pu).Encode(MSGID_DBMGR_REPORT_TABLE_START) << task->GetTaskId() << m_tableNum << GetCreateUserId()
				<< playTypeId << status << EndPluto;
			mbDbmgr->PushPluto(pu);
		}
	}
	else
	{
		LogError("CGameTable::ReportTableStartState", "!mbDbmgr");
	}
}
/*
结束行牌，计算结果，显示结果，积分上报
*/
void CGameTable::endXingPaiCalcResult()
{
	// 计算结果: 计算番数
    int sumScores = 0;
	for (size_t i = 0; i < m_userList.size(); i++)
	{
		CTableUser* pTUser = m_userList[i];
		for (auto itt = pTUser->huPaiInfo.begin(); itt != pTUser->huPaiInfo.end(); itt++)
		{
            (*itt).calcScores(m_tableRule.isHEBorDQ);
			TMJHuPaiInfoItem huPaiItem = (*itt);
            {
                // try 测试番种信息
                string tempstr;
                tempstr.clear();
                size_t len = huPaiItem.fanZhongList.size();
                vector<TMJFanZhongItem> fanZhongConfigList = g_logic_mgr->getFanZhongCfgList();
                for (size_t index = 0; index < len; ++index)
                {
                    if (index == 0)
                    {
                        tempstr += fanZhongConfigList[index].name + ":" + to_string(huPaiItem.fanZhongList[index]);
                        tempstr += "|";
                    }
                    else if (huPaiItem.fanZhongList[index] > 0)
                    {
                        tempstr += fanZhongConfigList[index].name + ":" + to_string(huPaiItem.fanZhongList[index]);
                        tempstr += "|";
                    }
                }
                LogInfo("玩家胡牌的番种信息", "palce %d : %s  fanshu = %d", i, tempstr.c_str(), huPaiItem.scores);
            }
            if (!((*itt).isWinner))
            {
                int scores = (*itt).scores;
                pTUser->winFan -= scores;
                (*itt).scores = scores;
                sumScores += scores;
                LogInfo("CGameTable::endXingPaiCalcResult", "place:%d score:%d", i, scores);//trytry
            }
		}
	}

    // 把赢牌玩家的分数算上`
    for (size_t i = 0; i < m_userList.size(); i++)
    {
        CTableUser* pTUser = m_userList[i];
        for (auto itt = pTUser->huPaiInfo.begin(); itt != pTUser->huPaiInfo.end(); itt++)
        {
            if ((*itt).isWinner)
            {
                (*itt).scores = sumScores;
                pTUser->winFan += sumScores;
            }
        }
    }

    LogInfo("分数结果", "-------------------------分数结果---------------------------");
    for (size_t i = 0; i < m_userList.size(); i++)
    {
        CTableUser* pTUser = m_userList[i];
        LogInfo("分数结果", "palce:%d  winFan:%d",i,pTUser->winFan);
    }

 	// 计算结果： 统计分数！！
 	// 注意： 内存虚拟积分(比如这个麻将的约局积分就是内存虚拟积分，不会落地到数据库，跟平台财富无关)
 	// 非 内存虚拟积分 不要把这段逻辑写到这个地方！！ 要写到上报积分回来后的回调里！ 因为要等数据库落地
    for (size_t i = 0; i < m_userList.size(); i++)
    {
        CTableUser* pTUser = m_userList[i];
        int incScore = pTUser->winFan * m_curBaseScore;
        AddUserTotalScore(pTUser->userInfo.baseInfo.userId, incScore);
    }

	// 积分上报
	//StartReportScore();
	m_tstate = tbsShowTheLastCard;
	m_decTimeCount = g_config_area->showLastCard_Sec;

	// 游戏结束时再扣房卡
	StartConsumeSpecialGold();
}

void CGameTable::SendRoundResult2User()
{
	// sendPacket 结果信息
	LogInfo("SendRoundResult2User", "begin"); 
	int baseScore = m_curBaseScore;

	CPluto* pu = new CPluto();
	(*pu).Encode(MSGID_CLIENT_G_RESULT_NOTIFY) << baseScore << m_curRound << m_mjDataMgr.FBaoPaiCardID;

	// 写入分数信息
	uint16_t len = MAX_TABLE_USER_COUNT;
	(*pu) << len;
	for (size_t i = 0; i < m_userList.size(); i++)
	{
		int incScore = m_userList[i]->winFan * m_curBaseScore;
		(*pu) << m_userList[i]->winFan << incScore << GetUserTotalScore(m_userList[i]->userInfo.baseInfo.userId);
	}
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		CTableUser* pTUser = FindUserByChairIndex(i);
		// 写入自己的相关番数信息
		len = pTUser->huPaiInfo.size();
		(*pu) << len;
		for (auto itt = pTUser->huPaiInfo.begin(); itt != pTUser->huPaiInfo.end(); itt++)
		{
			TMJHuPaiInfoItem huPaiItem = (*itt);
			(*pu) << int(huPaiItem.isWinner) << int(huPaiItem.isZiMo) << huPaiItem.dianPaoPlace << huPaiItem.scores << huPaiItem.lastCardId;
			uint16_t fanZhongLen = huPaiItem.fanZhongList.size();
			(*pu) << fanZhongLen;
			for (vector<int>::iterator fanZhongIter = huPaiItem.fanZhongList.begin(); fanZhongIter != huPaiItem.fanZhongList.end(); fanZhongIter++)
			{
				(*pu) << (*fanZhongIter);
			}
		}
	}
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++){
		WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(i), *pu);
		(*pu) << EndPluto;
	}
	/*WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(0), *pu);
	WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(1), *pu);
	WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(2), *pu);
	WriteCardsToPluto(m_mjDataMgr.FMJShouPai->getUserCardList(3), *pu);*/
	//(*pu) << EndPluto;

	SendBroadTablePluto(pu, -1);

	// 最后一局发送统计信息
	//if (m_curRound + 1 > m_maxRound)
	//{
	//	SendEndRound2User(0, 1);
	//}

	LogInfo("SendRoundResult2User", "end");
}

/*
	isForceLeave：是否是强制退出
	needShowEndRound：是否需要显示最后的牌局结果
*/
void CGameTable::SendEndRound2User(int isForceLeave, int needShowEndRound)
{
	CPluto* pu = new CPluto();
	int32_t createPlace = 0;
	for (int i = 0; i < MAX_TABLE_USER_COUNT; ++i)
	{
		CTableUser* pTableUser = m_userList[i];
		if (pTableUser->userInfo.baseInfo.userId == m_createUserId)
		{
			createPlace = i;
			break;
		}
	}
	(*pu).Encode(MSGID_CLIENT_G_END_ROUND) << isForceLeave << needShowEndRound << createPlace;
	(*pu) << uint16_t(MAX_TABLE_USER_COUNT);
	for (size_t i = 0; i < m_userList.size(); i++)
	{
		CTableUser* pTUser = m_userList[i];
		(*pu) <<  pTUser->countZiMoHu << pTUser->countDianPaoHu << pTUser->countDianPao 
			<< pTUser->countMingGang << pTUser->countAnGang << GetUserTotalScore(pTUser->userInfo.baseInfo.userId)
			<< pTUser->userInfo.baseInfo.userId;
	}
	SendBroadTablePluto(pu, -1);
	if (m_hasReportScore)
	{
		// 只有上报过单局成绩，才上报总分给后台
		StartReportTotalScore();
	}
}

/*
生成房间玩法信息字符串
*/
void CGameTable::GenerateOptionStr()
{
	m_optionStr.clear();
	char buffer[256];
	snprintf(buffer, sizeof(buffer), "{gameRoomId: %d, isChunJia: %d, isLaizi: %d, isGuaDaFeng: %d, isSanQiJia: %d, isDanDiaoJia: %d, isZhiDuiJia: %d,isZhanLiHu:%d,isMenQing:%d,isAnKe:%d,isKaiPaiZha:%d,isBaoZhongBao:%d,isHEBorDQ:%d,vipRoomType: %d}",
		g_config_area->gameRoomId, m_tableRule.isChunJia, m_tableRule.isLaizi, m_tableRule.isGuaDaFeng, m_tableRule.isSanQiJia, m_tableRule.isDanDiaoJia, m_tableRule.isZhiDuiJia, m_tableRule.isZhanLiHu, m_tableRule.isMenQingJiaFen, m_tableRule.isAnKeJiaFen, m_tableRule.isKaiPaiZha, m_tableRule.isBaoZhongBao, m_tableRule.isHEBorDQ,m_vipRoomType);
	m_optionStr = buffer;
}


CGameTableMgr::CGameTableMgr() : m_tablelist(), m_activeTableCount(0), m_sitAllUserList()
{
    m_tablelist.reserve(MAX_TABLE_HANDLE_COUNT);
    for(int i = 0; i < MAX_TABLE_HANDLE_COUNT; i++)
    {
        m_tablelist.push_back(new CGameTable(i));
    }
	for (int i = 0; i < MAX_USE_TABLE_COUNT; i++)
	{
		m_randomTableHandle[i] = i + 111;
	}
	for (int i = 0; i < MAX_USE_TABLE_COUNT; i++)
	{
		int tmp = rand() % MAX_USE_TABLE_COUNT;
		if (tmp != i)
		{
			int handle = m_randomTableHandle[i];
			m_randomTableHandle[i] = m_randomTableHandle[tmp];
			m_randomTableHandle[tmp] = handle;
		}
	}
	m_createIdx = 0;
}

CGameTableMgr::~CGameTableMgr()
{
    ClearContainer(m_tablelist);
}

void CGameTableMgr::RunTime()
{
    m_activeTableCount = 0;
    for(vector<CGameTable*>::iterator iter = m_tablelist.begin(); iter != m_tablelist.end(); ++iter)
    {
        if ((*iter)->CheckRunTime())
            m_activeTableCount++;
    }
}

void CGameTableMgr::OnUserOffline(int userId)
{
    int chairIndex = 0;
    CGameTable* pTable = GetUserTable(userId, chairIndex);
    if(!pTable)
        return;

    pTable->LeaveTable(userId);
}

bool CGameTableMgr::FindSitUser(int userId, int& retTableHandle, int&retChairIndex)
{
    map<int, uint32_t>::iterator iter = m_sitAllUserList.find(userId);
    if (m_sitAllUserList.end() == iter)
        return false;

    uint32_t value = iter->second;
    retTableHandle = value & 0xFFFF;
    retChairIndex = (value >> 16) & 0xFFFF;

    return true;
}

bool CGameTableMgr::AddSitUser(int userId, int tableHandle, int chairIndex)
{
    map<int, uint32_t>::iterator iter = m_sitAllUserList.find(userId);
    if (m_sitAllUserList.end() != iter)
    {
        LogError("CGameTableMgr::AddSitUser", "user exists");
        return false;
    }

    uint32_t value = (tableHandle & 0xFFFF) | (chairIndex << 16);
    m_sitAllUserList.insert(make_pair(userId, value));

    return true;
}

bool CGameTableMgr::RemoveSitUser(int userId)
{
    map<int, uint32_t>::iterator iter = m_sitAllUserList.find(userId);
    if (m_sitAllUserList.end() == iter)
    {
        LogError("CGameTableMgr::RemoveSitUser", "user not exists");
        return false;
    }

    // map erase iter 效率最高
    m_sitAllUserList.erase(iter);
    return true;
}
// 注意：clientFd只有在flag为1时才有效，用于返回给客户端创建桌子是否成功的信息
void CGameTableMgr::ReportToTableManager(CGameTable* pTable, int flag, int clientFd)
{
	if (flag != ftmClearAll && nullptr == pTable)
	{
		LogError("CGameTableMgr::ReportToTableManager", "pTable is nullptr");
		return;
	}

	int tableHandle;
	if (ftmClearAll != flag)
		tableHandle = pTable->GetHandle();
	else
		tableHandle = 0;

	CMailBox* mbDbMgr = GetWorld()->GetServerMailbox(SERVER_DBMGR);
	if (mbDbMgr)
	{
		CAreaTaskReportTableManager* task = new CAreaTaskReportTableManager(tableHandle, flag, clientFd);
		GetWorldGameArea()->AddTask(task);
		// 为了延续task，即使未连接，也要创建task
		if (!mbDbMgr->IsConnected())
		{
			LogWarning("CGameTableMgr::ReportToTableManager", "!mbDbMgr->IsConnected()");
		}
		else
		{
			int playTypeId = g_config_area->playTypeId;
			int gameRoomId = g_config_area->gameRoomId;
			int gameServerId = GetWorldGameArea()->GetServer()->GetMailboxId();
			int userId(0);
			string tableNum("");
			int maxRound(0);
			int minSpecialGold(0);
			int vipRoomType(vrtScoreOnePay);
			string optionStr;
			if (ftmClearAll != flag)
			{
				userId = pTable->GetCreateUserId();
				tableNum = pTable->GetTableNum();
				maxRound = pTable->GetMaxRound();
				minSpecialGold = pTable->GetMinSpecialGold();
				vipRoomType = pTable->GetVipRoomType();
				optionStr = pTable->GetOptionStr();
			}

			CPluto* pu = new CPluto;
			(*pu).Encode(MSGID_DBMGR_REPORT_TABlE_MANAGER) << task->GetTaskId() << flag << playTypeId
				<< gameRoomId << gameServerId << userId << tableNum << maxRound << minSpecialGold
				<< vipRoomType << optionStr
				<< EndPluto;

			mbDbMgr->PushPluto(pu);
		}
	}
	else
	{
		LogError("CGameTableMgr::ReportToTableManager", "!mbDbMgr");
	}
}


//bool CGameTableMgr::RemoveUserCreateTable(int userId)
//{
//    map<int, int>::iterator iter = m_userId2CreateTable.find(userId);
//    if (m_userId2CreateTable.end() == iter)
//    {
//        return false;
//    }
//
//    m_userId2CreateTable.erase(iter);
//
//    LogInfo("CGameTableMgr::RemoveUserCreateTable", "userId=%d", userId);
//
//    return true;
//}

//CGameTable* CGameTableMgr::GetUserCreateTable(int userId)
//{
//    map<int, int>::iterator iter = m_userId2CreateTable.find(userId);
//    if (m_userId2CreateTable.end() == iter)
//        return NULL;
//    else
//        return m_tablelist[iter->second];
//}

CGameTable* CGameTableMgr::GetUserTable(int userId, int& chairIndex)
{
    int tableHandle = 0;
    if(FindSitUser(userId, tableHandle, chairIndex))
        return m_tablelist[tableHandle];
    else
        return NULL;
}

CGameTable* CGameTableMgr::GetPUserTable(SUserInfo* pUser, int& chairIndex)
{
    int tableHandle = pUser->activeInfo.tableHandle;
    chairIndex = pUser->activeInfo.chairIndex;

    if(tableHandle >= 0)
        return m_tablelist[tableHandle];
    else
        return NULL;
}

CGameTable* CGameTableMgr::CreateTable(SUserInfo* pUser, TTableRuleInfo aTableRule, int selScore, int maxRound, int vipRoomType, int& retCode, string& errMsg)
{
	LogInfo("开局", "baseSocer: %d", selScore); // try

    retCode = ERROR_CODE_CREATE_TABLE_FAILED;
    errMsg = "服务器爆满";

    int minSpecialGold = 0;
    if (vipRoomType > vrtBean)
    {
        if (g_config_area->specialGold3 > 0)
        {
            // 越界判断
            int maxValue = INT_MAX / g_config_area->specialGold3;
            if (maxRound > maxValue)
                maxRound = maxValue;
        }

		// todo: 临时性方案，以后要从后天拉数据
		for (auto it = g_config_area->specialGoldCfg.begin(); it != g_config_area->specialGoldCfg.end(); ++it)
		{
			int maxRoundLine = it->first;
			if (maxRound <= maxRoundLine)
			{
				// 找到第一个成功的就退出循环，否则，会导致消费房卡错误
				minSpecialGold = it->second;
				break;
			}
		}
		if (minSpecialGold <= 0)
		{
			minSpecialGold = 1;
			LogError("CGameTableMgr::CreateTable", "minSpecialGold <= 0, maxRound = %d", maxRound);
		}

        if (vrtScoreAllPay == vipRoomType)
        {
            minSpecialGold /= MAX_TABLE_USER_COUNT;
        }
    }
    
    int userId = pUser->baseInfo.userId;
	CGameTable* pTable = nullptr;
   /* CGameTable* pTable = GetUserCreateTable(userId);
    if (pTable)
    {
        if (pTable->GetCurUserCount() > 0)
        {
            char buffer[100];
            snprintf(buffer, sizeof(buffer), "您已经创建了牌局【%s】", pTable->GetTableNum().c_str());
            errMsg = buffer;

            return NULL;
        }
    }*/

    // 复用桌子也要收费，等于重新创建了。
    if (minSpecialGold > 0 && pUser->baseInfo.specialGold < minSpecialGold)
    {
        retCode = ERROR_CODE_SPECIALGOLD_TOO_LITTLE;

        char buffer[100];
        snprintf(buffer, sizeof(buffer), "您的游戏%s小于%d，不能满足要求", g_config_area->specialGold_name.c_str(), minSpecialGold);
        errMsg = buffer;

        return NULL;
    }

    if (!pTable)
    {

		for (int i = 0; i < MAX_USE_TABLE_COUNT; ++i)
        {
			int handle = m_randomTableHandle[(m_createIdx + i) % MAX_USE_TABLE_COUNT];
			CGameTable* pItem = m_tablelist[handle];
            if (!pItem->GetIsActive() && pItem->GetDisBandInterval() > g_config_area->min_interval_reuse_table)
            {
				LogInfo("CGameTableMgr::CreateTable", "m_createIdx = %d, index = %d, handle = %d", m_createIdx, (m_createIdx + i) % MAX_USE_TABLE_COUNT, handle);
                pTable = pItem;
				m_createIdx = (m_createIdx + 1) % MAX_USE_TABLE_COUNT;
                break;
            }
        }
    }
    

    if (!pTable)
        return NULL;

    pTable->SetNotActive();
    pTable->SetCreateUserId(userId);
    pTable->SetTableRule(aTableRule);
	if (selScore < 1)
	{
		selScore = 1;
	}
    pTable->SetCurBaseScore(selScore);
    pTable->SetMinBean(0);  // 没有进入条件
	if (maxRound < 1)
	{
		maxRound = 1;
	}
    pTable->SetMaxRound(maxRound);
    string tableNum = GetTableNumByHandle(g_config_area->area_num, pTable->GetHandle());
    pTable->SetTableNum(tableNum);
	/*  if (m_userId2CreateTable.find(userId) == m_userId2CreateTable.end())
		  m_userId2CreateTable.insert(make_pair(userId, pTable->GetHandle()));
		  else
		  LogError("CGameTableMgr::CreateTable", "user=%d insert failed", userId);*/
    pTable->SetVipRoomType(vipRoomType);
    pTable->SetMinSpecialGold(minSpecialGold);
	pTable->GenerateOptionStr();

    LogInfo("CGameTableMgr::CreateTable", "userId=%d tabelNum=%s", userId, tableNum.c_str());
    retCode = 0;
    return pTable;
}


CTableUser::CTableUser()
{
    Clear();
}

CTableUser::~CTableUser()
{

}

void CTableUser::Clear()
{
	RoundStopClearData();

    ustate = tusNone;
	manualTrust = false;
	isReady = false;
    readyOrLeaveTick = GetNowMsTick();
    userInfo.Clear();
    player.Clear();
	agreeEnd = 0;
	lastQuestDisbandTick = 0;
	lastLeaveTimeTick = 0;

	countZiMoHu = 0;
	countMingGang = 0;
	countDianPaoHu = 0;
	countDianPao = 0;
	countAnGang = 0;
}

void CTableUser::RoundStopClearData()
{
	isReady = false;
	isTrust = false;
	discardCount = 0;
	lastDiscardTick = 0;
	userInfo.activeInfo.enterTableTick = GetNowMsTick();
	player.RoundClear();

	hasHu = false;
	hasTing = false;
	isHuaZhu = false;
	willHuCardID.clear();
	hasHuCardID.clear();
	selSwapCards.clear();
	getSwapCards.clear();
	selDelSuit = mjcsError;
	isSwaped = false;
	huPaiInfo.clear();
	winFan = 0;
	piaoType = -1;

	maxCardId = 0;
	maxFanZhongInfo.clear();

	tingPaiInfoArr.clear();

	haveHuPass = false;
	moCount4SpecialGang = 0;
	hasKaiMen = false;
}

int CTableUser::getPiaoType()
{
	if (piaoType <= 0)
	{
		return 0;
	}
	else
		return piaoType;
}