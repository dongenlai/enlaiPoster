#include "mjActionMgr.h"
#include "table_mgr.h"
#include "global_var.h"
#include "mjDataMgr.h"
#include<algorithm>


CMJActionMgr::CMJActionMgr()
{
	FParentTable = nullptr;
	FMJDataMgr = nullptr;
}

CMJActionMgr::~CMJActionMgr()
{
}

void CMJActionMgr::init(CGameTable* aParentTable, CMJDataMgr* mjDataMgr)
{
	FParentTable = aParentTable;
	FMJDataMgr = mjDataMgr;
}

void CMJActionMgr::initData()
{
	clearActionList();
	FDecTimeCount = -1;
	FLastActionName = mjaError;
	FCurrProcAciton = mjaError;
	FTimerState = tsError;
	FBIsGangBu = false; 
}

void CMJActionMgr::doActionStateRunTime()
{
	switch (FCurrActionState)
	{
	case asWaitChuPai:
		DoActionStateWaitChu();
		break;
	case asChuPaiing:
		DoActionStateAnimation();
		break;
	case asWaitDongZuo:
		DoActionStateWaitDongZuo();
		break;
	case asDongZuoing:
		DoActionStateAnimation();
		break;
	default:
		break;
	}
}

void CMJActionMgr::DoActionStateAnimation()
{
	FDecTimeCount--;
	if (FDecTimeCount <= 0)
	{
        // 先检测是否有自动胡牌
        bool hasAutoHu = false;
        for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
        {
            if ((*it).MJAName == mjaHu)
            {
                CTableUser* pTUser = FParentTable->FindUserByChairIndex((*it).Place);
                // 当玩家听牌时自动胡
                if (pTUser->hasTing)
                {
                    hasAutoHu = true;
                    // 一次只做一个胡牌动作， 否则会出错！！
                    procAction(it);
                    break;
                }
            }
        }
        if (hasAutoHu)
            return;

		if ((FLastActionName == mjaMo) || (FLastActionName == mjaBuHua))
		{
            CTableUser* pTUser = FParentTable->FindUserByChairIndex(FMJDataMgr->FCurrPlace);
            if (pTUser->hasTing && isOnlyDongZuo(mjaChu))
            {
                procAction(mjaChu);
            }
            else
            {
                // 等待玩家出牌
                FCurrActionState = asWaitChuPai;
				FDecTimeCount = C_TIMER_COUNT_ONE_SECOND * g_config_area->discard_sec;
            }
		}
        else if ((FLastActionName == mjaChu) || (FLastActionName == mjaTing) || (FLastActionName == mjaTingChi) || (FLastActionName == mjaTingPeng))
		{
			// 出牌后若只有摸牌动作则直接摸牌，否则等待动作
			if (isOnlyDongZuo(mjaMo))
			{
				procAction(mjaMo);
			}
			else
			{
				FCurrActionState = asWaitDongZuo;
				FDecTimeCount = C_TIMER_COUNT_ONE_SECOND * g_config_area->waitDongZuo_sec;
			}
		}
        else if ((FLastActionName == mjaChi) || (FLastActionName == mjaPeng))
		{
			// 等待玩家出牌
			FCurrActionState = asWaitChuPai;
			FDecTimeCount = C_TIMER_COUNT_ONE_SECOND * g_config_area->discard_sec;
		}
		else if ((FLastActionName == mjaDaMingGang) || (FLastActionName == mjaAnGang))
		{
			// 大明杠和暗杠牌后的下一个动作肯定是 补张摸牌
			procAction(mjaMo);
		}
		else if (FLastActionName == mjaJiaGang)
		{
			// 加杠的下一个动作视是否有人抢杠胡而定，若有胡牌动作则等待动作，若无则直接补张
			if (hasHuPaiAciton())
			{
				FCurrActionState = asWaitDongZuo;
				FDecTimeCount = C_TIMER_COUNT_ONE_SECOND * g_config_area->waitDongZuo_sec;
			}
			else
			{
				procAction(mjaMo);
			}
		}
		else if (FLastActionName == mjaHu)
		{
			// 胡牌以后可能还有胡牌动作(一炮多响)， 如果没有，则肯定直接摸牌
			if (isOnlyDongZuo(mjaMo))
				procAction(mjaMo);
			else
				FCurrActionState = asWaitDongZuo;
		}
		else
		{
			LogWarning("CMJActionMgr::DoActionStateAnimation", "没有动作 %d", FLastActionName);
		}
	}
}

void CMJActionMgr::DoActionStateWaitDongZuo()
{
	// 检查出牌后的动作  -- 胡、明杠、碰、吃、摸牌。
	// 到时间,处理具有相对最高优先级的动作
	//return; 
	trustProcAciton(FMJDataMgr->FCurrPlace);
	//test
	//trustProcAciton(-1);
	FDecTimeCount--;
	if (FDecTimeCount == -1)
	{
		procHighPRIValidAction();
	}
}

void CMJActionMgr::DoActionStateWaitChu()
{
	//return;
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(FMJDataMgr->FCurrPlace);
	if (pTUser->isTrust || (pTUser->ustate > tusNomal))
	{
		trustProcAciton(FMJDataMgr->FCurrPlace);
		trustChuPai();
	} 
	else
	{
		FDecTimeCount--;
		if (FDecTimeCount <= 0)
		{
			if (!pTUser->isTrust)
			{
				FParentTable->DoUserTrust(pTUser, true, -1);
			}
			trustProcAciton(FMJDataMgr->FCurrPlace);
			trustChuPai();
		}
	}
}

bool CMJActionMgr::hasAciton(int place, TMJActionName mjAction)
{
	if (mjAction != mjaPass)
	{
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
		{
			if (((*it).Place == place) && ((*it).MJAName == mjAction))
			{
				return true;
			}
		}
	}
	else
	{
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
		{
			if (((*it).Place == place) && (((*it).MJAName == mjaChi) || ((*it).MJAName == mjaPeng) ||
				((*it).MJAName == mjaDaMingGang) || ((*it).MJAName == mjaJiaGang) || ((*it).MJAName == mjaAnGang) ||
                ((*it).MJAName == mjaTing) || ((*it).MJAName == mjaHu) || ((*it).MJAName == mjaTingPeng) || ((*it).MJAName == mjaTingChi)))
			{
				return true;
			}
		}

	}
		
	
	return false;
}

bool CMJActionMgr::hasAcitonExact(int place, TMJActionName mjAction, const string& expandStr)
{
	int gangFlag = -1;
	string tmpStr = expandStr;
	vector<int> wuDaSunVec;

	if (mjAction == mjaPass)
	{
		return hasAciton(place, mjAction);
	}
	else
	{
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
		{
			// 出牌不要求严格一致
			if (((*it).Place == place) &&
				((*it).MJAName == mjAction) &&
				(!(*it).HasPass) &&
				((expandStr.compare((*it).ExpandStr) == 0) || (mjAction == mjaChu)))
			{
				return true;
			}
		}
	}

	return false;
}

bool CMJActionMgr::hasHuPaiAciton()
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if (((*it).MJAName == mjaHu) && (!(*it).HasPass))
		{
			return true;
		}
	}
	return false;
}

bool CMJActionMgr::hasChuPai()
{
    return (FLastActionName == mjaChu) || (FLastActionName == mjaTing) || (FLastActionName == mjaTingChi) || (FLastActionName == mjaTingPeng);
}

bool CMJActionMgr::isOnlyDongZuo(TMJActionName mjAction)
{
	return (FCurrActionList.size() == 1) && (FCurrActionList[0].MJAName == mjAction);
}

bool CMJActionMgr::isAutoChu()
{
	return FParentTable->isCurrUserHasHu() && isOnlyDongZuo(mjaChu);
}

bool CMJActionMgr::isAutoHu()
{
	return FParentTable->isCurrUserHasHu() && hasAciton(FMJDataMgr->FCurrPlace, mjaHu);
}

bool CMJActionMgr::procAction(TMJActionName mjAction)
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((*it).MJAName == mjAction)
		{
			return procAction(it);
		}
	}
	return false;
}

bool CMJActionMgr::procAction(int place, TMJActionName mjAction)
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if (((*it).Place == place) && ((*it).MJAName == mjAction))
		{
			return procAction(it);
		}
	}
	return false;
}

TMJActionName CMJActionMgr::getAutoGangAction(bool isMoPai)
{
	int place = FMJDataMgr->FCurrPlace;
	TMJActionName result = mjaError;
	while (place != FMJDataMgr->FLastChuPaiPlace)
	{
		if (FParentTable->isHuUser(place))
		{
			if (isMoPai)
			{
				if (hasAciton(place, mjaJiaGang))
					result = mjaJiaGang;
				else if (hasAciton(place, mjaAnGang))
					result = mjaAnGang;
			}
			if (result != mjaError)
				break;
		}

		if (isMoPai)
			break;
		place = (place + 1) % MAX_TABLE_USER_COUNT;
	}
	return result;
}

void CMJActionMgr::endXingPai()
{
	FCurrActionList.clear();
	FCurrTingPaiActionList.clear();
}

bool CMJActionMgr::procAction(vector<TPlayerMJAction>::iterator itProc)
{
	bool result = false;
	TMJActionName mjAction = (*itProc).MJAName;
	int place = (*itProc).Place;

	if ((FBIsGangBu && (mjAction == mjaChu)) ||   // 杠后补张后出牌
		(FIsGangPao && (mjAction == mjaHu)))      // 杠炮后胡牌动作
		FIsGangPao = true;
	else
		FIsGangPao = false;

	if (FBIsGangBu && (mjAction == mjaHu))
		FIsGangShangKaiHua = true;
	else
		FIsGangShangKaiHua = false;

	if ((mjAction == mjaMo) && ((FLastActionName == mjaDaMingGang) ||
		(FLastActionName == mjaJiaGang) || (FLastActionName == mjaAnGang)))
		FBIsGangBu = true;
	else
		FBIsGangBu = false;

	FCurrProcAciton = mjAction;
	switch (mjAction)
	{
	case mjaError:
		break;
	case mjaPass:
		break;
	case mjaMo:
		result = FMJDataMgr->procMoPai(place);
		break;
	case mjaChi:
	{
		vector<string> tmpVec;
		SplitStringToVector((*itProc).ExpandStr, ',', tmpVec);
		if (tmpVec.size() != 2)
		{
			result = false;
		}
		else
			result = FMJDataMgr->procChiPai(place, stoi(tmpVec[0]), stoi(tmpVec[1]));
		break;
	}
	case mjaPeng:
		result = FMJDataMgr->procPengPai(place, stoi((*itProc).ExpandStr));
		break;
    case mjaTingChi:
    {
        result = FMJDataMgr->procTingChiPai(place, ((*itProc).ExpandStr));
        break;
    }
    case mjaTingPeng:
        result = FMJDataMgr->procTingPengPai(place, (*itProc).ExpandStr);
        break;
	case mjaDaMingGang:
		result = FMJDataMgr->procDaMingGang(place, stoi((*itProc).ExpandStr));
		break;
	case mjaChu:
		result = FMJDataMgr->procChuPai(place, stoi((*itProc).ExpandStr));
		break;
	case mjaAnGang:
		result = FMJDataMgr->procAnGang(place, stoi((*itProc).ExpandStr));
		break;
	case mjaJiaGang:
		result = FMJDataMgr->procJiaGang(place, stoi((*itProc).ExpandStr));
		break;
	case mjaBuHua:
		break;
	case mjaTing:
        {
            size_t x = (*itProc).ExpandStr.find(":");
            if (x != string::npos)
            {
                string tmpStr = (*itProc).ExpandStr.substr(0, x);
                result = FMJDataMgr->procTingPai(place, stoi(tmpStr));
            }
            else
            {
                result = false;
            }
            break;
        }
	case mjaHu:
		result = FMJDataMgr->procHuPai(place, stoi((*itProc).ExpandStr));
		break;
	default:
		break;
	}

	// 不等待一炮多响
	if (!((mjAction == mjaHu) && (hasHuPaiAciton())))
	{
		if (mjAction == mjaChu)
			FCurrActionState = asChuPaiing;
		else
			FCurrActionState = asDongZuoing;
		FLastActionName = mjAction;
		calcDecTimeCount4Animi();
	}

	if (!result)
	{
		LogWarning("CMJActionMgr::procAction", "action: %d, place: %d", mjAction, place);
	}
	return result;
}

void CMJActionMgr::calcDecTimeCount4Animi()
{
	// todo: 各个动作的等待时间
	FDecTimeCount = C_TIMER_COUNT_ONE_SECOND/2;
	// 先检测是否有自动胡牌(胡牌后再次胡牌，不需要等待玩家选择)
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		CTableUser* pTUser = FParentTable->FindUserByChairIndex((*it).Place);
		if (pTUser->hasHu)
		{
			if ((*it).MJAName == mjaHu)
				FDecTimeCount = 2;
			else if ((*it).MJAName == mjaChu)
				FDecTimeCount = 1;
		}
	}
}

void CMJActionMgr::trustProcAciton(int place)
{
	vector<int> hasProcPlaceVector;
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((place != -1) && ((*it).Place != place))
			continue;
		int currPlace = (*it).Place;
		CTableUser* pTUser = FParentTable->FindUserByChairIndex(currPlace);
		// 托管或者掉线
		if (pTUser->isTrust || (pTUser->ustate > tusNomal))
		{
			TMJActionName mjAction = (*it).MJAName;

			if ((mjAction != mjaError) && (mjAction != mjaPass) && (mjAction != mjaMo) &&
				(mjAction != mjaBuHua) && (mjAction != mjaChu))
			{
				// 申请过的不再申请
				if (find(hasProcPlaceVector.begin(), hasProcPlaceVector.end(), (*it).Place) == 
					hasProcPlaceVector.end())
				{
					if ((mjAction == mjaHu))
					{
						hasProcPlaceVector.push_back((*it).Place);
						if (applyAction((*it).Place, mjAction, (*it).ExpandStr))
							break;
					}
					else
					{
						//try rebot
						if (mjAction == mjaChi){
							applyAction((*it).Place, mjaChi, (*it).ExpandStr);
							break;
						}
						else if (mjAction == mjaPeng){
							applyAction((*it).Place, mjaPeng, (*it).ExpandStr);
							break;
						}
						else if (mjAction == mjaDaMingGang){
							applyAction((*it).Place, mjaDaMingGang, (*it).ExpandStr);
							break;
						}
						else if (mjAction == mjaTing){
							applyAction((*it).Place, mjaTing, (*it).ExpandStr);
							break;
						}
						else if (mjAction == mjaTingChi){
							applyAction((*it).Place, mjaTingChi, (*it).ExpandStr);
							break;
						}
						else if (mjAction == mjaTingPeng){
							applyAction((*it).Place, mjaTingPeng, (*it).ExpandStr);
							break;
						}
						else{
							applyAction((*it).Place, mjaPass, "");
							break;
						}

					/*	if (applyAction((*it).Place, mjaPass, ""))
							break;*/
					}
				}
			}
		}
	}
}

void CMJActionMgr::trustChuPai()
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((*it).MJAName == mjaChu)
		{
			procAction(it);
			break;
		}
	}
}

/*
返回值表示，是否执行了action
*/

bool CMJActionMgr::applyAction(int place, TMJActionName mjAction, const string expandStr)
{
	if (!FParentTable->IsChairIndexValid(place))
		return false;
	if (mjAction == mjaError)
		return false;
	// todo: 处理听牌的字符串

	bool result = false;
	bool isPass = mjAction == mjaPass;
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		TMJActionName currMJAction = (*it).MJAName;
		if ((*it).Place == place)
		{
			if ((*it).HasPass)
				continue;

			if (isPass)
			{
				if ((currMJAction != mjaMo) && (currMJAction != mjaChu))
				{
					if (currMJAction == mjaHu)
					{
						CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
						pTUser->haveHuPass = true;
					}
					(*it).HasPass = true;
					(*it).HasApply = false;
				}
			}
			else
			{
				if ((currMJAction == mjAction) && 
					((expandStr == (*it).ExpandStr) || (mjAction == mjaChu)))
				{
					(*it).HasApply = true;
					// todo 处理听牌选项
					(*it).ExpandStr = expandStr;
				}
				else
				{
					if ((currMJAction != mjaMo) && (currMJAction != mjaChu))
					{
						(*it).HasPass = true;
						(*it).HasApply = false;
					}
				}
			}
		}
	}

	if (isPass)
	{
		// 打印pass信息，方便调试
		FMJDataMgr->debugActionMsg(place, mjaPass, 0);
	}

	{
		// 检查没有过的最高级别动作是否可以处理(已经申请执行)
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
		{
			if ((*it).HasPass)
				continue;
			if ((*it).HasApply)
			{
				result = procAction(it);
				break;
			}
            break;
		}
	}

	return result;
}

void CMJActionMgr::procHighPRIValidAction()
{
	// 强制处理具有相对最高优先级的动作(玩家已经申请并且没有过的动作)
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((*it).HasApply && !(*it).HasPass)
		{
			procAction(it);
			break;
		}
	}
}

void CMJActionMgr::clearActionList()
{
	FCurrActionList.clear();
	FCurrTingPaiActionList.clear();
}

void CMJActionMgr::addAction(int place, TMJActionName mjAction, bool hasApply, bool hasPass, const string expandStr)
{
	// 为什么删除摸牌，因为一炮多响的时候，不会 updateAction刷新，会强制添加摸牌动作，导致动作列表中可能有多个摸牌，数据出错。
	if (mjAction == mjaMo)
	{
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end();)
		{
			if ((*it).MJAName == mjaMo)
			{
				it = FCurrActionList.erase(it);
			}
			else
				it++;
		}
	}

	{
		FCurrActionList.push_back(TPlayerMJAction(mjAction, place, hasPass, hasApply, expandStr));
	}
	//LogInfo("CMJActionMgr::addAction", "%d: %s, %s", place, CAPTION_MJAction[int(mjAction)].c_str(), expandStr.c_str());
}

/*
	一炮多响时， 不是 updateAction 而是删除申请的胡牌。
*/
void CMJActionMgr::delHuPaiAction(int place)
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if (((*it).Place == place) && ((*it).MJAName == mjaHu))
		{
			FCurrActionList.erase(it);
			break;
		}
	}
}

void CMJActionMgr::delAllActionExceptHuPaiAction()
{
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end();)
	{
		if (((*it).MJAName != mjaHu))
		{
			it = FCurrActionList.erase(it);
		}
		else
			it++;
	}
}

bool myCompare(const TPlayerMJAction fir, const TPlayerMJAction sec)
{
	return PRI_MJAction[fir.MJAName] > PRI_MJAction[sec.MJAName];
}

void CMJActionMgr::sortALLAction()
{
	sort(FCurrActionList.begin(), FCurrActionList.end(), myCompare);
}

void CMJActionMgr::updateTimerState()
{
	// 设置客户端的时间显示状态，逻辑上要与服务端的逻辑状态设置函数 -- DoActionStateAnimation 一致！！！
	// 客户端无非就是等待出牌、等待动作、等待网络事件。所谓的等待网络事件是指由服务端
	// 决定下一步动作执行的过程,此时客户端不做任何处理。
	// 先检测是否有自动胡牌(胡牌后再次胡牌，不需要等待玩家选择)
	bool hasAutoHu = false;
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((*it).MJAName == mjaHu)
		{
			CTableUser* pTUser = FParentTable->FindUserByChairIndex((*it).Place);
			if (pTUser->hasHu)
			{
				hasAutoHu = true;
				break;
			}
		}
	}
	if (hasAutoHu){
		FTimerState = tsWaitNetEvent;
		return;
	}

	if ((FCurrProcAciton == mjaMo) || (FCurrProcAciton == mjaBuHua))
	{
		int currPlace = FMJDataMgr->FCurrPlace;
		if (FParentTable->isCurrUserHasHu())
		{
			if (hasAciton(currPlace, mjaHu) || hasAciton(currPlace, mjaJiaGang) ||
				hasAciton(currPlace, mjaAnGang) || isOnlyDongZuo(mjaChu))
				FTimerState = tsWaitNetEvent;
			else{
				LogWarning("updateTimerState", "error self aciton: %d", currPlace);
			}
		}
		else
			FTimerState = tsWaitChuPai;
	}
    else if ((FCurrProcAciton == mjaChu) || (FCurrProcAciton == mjaTing) || (FCurrProcAciton == mjaTingChi) || (FCurrProcAciton == mjaTingPeng))
	{
		// 出牌后若只有摸牌动作则直接摸牌，否则等待动作
		if (isOnlyDongZuo(mjaMo))
			FTimerState = tsWaitNetEvent;
		else
			FTimerState = tsWaitDongZuo;
	}
    else if ((FCurrProcAciton == mjaChi) || (FCurrProcAciton == mjaPeng))
	{
		// 等待玩家出牌
		FTimerState = tsWaitChuPai;
	}
	else if ((FCurrProcAciton == mjaDaMingGang) || (FCurrProcAciton == mjaAnGang))
	{
		// 大明杠和暗杠牌后的下一个动作肯定是 补张摸牌
		FTimerState = tsWaitNetEvent;
	}
	else if (FCurrProcAciton == mjaJiaGang)
	{
		// 加杠的下一个动作视是否有人抢杠胡而定，若有胡牌动作则等待动作，若无则直接补张
		if (hasHuPaiAciton())
			FTimerState = tsWaitDongZuo;
		else
			FTimerState = tsWaitNetEvent;
	}
	else if (FCurrProcAciton == mjaHu)
	{
		// 胡牌以后可能还有胡牌动作(一炮多响)， 如果没有，则肯定直接摸牌
		if (isOnlyDongZuo(mjaMo))
			FTimerState = tsWaitNetEvent;
		else
			FTimerState = tsWaitDongZuo;
	}
	else
	{
		LogWarning("CMJActionMgr::updateTimerState", "没有动作 %d", FCurrProcAciton);
	}
}

void CMJActionMgr::beginXingPai()
{
	FCurrActionState = asWaitChuPai;
	FTimerState = tsWaitChuPai;
	FDecTimeCount = C_TIMER_COUNT_ONE_SECOND * g_config_area->discard_sec;
	FLastActionName = mjaError;
	FCurrProcAciton = mjaError;
	FBIsGangBu = false;

	FMJDataMgr->beginXingPai();
}

void CMJActionMgr::writeUserAction2Pluto(int place, CPluto* pu)
{
	uint16_t len = 0;
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if ((*it).Place == place)
			len++;
	}
	for (auto it = FCurrTingPaiActionList.begin(); it != FCurrTingPaiActionList.end(); it++)
	{
		if ((*it).Place == place)
			len++;
	}

	(*pu) << len;
	if (len > 0)
	{
		for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
		{
			if ((*it).Place == place)
				(*pu) << int((*it).MJAName) << (*it).ExpandStr;
		}
		for (auto it = FCurrTingPaiActionList.begin(); it != FCurrTingPaiActionList.end(); it++)
		{
			if ((*it).Place == place)
				(*pu) << int((*it).MJAName) << (*it).ExpandStr;
		}
	}
}

void CMJActionMgr::debugStr(stringstream& aStream)
{
	aStream << "ActionList: ";
	for (auto it = FCurrActionList.begin(); it != FCurrActionList.end(); it++)
	{
		if (it != FCurrActionList.begin())
			aStream << ", ";
		TPlayerMJAction actionItem = (*it);
		int tmpI = int((*it).MJAName);
		aStream << "{" << "place: " << actionItem.Place << ", action: " << CAPTION_MJAction[tmpI] <<
			", str: " << (*it).ExpandStr << ", hasApply: " << (*it).HasApply <<
			", hasPass: " << (*it).HasPass << "}";
	}
	for (auto it = FCurrTingPaiActionList.begin(); it != FCurrTingPaiActionList.end(); it++)
	{
		TPlayerMJAction actionItem = (*it);
		int tmpI = int((*it).MJAName);
		aStream << "{" << "place: " << actionItem.Place << ", action: " << CAPTION_MJAction[tmpI] <<
			", str: " << (*it).ExpandStr << ", hasApply: " << (*it).HasApply <<
			", hasPass: " << (*it).HasPass << "}";
	}
}

void CMJActionMgr::analyseSpecialGangExpandStr(const string& expandStr, int& gangFlag, vector<int>& retCardList)
{
	// 特殊杠发过来的字符串： 27,28,29,31,32
	try
	{
		string gangStr = expandStr;
		vector<string> tmpVec;
		SplitStringToVector(gangStr, ',', tmpVec);
		for (string tmpStr : tmpVec)
		{
			if (!tmpStr.empty())
			{
				retCardList.push_back(stoi(tmpStr));
			}
		}

		if (retCardList[0] == 27)
			gangFlag = 0;
		else
			gangFlag = 1;
		
	}
	catch (CException* e)
	{
		gangFlag = -1;
	}
}