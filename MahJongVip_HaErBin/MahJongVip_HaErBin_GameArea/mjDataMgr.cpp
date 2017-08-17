#include "mjDataMgr.h"
#include "mjActionMgr.h"
#include "table_mgr.h"
#include "global_var.h"

CMJDataMgr::CMJDataMgr()
{
	FMJShouPai = new CMJShouPai();
	FMJPaiQiang = new CMJPaiQiang();
	FMJMingPai = new CMJMingPai();
	FMJDeck = new CMJDeck();
	FMJZhuoPai = new CMJZhuoPai();
}

CMJDataMgr::~CMJDataMgr()
{
	delete FMJZhuoPai;
	delete FMJDeck;
	delete FMJPaiQiang;
	delete FMJMingPai;
	delete FMJShouPai;
}

void CMJDataMgr::init(CGameTable* aParentTable, CMJActionMgr* mjActionMgr)
{
	FParentTable = aParentTable;
	FMJActionMgr = mjActionMgr;
}

void CMJDataMgr::updateAction()
{
	FMJActionMgr->clearActionList();
	FHuCountCurrAction = 0;
	FMaxHuPlace = -1;
	FHuPlace = 0;
	
	TMJActionName procAction = FMJActionMgr->FCurrProcAciton;
    if ((procAction == mjaChu) || (procAction == mjaJiaGang) || (procAction == mjaTing) || (procAction == mjaTingChi) || (procAction == mjaTingPeng))
	{
		// 检测三家可能的动作 胡、大明杠、碰牌、吃牌、摸牌。
		int startPlace = FLastChuPaiPlace;
		int checkPlace = (startPlace + 1) % MAX_TABLE_USER_COUNT;
		while (checkPlace != startPlace)
		{
			CTableUser* pCheckUser = FParentTable->FindUserByChairIndex(checkPlace);
			if (!pCheckUser)
			{
				LogWarning("updateAction", "error place: %d", checkPlace);
				return;
			}
			if (canHuPai(pCheckUser, false) > 0)
				FMJActionMgr->addAction(checkPlace, mjaHu, false, false, to_string(FLastCardID));
			if (procAction != mjaJiaGang)
			{
                //检测听吃
                {
                    vector<int> mjCountAry(MJDATA_TYPE_COUNT, 0);
                    string tmpTingChiStr;
                    int cardId00;
                    int cardId01;
                    FMJShouPai->getMJCountAry(pCheckUser->userInfo.activeInfo.chairIndex, mjCountAry);
                    // 检测听吃
					for (int k = 0; k < MAX_TABLE_USER_COUNT - 1; k++)
                    {
                        if (canTingChiPai(pCheckUser, FLastCardID, k, cardId00, cardId01))
                        {
                            mjCountAry[cardId00]--;
                            mjCountAry[cardId01]--;
                            for (size_t i = 0; i < mjCountAry.size(); i++)
                            {
                                if (mjCountAry[i] > 0)
                                {
                                    tmpTingChiStr.clear();
                                    if (canTingAfterChiPai(pCheckUser, FLastCardID, cardId00, cardId01, i, true, false, tmpTingChiStr))
                                    {
                                        // 听吃字符串 Q:W:X^Y^Z,X^Y^Z...  Q: 吃的牌，W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
                                        tmpTingChiStr = to_string(FLastCardID) + "," + to_string(k) + ":" + to_string(i) + ":" + tmpTingChiStr;
                                        FMJActionMgr->addAction(checkPlace, mjaTingChi, false, false, tmpTingChiStr);
                                    }
                                }
                            }
                            mjCountAry[cardId00]++;
                            mjCountAry[cardId01]++;
                        }
                    }
                }
                // 检测听碰
                {
                    vector<int> mjCountAry(MJDATA_TYPE_COUNT, 0);
                    FMJShouPai->getMJCountAry(pCheckUser->userInfo.activeInfo.chairIndex, mjCountAry);
                    string tmpTingChiStr;
                    if (canPengPai(pCheckUser, FLastCardID))
                    {
                        mjCountAry[FLastCardID] -= 2;
                        for (size_t i = 0; i < mjCountAry.size(); i++)
                        {
                            if (mjCountAry[i] > 0)
                            {
                                tmpTingChiStr.clear();
                                if (canTingAfterPengPai(pCheckUser, FLastCardID, i, true, false, tmpTingChiStr))
                                {
                                    // 听吃字符串 Q:W:X^Y^Z,X^Y^Z...  Q: 碰的牌，W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
                                    tmpTingChiStr = to_string(FLastCardID) + ":" + to_string(i) + ":" + tmpTingChiStr;
                                    FMJActionMgr->addAction(checkPlace, mjaTingPeng, false, false, tmpTingChiStr);
                                }
                            }
                        }
                        mjCountAry[FLastCardID] += 2;
                    }
                }
				if (canDaMingGang(pCheckUser, FLastCardID))
					FMJActionMgr->addAction(checkPlace, mjaDaMingGang, false, false, to_string(FLastCardID));
				if (canPengPai(pCheckUser, FLastCardID))
					FMJActionMgr->addAction(checkPlace, mjaPeng, false, false, to_string(FLastCardID));
				if ((checkPlace == ((FLastChuPaiPlace + 1) % MAX_TABLE_USER_COUNT)) && (FLastCardID < 27))
				{
					if (canChiPai(pCheckUser, FLastCardID, 0))
						FMJActionMgr->addAction(checkPlace, mjaChi, false, false, to_string(FLastCardID) + ",0");
					if (canChiPai(pCheckUser, FLastCardID, 1))
						FMJActionMgr->addAction(checkPlace, mjaChi, false, false, to_string(FLastCardID) + ",1");
					if (canChiPai(pCheckUser, FLastCardID, 2))
						FMJActionMgr->addAction(checkPlace, mjaChi, false, false, to_string(FLastCardID) + ",2");
                }
				if (canMoPai(checkPlace))
					FMJActionMgr->addAction(checkPlace, mjaMo, true, false, "");
			}
			checkPlace = (checkPlace + 1) % MAX_TABLE_USER_COUNT;
		}

		// 如果是加杠，添加加杠玩家的摸牌动作
		if (procAction == mjaJiaGang)
		{
			if (canMoPai(FCurrPlace))
				FMJActionMgr->addAction(FCurrPlace, mjaMo, true, false, "");
		}

		// 多家有动作，需要按照动作优先级排序
		FMJActionMgr->sortALLAction();
	}
	else
	{
		// 检测一家可能的动作 胡、补花、听牌、暗杠、加杠、出牌、摸牌。
		CTableUser* pCheckUser = FParentTable->FindUserByChairIndex(FCurrPlace);

		// 只有开局/自摸/加杠/听牌/或者其他玩家出牌才检测是否胡牌
		if ((procAction == mjaMo) || (procAction == mjaBuHua) || (procAction == mjaError))
		{
			if (canHuPai(pCheckUser, true) > 0)
				FMJActionMgr->addAction(FCurrPlace, mjaHu, false, false, to_string(FLastCardID));
		}
		// 加杠/暗杠
		vector<int> mjCountAry(MJDATA_TYPE_COUNT, 0);
		int tmpLastCardId = 0;
		string tmpTingStr;
		FMJShouPai->getMJCountAry(FCurrPlace, mjCountAry);
		for (size_t i = 0; i < mjCountAry.size(); i++)
		{
			if (mjCountAry[i] > 0)
			{
				tmpLastCardId = i;
				if (canAnGang(pCheckUser, i))
					FMJActionMgr->addAction(FCurrPlace, mjaAnGang, false, false, to_string(i));
				else if (canJiaGang(pCheckUser, i))
					FMJActionMgr->addAction(FCurrPlace, mjaJiaGang, false, false, to_string(i));
				tmpTingStr.clear();
				if (canTingPai(pCheckUser, i, true,false, tmpTingStr))
				{
					// 听牌字符串 W:X^Y^Z,X^Y^Z... W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
					tmpTingStr = to_string(i) + ":" + tmpTingStr;
					FMJActionMgr->addAction(FCurrPlace, mjaTing, false, false, tmpTingStr);
				}
			}
		}
		// 出牌
		if (canChuPai(pCheckUser, MJDATA_CARDID_ANY))
		{
			string willChuCard;
			if ((procAction == mjaMo) || (procAction == mjaBuHua)  )
				willChuCard = to_string(FLastCardID);
			else
				willChuCard = to_string(tmpLastCardId);
			// 如果已经胡牌，则系统主动申请出牌。
			FMJActionMgr->addAction(FCurrPlace, mjaChu, FParentTable->isHuUser(FCurrPlace), false, willChuCard);
		}
		if (canMoPai(FCurrPlace))
			FMJActionMgr->addAction(FCurrPlace, mjaMo, true, false, "");
	}

	FMJActionMgr->updateTimerState();
}

void CMJDataMgr::beginXingPai()
{
	FCurrPlace = FParentTable->m_bankerPlace;
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(FCurrPlace);
	pTUser->moCount4SpecialGang = 1;
	
	updateAction();
}

void CMJDataMgr::procZhuaPai(int eastPlace, int startPlace, int remainderCol)
{
	FMJPaiQiang->beginZhuaPai(startPlace, remainderCol);
	vector<int> tmpCards;
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		tmpCards.clear();
		if (i == eastPlace)
			FMJDeck->zhuaPai(14, tmpCards);
		else
			FMJDeck->zhuaPai(13, tmpCards);

  		// try
        //if (i == eastPlace)
        //{
        //    int tmpAry[14] = { 0, 0, 9, 9, 9, 12, 12, 12, 23, 23, 23, 15, 17, 24 };
        //    std::vector<int> vecTmp(tmpAry, tmpAry + 14);
        //    vecTmp.swap(tmpCards);
        //}
        //if (i == (eastPlace + 2) % 4)
        //{
        //    int tmpAry[13] = { 0, 0, 9, 10, 11, 13, 13, 13, 15, 17, 23, 22, 14 };
        //    std::vector<int> vecTmp(tmpAry, tmpAry + 13);
        //    vecTmp.swap(tmpCards);
        //}
        //if (i == (eastPlace + 1) % 4)
        //{
        //    int tmpAry[13] = { 0, 0, 11, 11, 11, 16, 16, 20, 17, 17, 23, 25, 14 };
        //    std::vector<int> vecTmp(tmpAry, tmpAry + 13);
        //    vecTmp.swap(tmpCards);
        //}
        //      if (i == (eastPlace + 3) % 4)
        //      {
        //          int tmpAry[13] = { 0, 0, 0, 17, 17, 18, 19, 20, 17, 15, 21, 25, 14 };
        //          std::vector<int> vecTmp(tmpAry, tmpAry + 13);
        //          vecTmp.swap(tmpCards);
        //      }

		FMJShouPai->zhuaPai(i, tmpCards);
	}
}

bool CMJDataMgr::canMoPai(int place) const
{
	return (place == FCurrPlace) && (!FMJShouPai->isJinZhang(place));
}

bool CMJDataMgr::canChuPai(CTableUser* pTUser, int cardId) const
{
	int place = pTUser->userInfo.activeInfo.chairIndex;
	{
		return (place == FCurrPlace) && (cardId != MJDATA_CARDID_ERROR) &&
			(FMJShouPai->isJinZhang(place)) && 
			((cardId == MJDATA_CARDID_ANY) || FMJShouPai->hasCard(place, cardId));
	}
}


bool CMJDataMgr::getSelfCardByChiCard(int cardId, int order, int& card00, int& card01) const
{
	if ((cardId >= 0) && (cardId < 27))
	{
		int cardValue = cardId2CardValue(cardId);
		if (order == 0)
		{
			if (cardValue > 7)
				return false;
			card00 = cardId + 1;
			card01 = cardId + 2;
		}
		else if (order == 1)
		{
			if ((cardValue < 2) || (cardValue > 8))
				return false;
			card00 = cardId - 1;
			card01 = cardId + 1;
		}
		else if (order == 2)
		{
			if (cardValue < 3)
				return false;
			card00 = cardId - 2;
			card01 = cardId - 1;
		}
		else
			return false;
	}
	else
		return false;

	return true;
}


bool CMJDataMgr::canChiPai(CTableUser* pTUser, int cardId, int order) const
{
    if (pTUser->hasTing)
        return false;
	int place = pTUser->userInfo.activeInfo.chairIndex;	
	if ((place == FCurrPlace) && (((FLastChuPaiPlace + 1) % 4) == place) && (!FMJShouPai->isJinZhang(place)) &&
		(cardId == FLastCardID) && (cardId >= 0) && (cardId < 27))
	{
		int card00 = 0;
		int card01 = 0;
		if (getSelfCardByChiCard(cardId, order, card00, card01))
		{
			return FMJShouPai->hasCard(place, card00) && FMJShouPai->hasCard(place, card01);
		}
		else
			return false;
	}
	else
		return false;
}

bool CMJDataMgr::canPengPai(CTableUser* pTUser, int cardId) const
{
    if (pTUser->hasTing)
        return false;
	int place = pTUser->userInfo.activeInfo.chairIndex;
	if (!pTUser->hasHu)
	{
		return (place != FLastChuPaiPlace) && (!FMJShouPai->isJinZhang(place)) &&
			(cardId == FLastCardID) && (FMJShouPai->cardCount(place, cardId) >= 2);
	}
	else
		return false;
}

bool CMJDataMgr::canDaMingGang(CTableUser* pTUser, int cardId) const
{
    // 大庆玩法不带杠
	if (FParentTable->m_tableRule.isHEBorHeiLongJiang == 1)
        return false;

	int place = pTUser->userInfo.activeInfo.chairIndex;
	if (!pTUser->hasTing)
	{
		return (place != FLastChuPaiPlace) && (!FMJShouPai->isJinZhang(place)) &&
			(cardId == FLastCardID) && (FMJShouPai->cardCount(place, cardId) == 3);
	}
    else
    {
        if ((place != FLastChuPaiPlace) && (!FMJShouPai->isJinZhang(place)) &&
            (cardId == FLastCardID) && (FMJShouPai->cardCount(place, cardId) == 3))
        {
            vector<int> tmpMjCountAry(MJDATA_TYPE_COUNT, 0);
            FMJShouPai->getMJCountAry(place, tmpMjCountAry);
            tmpMjCountAry[cardId] = 0;

            for (int addCardId : pTUser->willHuCardID)
            {
                tmpMjCountAry[addCardId]++;
                if ((0 < g_logic_mgr->isHuPai(!FMJMingPai->hasPengGang(place), !FMJMingPai->hasChiPai(place), tmpMjCountAry, FParentTable->m_tableRule, addCardId, INVALID_CARD_VALUE,false)))
                    return true;
                tmpMjCountAry[addCardId]--;
            }
        }
        return false;
    }
}

bool CMJDataMgr::canJiaGang(CTableUser* pTUser, int cardId) const
{
    // 大庆玩法不带杠
	if (FParentTable->m_tableRule.isHEBorHeiLongJiang == 1)
        return false;

	bool result;
	int place = pTUser->userInfo.activeInfo.chairIndex;

	result = (place == FCurrPlace) && (FMJShouPai->isJinZhang(place)) &&
        FMJMingPai->hasPengGangItem(place, cardId, mjaPeng) && (cardId == FLastCardID) &&
		(FMJActionMgr->FLastActionName != mjaPeng) && (FMJActionMgr->FCurrProcAciton != mjaPeng);

	return result;
}

bool CMJDataMgr::canAnGang(CTableUser* pTUser, int cardId) const
{
    // 大庆玩法不带杠
	if (FParentTable->m_tableRule.isHEBorHeiLongJiang == 1)
        return false;

	int place = pTUser->userInfo.activeInfo.chairIndex;
    if (!pTUser->hasTing)
    {
        return  (place == FCurrPlace) && (FMJShouPai->isJinZhang(place)) &&
            (FMJShouPai->cardCount(place, cardId) == 4);
    }
    else
    {
        if ((place == FCurrPlace) && (FMJShouPai->isJinZhang(place)) &&
            (FMJShouPai->cardCount(place, cardId) == 4) && (cardId == FLastCardID))
        {
            vector<int> tmpMjCountAry(MJDATA_TYPE_COUNT, 0);
            FMJShouPai->getMJCountAry(place, tmpMjCountAry);
            tmpMjCountAry[cardId] = 0;

            for (int addCardId : pTUser->willHuCardID)
            {
                tmpMjCountAry[addCardId]++;
                if ((0 < g_logic_mgr->isHuPai(!FMJMingPai->hasPengGang(place), !FMJMingPai->hasChiPai(place), tmpMjCountAry, FParentTable->m_tableRule, addCardId, INVALID_CARD_VALUE, false)))
                    return true;
                tmpMjCountAry[addCardId]--;
            }
        }
        return false;
    }
}
 
/*
0: 不胡牌
1： 普通胡牌
2： 七对胡牌
*/
int CMJDataMgr::canHuPai(CTableUser* pTUser, bool isZiMo) const
{
	int place = pTUser->userInfo.activeInfo.chairIndex;

    // 开牌炸
    if (FParentTable->m_tableRule.isKaiPaiZha)
    {
        if ((FMJActionMgr->FLastActionName == mjaError) && (place == FParentTable->m_bankerPlace))
        {
            vector<int> shouPaiAry(MJDATA_TYPE_COUNT, 0);
            FMJShouPai->getMJCountAry(place, shouPaiAry);
            for (size_t i = 0; i < shouPaiAry.size(); i++)
            {
                if (shouPaiAry[i] == 4)
                {
                    return 6;
                }
            }
        }
    }

	// 必须报听
	if (!pTUser->hasTing)
		return false;

    // 非站立胡必须开门
    if (!FParentTable->m_tableRule.isZhanLiHu && !pTUser->hasKaiMen)
        return false;

	vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, allCardCountAry);
	FMJMingPai->getMJCountAry(place, allCardCountAry);
	vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);
	if (!isZiMo){
		allCardCountAry[FLastCardID]++;
		shouPaiMjCountAry[FLastCardID]++;
	}

	// 胡牌必须有一或九，东南西北中发白也算一九
	if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
		return 0;

	// 必须有两种色以上
	if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
			return 0;

    if ( !pTUser->hasKaiMen && !pTUser->hasTing &&!(g_logic_mgr->getSuitCout(allCardCountAry)>1) )
		return false;

    if (FBaoPaiCardID == FLastCardID && !isZiMo)
    {
        if (find(pTUser->willHuCardID.begin(), pTUser->willHuCardID.end(), FLastCardID) == pTUser->willHuCardID.end())
            return false;
    }

    if (FLastCardID != FBaoPaiCardID && !FParentTable->m_tableRule.isGuaDaFeng && !FParentTable->m_tableRule.isLaizi && find(pTUser->willHuCardID.begin(), pTUser->willHuCardID.end(), FLastCardID) == pTUser->willHuCardID.end())
        return false;

	vector<int> tmpMjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, tmpMjCountAry);
	if (!isZiMo)
		tmpMjCountAry[FLastCardID]++;
	
    int huType = 0;
    // 摸宝胡牌
    if (pTUser->hasTing  && isZiMo && (FLastCardID == FBaoPaiCardID ||(FParentTable->m_tableRule.isLaizi && FLastCardID == 31)))
    {
        tmpMjCountAry[FLastCardID]--;
        for (auto HuCardID :pTUser->willHuCardID)
        {
            tmpMjCountAry[HuCardID]++;
            huType = g_logic_mgr->isHuPai(!FMJMingPai->hasPengGang(place), !FMJMingPai->hasChiPai(place), tmpMjCountAry, FParentTable->m_tableRule, HuCardID, INVALID_CARD_VALUE, false);
            if (huType > 0)
                return huType;
        }
    }
    
    // 刮大风
    if (FParentTable->m_tableRule.isGuaDaFeng && isZiMo)
    {
        vector<int> shouAry(MJDATA_TYPE_COUNT, 0);
        FMJShouPai->getMJCountAry(place, shouAry);
        if (shouAry[FLastCardID] == 4)
        {
            tmpMjCountAry[FLastCardID]--;
            for (auto HuCardID : pTUser->willHuCardID)
            {
                tmpMjCountAry[HuCardID]++;
                huType = g_logic_mgr->isHuPai(!FMJMingPai->hasPengGang(place), !FMJMingPai->hasChiPai(place), tmpMjCountAry, FParentTable->m_tableRule, HuCardID, FLastCardID, true);
                if (huType > 0)
                    return 7;                     
            }
        }
    }

    huType = g_logic_mgr->isHuPai(!FMJMingPai->hasPengGang(place), !FMJMingPai->hasChiPai(place), tmpMjCountAry, FParentTable->m_tableRule, FLastCardID, INVALID_CARD_VALUE, false);

	return huType;
}

bool CMJDataMgr::canTingPai(CTableUser* pTUser, int decCardId, bool needExpandStr, bool isProcTing, string& retStr)
{
	retStr.clear();

	if (pTUser->hasTing)
		return false;
	int place = pTUser->userInfo.activeInfo.chairIndex;
	if (FCurrPlace != place)
		return false;
	if (!FMJShouPai->isJinZhang(place))
		return false;
	if (!FMJShouPai->hasCard(place, decCardId))
		return false;

	vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, allCardCountAry);
	FMJMingPai->getMJCountAry(place, allCardCountAry);
	vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);
	allCardCountAry[decCardId]--;
	shouPaiMjCountAry[decCardId]--;

    // 听牌时，牌中必须带至少一个“幺”或“九”或“红中”
    if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        return 0;

    // 非站立胡时，门清不能听牌
    if (!FParentTable->m_tableRule.isZhanLiHu)
        if (!pTUser->hasKaiMen)
            return false;
    
    // 必须有两种色以上
	if ( g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
			return false;

    // 最后至少4张牌才可上听
    if (FMJShouPai->getUserCardCount(place) < 4)
        return false;

    // 听牌时，牌中必须带至少一组刻牌
    bool hasPengPai = FMJMingPai->hasPengGang(place);
    bool hasChiPai = FMJMingPai->hasChiPai(place);
	bool result = false;
	stringstream tmpStream;
	int tingCount = 0;
    vector<int> huTypeVec;
    huTypeVec.clear();
	for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
	{
		// 这里对删除的牌不能继续进行循环，因为如果是手牌胡牌牌型，且玩家没有选择胡，这张删除的牌是可以再胡的
		//if (i == decCardId)
		//	continue;
		shouPaiMjCountAry[i]++;
		allCardCountAry[i]++;

        if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

		{
			int huType = 0;

            huType = g_logic_mgr->isHuPai(!hasPengPai, !hasChiPai, shouPaiMjCountAry, FParentTable->m_tableRule, i, INVALID_CARD_VALUE, false);

            // 必须夹胡
            if (FParentTable->m_tableRule.isChunJia )
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }
            else if ( FParentTable->m_tableRule.isSanQiJia || FParentTable->m_tableRule.isDanDiaoJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }

			if (huType > 0)
			{
				result = true;
                huTypeVec.push_back(huType);
                if (isProcTing)
                    pTUser->willHuCardID.push_back(i);
				if (needExpandStr)
				{
					// 听牌字符串 W:X^Y^Z,X^Y^Z... W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
					vector<int> fanZhongInfo;
                    vector<vector<int>> shouPaiCards;
                    g_logic_mgr->getZuHeList(shouPaiCards);
                    calcFanZhongInfo(place, place, true, huType, i, allCardCountAry, shouPaiMjCountAry, shouPaiCards, fanZhongInfo, FParentTable->m_tableRule);
					int scores = g_logic_mgr->calcScores(fanZhongInfo, FParentTable->m_tableRule.isHEBorHeiLongJiang);
					int remaindCount = getRemaindCount(place, i);
					if (tingCount > 0)
						tmpStream << ",";
                    int isZhiDuiHu = 0;
                    if (huType == 5)
                        isZhiDuiHu = 1;
                    tmpStream << i << "^" << scores << "^" << remaindCount << "^" << isZhiDuiHu;
					tingCount++;
				}
			}
		}
		allCardCountAry[i]--;
		shouPaiMjCountAry[i]--;
	}

	retStr = tmpStream.str();

    // 纯夹只能胡一个牌值
    if (FParentTable->m_tableRule.isChunJia && tingCount > 1)
        result = false;

	return result;
}


bool CMJDataMgr::canTingChiPai(CTableUser* pTUser, int cardId, int order, int& cardId00, int& cardId01)
{
    bool isCanChi = false;
    int card00 = 0;
    int card01 = 0;
    int place = pTUser->userInfo.activeInfo.chairIndex;
    if ((place != FLastChuPaiPlace) && (!FMJShouPai->isJinZhang(place)) && (cardId == FLastCardID) && (cardId >= 0) && (cardId < 27))
    {
        if (getSelfCardByChiCard(cardId, order, card00, card01))
        {
            isCanChi = FMJShouPai->hasCard(place, card00) && FMJShouPai->hasCard(place, card01);
        }
    }
    cardId00 = card00;
    cardId01 = card01;
    return isCanChi;
}


bool CMJDataMgr::canTingAfterChiPai(CTableUser* pTUser, int cardId, int cardId00, int cardId01, int decCardId, bool needExpandStr, bool isProcTing, string& retStr)
{
    if (pTUser->hasTing)
        return false;
    int place = pTUser->userInfo.activeInfo.chairIndex;
    // 检测吃后能否听牌
    vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
    FMJShouPai->getMJCountAry(place, allCardCountAry);
    FMJMingPai->getMJCountAry(place, allCardCountAry);
    vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
    FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);

    allCardCountAry[cardId]++;

    shouPaiMjCountAry[cardId00]--;
    shouPaiMjCountAry[cardId01]--;

    allCardCountAry[decCardId]--;
    shouPaiMjCountAry[decCardId]--;

    // 听牌时，牌中必须带至少一个“幺”或“九”或“红中”
    if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
    {
        return 0;
    }
    // 必须有两种色以上
    if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
    {
        return false;
    }
    // 最后至少4张牌才可上听
    if (FMJShouPai->getUserCardCount(place) < 4)
    {
        return false;
    }
    // 听牌时，牌中必须带至少一组刻牌
    bool hasPengPai = FMJMingPai->hasPengGang(place);
    bool hasChiPai = true;
    bool result = false;
    stringstream tmpStream;
    int tingCount = 0;
    for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
    {
        shouPaiMjCountAry[i]++;
        allCardCountAry[i]++;

        if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        {
            int huType = 0;
            huType = g_logic_mgr->isHuPai(!hasPengPai, !hasChiPai, shouPaiMjCountAry, FParentTable->m_tableRule, i, INVALID_CARD_VALUE, false);

            // 必须夹胡
            if (FParentTable->m_tableRule.isChunJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }
            else  if (FParentTable->m_tableRule.isSanQiJia || FParentTable->m_tableRule.isDanDiaoJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }

            if (huType > 0)
            {
                result = true;
                if (isProcTing)
                    pTUser->willHuCardID.push_back(i);
                if (needExpandStr)
                {
                    // 听牌字符串 W:X^Y^Z,X^Y^Z... W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
                    vector<int> fanZhongInfo;
                    vector<vector<int>> shouPaiCards;
                    g_logic_mgr->getZuHeList(shouPaiCards);
                    calcFanZhongInfo(place, place, true, huType, i, allCardCountAry, shouPaiMjCountAry, shouPaiCards, fanZhongInfo, FParentTable->m_tableRule);
					int scores = g_logic_mgr->calcScores(fanZhongInfo, FParentTable->m_tableRule.isHEBorHeiLongJiang);
                    int remaindCount = getRemaindCount(place, i);
                    if (tingCount > 0)
                        tmpStream << ",";
                    int isZhiDuiHu = 0;
                    if (huType == 5)
                        isZhiDuiHu = 1;
                    tmpStream << i << "^" << scores << "^" << remaindCount << "^" << isZhiDuiHu;
                    tingCount++;
                }
            }
        }
        allCardCountAry[i]--;
        shouPaiMjCountAry[i]--;
    }
    retStr = tmpStream.str();

    // 纯夹只能胡一个牌值
    if (FParentTable->m_tableRule.isChunJia && tingCount > 1)
        result = false;

    return result;
}

bool CMJDataMgr::canTingAfterPengPai(CTableUser* pTUser, int cardId, int decCardId, bool needExpandStr, bool isProcTing, string& retStr)
{
    if (pTUser->hasTing)
        return false;
    int place = pTUser->userInfo.activeInfo.chairIndex;
    // 检测碰后能否听牌
    vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
    FMJShouPai->getMJCountAry(place, allCardCountAry);
    FMJMingPai->getMJCountAry(place, allCardCountAry);

    vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
    FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);

    allCardCountAry[cardId] += 1;
    shouPaiMjCountAry[cardId] -= 2;

    allCardCountAry[decCardId] -=1;
    shouPaiMjCountAry[decCardId] -= 1;

    // 听牌时，牌中必须带至少一个“幺”或“九”或“红中”
    if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        return 0;
    // 必须有两种色以上
    if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
        return false;
    // 最后至少4张牌才可上听
    if (FMJShouPai->getUserCardCount(place) < 4)
        return false;

    // 听牌时，牌中必须带至少一组刻牌
    bool hasPengPai = true;
    bool hasChiPai = FMJMingPai->hasChiPai(place);
    bool result = false;
    stringstream tmpStream;
    int tingCount = 0;

    for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
    {
        shouPaiMjCountAry[i]++;
        allCardCountAry[i]++;

        if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        {
            int huType = 0;
            huType = g_logic_mgr->isHuPai(!hasPengPai, !hasChiPai, shouPaiMjCountAry, FParentTable->m_tableRule, i, INVALID_CARD_VALUE, false);

            // 必须夹胡
            if (FParentTable->m_tableRule.isChunJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }
            else if (FParentTable->m_tableRule.isSanQiJia || FParentTable->m_tableRule.isDanDiaoJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }

            if (huType > 0)
            {
                result = true;
                if (isProcTing)
                    pTUser->willHuCardID.push_back(i);
                if (needExpandStr)
                {
                    // 听牌字符串 W:X^Y^Z,X^Y^Z... W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
                    vector<int> fanZhongInfo;
                    vector<vector<int>> shouPaiCards;
                    g_logic_mgr->getZuHeList(shouPaiCards);
                    calcFanZhongInfo(place, place, true, huType, i, allCardCountAry, shouPaiMjCountAry, shouPaiCards, fanZhongInfo, FParentTable->m_tableRule);
					int scores = g_logic_mgr->calcScores(fanZhongInfo, FParentTable->m_tableRule.isHEBorHeiLongJiang);
                    int remaindCount = getRemaindCount(place, i);
                    if (tingCount > 0)
                        tmpStream << ",";
                    int isZhiDuiHu = 0;
                    if (huType == 5)
                        isZhiDuiHu = 1;                    
                    tmpStream << i << "^" << scores << "^" << remaindCount << "^" << isZhiDuiHu;
                    tingCount++;
                }
            }
        }
        allCardCountAry[i]--;
        shouPaiMjCountAry[i]--;
    }

    {
        for (auto i : pTUser->willHuCardID)
        {
            LogInfo("CMJDataMgr::canTingAfterPengPai", "能胡的牌：%d", i);
        }
    }

    retStr = tmpStream.str();

    // 纯夹只能胡一个牌值
    if (FParentTable->m_tableRule.isChunJia && tingCount > 1)
        result = false;

    return result;
}

void CMJDataMgr::calcTingInfo(CTableUser* pTUser)
{
    if (!pTUser->hasTing)
        return;
	int place = pTUser->userInfo.activeInfo.chairIndex;
	pTUser->tingPaiInfoArr.clear();

	vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, allCardCountAry);
	FMJMingPai->getMJCountAry(place, allCardCountAry);

	vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);

	// 不能缺门的条件
	if ( g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
			return;

	bool result = false;
	stringstream tmpStream;
	int tingCount = 0;
	bool hasPengGang = FMJMingPai->hasPengGang(place);
    bool hasChiPai = FMJMingPai->hasChiPai(place);
	for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
	{
		// 这里对删除的牌不能继续进行循环，因为如果是手牌胡牌牌型，且玩家没有选择胡，这张删除的牌是可以再胡的
		//if (i == decCardId)
		//	continue;
		shouPaiMjCountAry[i]++;
		allCardCountAry[i]++;

        if (!g_logic_mgr->hasYaoJiuCard(allCardCountAry))
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

        if (g_logic_mgr->getMenSuitCount(allCardCountAry) < 2)
        {
            allCardCountAry[i]--;
            shouPaiMjCountAry[i]--;
            continue;
        }

		{
			int huType = 0;
            huType = g_logic_mgr->isHuPai(!hasPengGang, !hasChiPai, shouPaiMjCountAry, FParentTable->m_tableRule, i, FBaoPaiCardID, false);

            // 必须夹胡
            if (FParentTable->m_tableRule.isChunJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }
            else if (FParentTable->m_tableRule.isSanQiJia || FParentTable->m_tableRule.isDanDiaoJia)
            {
                if (huType < 2)
                {
                    allCardCountAry[i]--;
                    shouPaiMjCountAry[i]--;
                    continue;
                }
            }
			if (huType > 0)
			{
				// 听牌字符串 W:X^Y^Z,X^Y^Z... W: 打出的牌，X: 所听的牌，Y：听牌番数，Z: 还有几张
				vector<int> fanZhongInfo;
                vector<vector<int>> shouPaiCards;
                g_logic_mgr->getZuHeList(shouPaiCards);
                calcFanZhongInfo(place, place, true, huType, i, allCardCountAry, shouPaiMjCountAry, shouPaiCards, fanZhongInfo, FParentTable->m_tableRule);
				int scores = g_logic_mgr->calcScores(fanZhongInfo, FParentTable->m_tableRule.isHEBorHeiLongJiang);
				TMJTingPaiInfoItem tingItem(i, scores);
				pTUser->tingPaiInfoArr.push_back(tingItem);
                tingCount++;
			}
		}
		allCardCountAry[i]--;
		shouPaiMjCountAry[i]--;
	}

    if (FParentTable->m_tableRule.isChunJia && tingCount > 1)
    {
        pTUser->tingPaiInfoArr.clear();
    }

}
	

bool CMJDataMgr::procMoPai(int place)
{
    CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canMoPai(place))
		return false;
	if (FMJDeck->isHuangPai())
	{
		FParentTable->endXingPaiCalcResult();
		return true;
	}

	if (!FMJActionMgr->FBIsGangBu)
		FMJPaiQiang->moPai();     
	else
		// todo: 杠后补张其实应该从牌墙末尾拿牌，
		FMJPaiQiang->moPai();
	
	
	FLastCardID = FMJDeck->takePai();

    //if (place == FParentTable->m_bankerPlace && pTUser->hasTing)
    //{
    //    FLastCardID = 16;
    //}

	FMJShouPai->takePai(place, FLastCardID);
	// 摸牌之后需要将passHu的标志位置为false
	pTUser->haveHuPass = false;
	pTUser->moCount4SpecialGang++;

	updateAction();

	// send packet
	{
		for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MGSID_CLIENT_G_MO_PAI_NOTIFY) << place << FLastCardID << int(FMJActionMgr->FBIsGangBu) <<
				FMJPaiQiang->m_currMoPaiPlace << FMJPaiQiang->m_cntList[FMJPaiQiang->m_currMoPaiPlace] <<
				// 注: 此时  GameMJActionMgr.DecTimeCount 还没变为 出牌时间！
				FCurrPlace << FMJActionMgr->FTimerState << g_config_area->discard_sec;
			FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
			(*pu) << EndPluto;
			FParentTable->SendPlutoToUser(pu, *it);
		}
	}

	debugActionMsg(place, mjaMo, FLastCardID);

	return true;
}

bool CMJDataMgr::procChuPai(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canChuPai(pTUser, cardId))
		return false;

	FCurrPlace = (FCurrPlace + 1) % MAX_TABLE_USER_COUNT;
	FLastChuPaiPlace = place;
	FLastCardID = cardId;
	FMJShouPai->chuPai(place, cardId);
	FMJZhuoPai->addCard(place, cardId);
	// 只要有出牌就应该将passHu标志位置为false
	pTUser->haveHuPass = false;

    // 检查是否需要换宝
    if (FBaoPaiCardID != INVALID_CARD_VALUE && getMJCountZhuoPaiAndMingPai(FBaoPaiCardID)==3)
    {
        if (!FMJDeck->isHuangPai())
        {
            do
            {
                FBaoPaiCardID = FMJDeck->takePai();
                FMJPaiQiang->moPai();
            } while (!FMJDeck->isHuangPai() && getMJCountZhuoPaiAndMingPai(FBaoPaiCardID) == 3);

            if (FMJDeck->isHuangPai())
            {
                FParentTable->endXingPaiCalcResult();
            }
            for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
            {
                int flag = 0;
                CPluto* pu = new CPluto();
                (*pu).Encode(MSGID_CLIENT_G_MO_BAO_NOTIFY) << FMJPaiQiang->m_currMoPaiPlace << FMJPaiQiang->m_cntList[FMJPaiQiang->m_currMoPaiPlace] << flag << FBaoPaiCardID;
                (*pu) << EndPluto;
                FParentTable->SendPlutoToUser(pu, *it);
            }
        }
        else
        {
            FParentTable->endXingPaiCalcResult();
        }
    }

	updateAction();

	// send packet
	{
		int decTimeCount = 1;
		if (FMJActionMgr->FTimerState == tsWaitDongZuo)
			decTimeCount = g_config_area->waitDongZuo_sec;
		else if (FMJActionMgr->FTimerState == tsWaitChuPai)
			decTimeCount = g_config_area->discard_sec;

		for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MGSID_CLIENT_G_CHU_PAI_NOTIFY) << place << FLastCardID << FCurrPlace <<
				FMJActionMgr->FTimerState << decTimeCount;
			FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
			(*pu) << EndPluto;
			FParentTable->SendPlutoToUser(pu, *it);
		}
	}

	{
		// 检测玩家是否可以听牌，并记录下来，便于用户查询
		calcTingInfo(pTUser);
	}

	// debugStr
	{
		stringstream debugStream;
		debugStream << "出牌： place: " << place << ", " << CAPTION_MJName[cardId] << "  ; ";
		FMJActionMgr->debugStr(debugStream);
		debugStream << endl;
		LogInfo("procChuPai", debugStream.str().c_str());
	}
	return true;
}

bool CMJDataMgr::procChiPai(int place, int cardId, int order)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canChiPai(pTUser, cardId, order))
		return false;
	if (!FMJActionMgr->hasChuPai())
		return false;

	int card00, card01;
	if (!getSelfCardByChiCard(cardId, order, card00, card01))
	{
		LogWarning("procChiPai", "ERROR.getSelfCardByChiCard: %d, %d", place, order);
		return false;
	}

	FMJShouPai->chiPai(place, card00, card01);
	vector<int> tmpVec;
	if (order == 0)
	{
		tmpVec.push_back(cardId);
		tmpVec.push_back(card00);
		tmpVec.push_back(card01);
	}
	else if (order == 1)
	{
		tmpVec.push_back(card00);
		tmpVec.push_back(cardId);
		tmpVec.push_back(card01);
	}
	else if (order == 2)
	{
		tmpVec.push_back(card00);
		tmpVec.push_back(card01);
		tmpVec.push_back(cardId);
	}
	else
	{
		LogWarning("procChiPai", "ERROR.order: %d, %d", place, order);
		return false;
	}
	TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaChi, tmpVec);
	FMJMingPai->addMingPaiItem(mingPaiItem);
    FMJZhuoPai->delCard(FLastChuPaiPlace, cardId);
	pTUser->hasKaiMen = true;

	updateAction();
	{
		// sendPacket
		int decTimeCount = g_config_area->discard_sec;
		for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)		{			CPluto* pu = new CPluto();
			(*pu).Encode(MGSID_CLIENT_G_CHI_NOTIFY) << place << cardId << order << int(mjaChi) <<
				FLastChuPaiPlace << FCurrPlace << FMJActionMgr->FTimerState << decTimeCount;			FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);			(*pu) << EndPluto;			FParentTable->SendPlutoToUser(pu, *it);		}
	}

	{
		// debug
		stringstream debugStream;
		string tmpStr;
		Vector2Str(tmpVec, true, ',', tmpStr);
		debugStream << CAPTION_MJAction[mjaChi] << "： place: " << place << ", " << CAPTION_MJName[cardId] << ", " << tmpStr << "  ; ";
		FMJActionMgr->debugStr(debugStream);
		debugStream << endl;
		LogInfo(CAPTION_MJAction[mjaChi].c_str(), debugStream.str().c_str());
	}

	return true;

}

void CMJDataMgr::sendPengGangPacket(int place, int lastChuPaiPlace, int cardId, TMJActionName mjAction)
{
	int decTimeCount = g_config_area->discard_sec;
	for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
	{
		CPluto* pu = new CPluto();
		(*pu).Encode(MGSID_CLIENT_G_PENG_GANG_NOTIFY) << place << cardId << int(mjAction) <<
			lastChuPaiPlace << FCurrPlace << FMJActionMgr->FTimerState << decTimeCount;
		FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
		(*pu) << EndPluto;
		FParentTable->SendPlutoToUser(pu, *it);
	}
}

void CMJDataMgr::sendErrorActionRespPacket(int place, int errorCode, const string errorStr)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	CPluto* pu = new CPluto();
	(*pu).Encode(MSGID_CLIENT_G_ERROR_ACTION_RESP) << errorCode << errorStr;
	FMJShouPai->WriteToPluto(place, *pu);
	FMJActionMgr->writeUserAction2Pluto(place, pu);
	(*pu) << EndPluto;
	FParentTable->SendPlutoToUser(pu, pTUser);
}

void CMJDataMgr::debugActionMsg(int place, TMJActionName mjAction, int cardId)
{
	stringstream debugStream;
	debugStream << CAPTION_MJAction[mjAction] <<  "： place: " << place << ", " << CAPTION_MJName[cardId] << "  ; ";
	FMJActionMgr->debugStr(debugStream);
	debugStream << endl;
	LogInfo(CAPTION_MJAction[mjAction].c_str(), debugStream.str().c_str());
}

bool CMJDataMgr::procPengPai(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canPengPai(pTUser, cardId))
		return false;
	if (!FMJActionMgr->hasChuPai())
		return false;
	
	FMJShouPai->pengGangPai(place, cardId, 2);
	pTUser->hasKaiMen = true;
	TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaPeng, cardId);
	FMJMingPai->addMingPaiItem(mingPaiItem);
	FMJZhuoPai->delCard(FLastChuPaiPlace, cardId);
	FCurrPlace = place;

	updateAction();
	sendPengGangPacket(place, FLastChuPaiPlace, cardId, mjaPeng);

	debugActionMsg(place, mjaPeng, cardId);

	return true;
}

bool CMJDataMgr::procDaMingGang(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canDaMingGang(pTUser, cardId))
		return false;
	if (!FMJActionMgr->hasChuPai())
		return false;

	pTUser->countMingGang++;
	pTUser->hasKaiMen = true;
	FMJShouPai->pengGangPai(place, cardId, 3);
	TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaDaMingGang, cardId);
	FMJMingPai->addMingPaiItem(mingPaiItem);
	FMJZhuoPai->delCard(FLastChuPaiPlace, cardId);
	FCurrPlace = place;

	updateAction();
	sendPengGangPacket(place, FLastChuPaiPlace, cardId, mjaDaMingGang);

	debugActionMsg(place, mjaDaMingGang, cardId);

	return true;
}

bool CMJDataMgr::procJiaGang(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canJiaGang(pTUser, cardId))
		return false;

	pTUser->countMingGang++;
	FMJShouPai->pengGangPai(place, cardId, 1);
	int paoPlace = FMJMingPai->jiaGang(place, cardId);
	FCurrPlace = place;
	FLastChuPaiPlace = place;
	FLastCardID = cardId;

	updateAction();
	sendPengGangPacket(place, place, cardId, mjaJiaGang);

	debugActionMsg(place, mjaJiaGang, cardId);

	return true;
}

bool CMJDataMgr::procAnGang(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	if (!canAnGang(pTUser, cardId))
		return false;

	FMJShouPai->pengGangPai(place, cardId, 4);
	TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaAnGang, cardId);
	FMJMingPai->addMingPaiItem(mingPaiItem);
	pTUser->countAnGang++;

	updateAction();
	sendPengGangPacket(place, place, cardId, mjaAnGang);

	debugActionMsg(place, mjaAnGang, cardId);

	return true;
}

bool CMJDataMgr::procTingPai(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	string tmpStr;
	if (!canTingPai(pTUser, cardId, false,true, tmpStr))
		return false;

	pTUser->hasTing = true;
	FMJShouPai->chuPai(place, cardId);
	FMJZhuoPai->addCard(place, cardId);
	FLastChuPaiPlace = FCurrPlace;
	FLastCardID = cardId;
	FCurrPlace = (place + 1) % MAX_TABLE_USER_COUNT;

    // 摸宝牌
    procMoBaoPai();

	updateAction();
	{
		int decTimeCount = g_config_area->discard_sec;
		for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MSGID_CLIENT_G_TING_PAI_NOTIFY) << place << FLastCardID << FCurrPlace << 
                FMJActionMgr->FTimerState << decTimeCount;
			FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
			(*pu) << EndPluto;
			FParentTable->SendPlutoToUser(pu, *it);
		}
	}

    {
        // 检测玩家是否可以听牌，并记录下来，便于用户查询
        calcTingInfo(pTUser);
    }

	debugActionMsg(place, mjaTing, cardId);

	return true;
}


bool CMJDataMgr::procTingChiPai(int place, const string& expandStr)
{
    CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);

    int cardId;
    int order;
    int cardId00;
    int cardId01;
    int decCardId = 0;

    vector<string> sp;
    sp.clear();
    SplitStringToVector(expandStr, ':', sp);
    if (sp.size() != 3)
    {
        LogWarning("CMJDataMgr::procTingPai", "format of expandStr is wrong!!");
        return false;
    }
    vector<string> sp1;
    sp1.clear();
    SplitStringToVector(sp[0], ',', sp1);
    if (sp1.size() != 2)
    {
        LogWarning("CMJDataMgr::procTingPai", "format of expandStr is wrong!!");
        return false;
    }
    cardId = stoi(sp1[0]);
    order = stoi(sp1[1]);
    decCardId = stoi(sp[1]);

    if (!canTingChiPai(pTUser, cardId, order,cardId00,cardId01))
        return false;
    if (!FMJActionMgr->hasChuPai())
        return false;
    int card00, card01;
    if (!getSelfCardByChiCard(cardId, order, card00, card01))
    {
        LogWarning("procChiPai", "ERROR.getSelfCardByChiCard: %d, %d", place, order);
        return false;
    }

    string tmpStr;
    if (!canTingAfterChiPai(pTUser, cardId, cardId00, cardId01, decCardId, false,true, tmpStr))
        return false;

    FMJShouPai->chiPai(place, card00, card01);
    vector<int> tmpVec;
    if (order == 0)
    {
        tmpVec.push_back(cardId);
        tmpVec.push_back(card00);
        tmpVec.push_back(card01);
    }
    else if (order == 1)
    {
        tmpVec.push_back(card00);
        tmpVec.push_back(cardId);
        tmpVec.push_back(card01);
    }
    else if (order == 2)
    {
        tmpVec.push_back(card00);
        tmpVec.push_back(card01);
        tmpVec.push_back(cardId);
    }
    else
    {
        LogWarning("procChiPai", "ERROR.order: %d, %d", place, order);
        return false;
    }
    TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaChi, tmpVec);
    FMJMingPai->addMingPaiItem(mingPaiItem);
    FMJZhuoPai->delCard(FLastChuPaiPlace, cardId);
    pTUser->hasKaiMen = true;
    int chuPaiPlace = FLastChuPaiPlace;

    pTUser->hasTing = true;
    FMJShouPai->chuPai(place, decCardId);
    FMJZhuoPai->addCard(place, decCardId);
    FLastChuPaiPlace = place;
    FLastCardID = decCardId;
	FCurrPlace = (place + 1) % MAX_TABLE_USER_COUNT;

    // 摸宝牌
    procMoBaoPai();

    updateAction();

    {
        // sendPacket
        int decTimeCount = g_config_area->discard_sec;
        for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)        {            CPluto* pu = new CPluto();
            (*pu).Encode(MGSID_CLIENT_G_TING_CHI_NOTIFY) << place << cardId << order << int(mjaTingChi) << chuPaiPlace << FLastCardID <<
                FLastChuPaiPlace << FCurrPlace << FMJActionMgr->FTimerState << decTimeCount;            FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);            (*pu) << EndPluto;            FParentTable->SendPlutoToUser(pu, *it);        }
    }

    {
        // 检测玩家是否可以听牌，并记录下来，便于用户查询
        calcTingInfo(pTUser);
    }

    {
        // debug
        stringstream debugStream;
        string tmpStr;
        Vector2Str(tmpVec, true, ',', tmpStr);
        debugStream << CAPTION_MJAction[mjaTingChi] << ": place: " << place << ", " << CAPTION_MJName[cardId] << ", " << tmpStr << "," << ": 听吃出牌" 
            << CAPTION_MJName[FLastCardID] << "  ; ";
        FMJActionMgr->debugStr(debugStream);
        debugStream << endl;
        LogInfo(CAPTION_MJAction[mjaTingChi].c_str(), debugStream.str().c_str());
    }

    return true;
}

bool CMJDataMgr::procTingPengPai(int place, const string& expandStr)
{
    CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
    int cardId;
    int decCardId;

    vector<string> sp;
    sp.clear();
    SplitStringToVector(expandStr, ':', sp);
    if (sp.size() != 3)
    {
        LogWarning("CMJDataMgr::procTingPai", "format of expandStr is wrong!!");
        return false;
    }
    cardId = stoi(sp[0]);
    decCardId = stoi(sp[1]);

    if (!canPengPai(pTUser, cardId))
        return false;

    if (!FMJActionMgr->hasChuPai())
        return false;

    string tmpStr;
    if (!canTingAfterPengPai(pTUser, cardId,  decCardId, false,true, tmpStr))
        return false;
    // 碰
    FMJShouPai->pengGangPai(place, cardId, 2);
    pTUser->hasKaiMen = true;
    TMJMingPaiItem mingPaiItem(place, FLastChuPaiPlace, cardId, mjaPeng, cardId);
    FMJMingPai->addMingPaiItem(mingPaiItem);
    FMJZhuoPai->delCard(FLastChuPaiPlace, cardId);
    FCurrPlace = place;
    int chuPaiPlace = FLastChuPaiPlace;
    // 听
    pTUser->hasTing = true;
    FMJShouPai->chuPai(place, decCardId);
    FMJZhuoPai->addCard(place, decCardId);
    FLastChuPaiPlace = place;
    FLastCardID = decCardId;
	FCurrPlace = (place + 1) % MAX_TABLE_USER_COUNT;

    // 摸宝牌
    procMoBaoPai();

    updateAction();
    
    {
        // sendPacket
        int decTimeCount = g_config_area->discard_sec;
        for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)        {            CPluto* pu = new CPluto();
            (*pu).Encode(MGSID_CLIENT_G_TING_PENG_NOTIFY) << place << cardId << int(mjaTingPeng) << chuPaiPlace << FLastCardID <<
                FLastChuPaiPlace << FCurrPlace << FMJActionMgr->FTimerState << decTimeCount;            FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);            (*pu) << EndPluto;            FParentTable->SendPlutoToUser(pu, *it);        }
    }

    {
        // 检测玩家是否可以听牌，并记录下来，便于用户查询
        calcTingInfo(pTUser);
    }

    debugActionMsg(place, mjaTingPeng, cardId);

    {
        for (auto i :pTUser->willHuCardID)
        {
            LogInfo("CMJDataMgr::procTingPengPai", "能胡的牌：%d",i);
        }
    }

    return true;
}

bool CMJDataMgr::procHuPai(int place, int cardId)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);
	bool isZiMo = (FMJActionMgr->FLastActionName == mjaMo) || (FMJActionMgr->FLastActionName == mjaError);
	int huType = canHuPai(pTUser, isZiMo);
    if (huType <= 0)
		return false;

	// 计算番种得分记录下来
	vector<int> allCardCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, allCardCountAry);
	FMJMingPai->getMJCountAry(place, allCardCountAry);
	vector<int> shouPaiMjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, shouPaiMjCountAry);
	if (!isZiMo)
	{
		allCardCountAry[FLastCardID]++;
		shouPaiMjCountAry[FLastCardID]++;
	}
	vector<int> fanZhongInfo;
    vector<vector<int>> shouPaiCards;
    g_logic_mgr->getZuHeList(shouPaiCards);
    calcFanZhongInfo(place, FLastChuPaiPlace, isZiMo, huType, FLastCardID, allCardCountAry, shouPaiMjCountAry, shouPaiCards, fanZhongInfo, FParentTable->m_tableRule);
	// 放入胡牌信息列表中，赢家输家都要加
	addAHuPaiInfo(place, FLastChuPaiPlace, isZiMo, FLastCardID, fanZhongInfo);
	pTUser->hasHu = true;

	// 拿出手牌
	if (isZiMo){
		pTUser->countZiMoHu++;
		FMJShouPai->chuPai(place, cardId);
		FHuPlace = place;
	}
	else
	{
		pTUser->countDianPaoHu++;
		CTableUser* pTChuPaiUser = FParentTable->FindUserByChairIndex(FLastChuPaiPlace);
		pTChuPaiUser->countDianPao++;
		// 牌局进行 一炮多响时，下一个玩家的摸牌位置。
		// 由发炮玩家的位置开始算起，逆时针计算，离放炮玩家最远的胡牌玩家的下一家进行摸牌
		int calcPlace = (place - FLastChuPaiPlace + MAX_TABLE_USER_COUNT) % MAX_TABLE_USER_COUNT;
		if (calcPlace > FMaxHuPlace)
		{
			FMaxHuPlace = calcPlace;
			FHuPlace = place;
		}
	}
	
	int huPaiCnt = ++FHuCountCurrAction;
	// sendPack
	{
		int decTimeCount = g_config_area->discard_sec;
		for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
		{
			CPluto* pu = new CPluto();
			(*pu).Encode(MSGID_CLIENT_G_HU_NOTIFY) << place << int(isZiMo) << FLastChuPaiPlace << FLastCardID <<
				huPaiCnt << FCurrPlace << FMJActionMgr->FTimerState << decTimeCount << int32_t(0);
			FParentTable->writeTotalScore2Pluto(pu);
			FMJActionMgr->writeUserAction2Pluto((*it)->userInfo.activeInfo.chairIndex, pu);
			(*pu) << EndPluto;
			FParentTable->SendPlutoToUser(pu, *it);
		}
	}

	debugActionMsg(place, mjaHu, cardId);

	FParentTable->endXingPaiCalcResult();

	return true;
}

void CMJDataMgr::RoundStopClearData()
{
	FMJDeck->clearData();
	FMJShouPai->clearData();
	FMJMingPai->clearData();
	FMJZhuoPai->clearData();
	FMJPaiQiang->clearData(FParentTable->getEastPlace());
	FMJHasHuPai.clear();
    FBaoPaiCardID = INVALID_CARD_VALUE;
}

/*
	添加赢局信息
	注意：内部修改杠出的番种
*/
void CMJDataMgr::addAHuPaiInfo(int winnerPlace, int paoPlace, bool isZiMo, int cardId, const vector<int>& fanZhongList)
{
    // 哈尔滨玩法
	if (FParentTable->m_tableRule.isHEBorHeiLongJiang == 0)
    {
        // 是否为上听时点炮（上听出的牌点炮也包三家）
        bool isShangTingPao = ((FMJActionMgr->FLastActionName == mjaTing) || (FMJActionMgr->FLastActionName == mjaTingChi) || (FMJActionMgr->FLastActionName == mjaTingPeng)) && (!isZiMo);

        for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
        {
            CTableUser* pTUser = FParentTable->FindUserByChairIndex(i);
            if (i == winnerPlace)
            {
                TMJHuPaiInfoItem addItem(true, isZiMo, paoPlace, cardId, fanZhongList);
                pTUser->huPaiInfo.push_back(addItem);
            }
            else
            {
                if (isZiMo)
                {
                    vector<int> tmpFanZhongList = fanZhongList;

                    if (pTUser->hasKaiMen)
                        tmpFanZhongList[mjfzKaiMen] = 1;

                    TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                    pTUser->huPaiInfo.push_back(addItem);
                }
                else
                {
                    CTableUser* pTPaoUser = FParentTable->FindUserByChairIndex(paoPlace);
                    if (!pTPaoUser->hasTing || isShangTingPao)
                    {
                        if (i == paoPlace)
                        {

                            for (int k = 0; k < MAX_TABLE_USER_COUNT; k++)
                            {
                                if (k != winnerPlace)
                                {
                                    vector<int> tmpFanZhongList = fanZhongList;

                                    CTableUser* pTLoseUser = FParentTable->FindUserByChairIndex(k);
                                    if (pTLoseUser->hasKaiMen)
                                        tmpFanZhongList[mjfzKaiMen] = 1;

                                    if (k == paoPlace)
                                        tmpFanZhongList[mjfzDianPao] = 1;

                                    TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem);
                                }
                            }
                        }
                    }
                    else
                    {
                        if (i == paoPlace)
                        {
                            vector<int> tmpFanZhongList = fanZhongList;

                            tmpFanZhongList[mjfzDianPao] = 1;

                            tmpFanZhongList[mjfzBaoTing] = 1;

                            if (pTUser->hasKaiMen)
                                tmpFanZhongList[mjfzKaiMen] = 1;

                            TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                            pTUser->huPaiInfo.push_back(addItem);
                        }
                        else
                        {
                            vector<int> tmpFanZhongList = fanZhongList;

                            if (pTUser->hasKaiMen)
                                tmpFanZhongList[mjfzKaiMen] = 1;

                            TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                            pTUser->huPaiInfo.push_back(addItem);
                        }
                    }
                }
            }
        }
    }
    // 大庆玩法
    else
    {
        for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
        {
            vector<int> tmpFanZhongList = fanZhongList;
            CTableUser* pTUser = FParentTable->FindUserByChairIndex(i);
            if (i == winnerPlace)
            {
                TMJHuPaiInfoItem addItem(true, isZiMo, paoPlace, cardId, fanZhongList);
                pTUser->huPaiInfo.push_back(addItem);
            }
            else
            {
                if (isZiMo)
                {
                    if (i == FParentTable->m_bankerPlace)
                    {
                        tmpFanZhongList[mjfzdpZhuangJia] = 1;
                        TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                        pTUser->huPaiInfo.push_back(addItem);
                    }
                    else
                    {
                        TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, fanZhongList);
                        pTUser->huPaiInfo.push_back(addItem);
                    }
                }
                else
                {
                    CTableUser* pTPaoUser = FParentTable->FindUserByChairIndex(paoPlace);
                    if (!pTPaoUser->hasTing)
                    {
                        if (i == paoPlace)
                        {
                            if (winnerPlace == FParentTable->m_bankerPlace)
                            {
                                // 判断自己的番种
                                TMJHuPaiInfoItem addItem1(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                pTUser->huPaiInfo.push_back(addItem1);
                                TMJHuPaiInfoItem addItem2(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                pTUser->huPaiInfo.push_back(addItem2);
                                TMJHuPaiInfoItem addItem3(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                pTUser->huPaiInfo.push_back(addItem3);
                            }
                            else
                            {
                                if (i == FParentTable->m_bankerPlace)
                                {
                                    // 判断自己的番种
                                    tmpFanZhongList[mjfzdpZhuangJia] = 1;
                                    TMJHuPaiInfoItem addItem1(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem1);
                                    // 判断其他两人的番种
                                    tmpFanZhongList[mjfzdpZhuangJia] = 0;
                                    TMJHuPaiInfoItem addItem2(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem2);
                                    TMJHuPaiInfoItem addItem3(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem3);
                                }
                                else
                                {
                                    TMJHuPaiInfoItem addItem1(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem1);
                                    // 如果自己不为专家其他两人必有一人为庄，所以其中一个得加上“庄家”，另一个不需要加
                                    TMJHuPaiInfoItem addItem2(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem2);
                                    tmpFanZhongList[mjfzdpZhuangJia] = 1;
                                    TMJHuPaiInfoItem addItem3(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                                    pTUser->huPaiInfo.push_back(addItem3);
                                }
                            }
                        }
                    }
                    else
                    {
                        if (i == FParentTable->m_bankerPlace)
                        {
                            tmpFanZhongList[mjfzdpZhuangJia] = 1;
                            TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                            pTUser->huPaiInfo.push_back(addItem);
                        }
                        else
                        {
                            TMJHuPaiInfoItem addItem(false, isZiMo, winnerPlace, cardId, tmpFanZhongList);
                            pTUser->huPaiInfo.push_back(addItem);
                        }
                    }
                }
            }
        }
    }
	FParentTable->debugTotalScore(); // try
}

/*
针对玩家place，cardId还剩余多少张牌。
去除自己手中的、所有亮出的桌牌、所有亮出的明牌、所有已经胡掉的牌。
*/
int CMJDataMgr::getRemaindCount(int place, int cardId)
{
	int result = 4;
	vector<int> mjCountAry(MJDATA_TYPE_COUNT, 0);
	FMJShouPai->getMJCountAry(place, mjCountAry);
	result -= mjCountAry[cardId];
	result -= FMJZhuoPai->getMJCount(cardId);
	result -= FMJMingPai->getMJCount(cardId);
	for (auto it = FMJHasHuPai.begin(); it != FMJHasHuPai.end(); it++)
	{
		if ((*it) == cardId)
		{
			result--;
		}
	}

	if (result < 0)
	{
		result = 0;
		LogWarning("getRemaindCount", "count error: (%d, %d)", place, cardId);
	}

	return result;
}

/*
	计算输家需要添加的牌型分数， fanZhongList 外围已经做好初始化，这个函数只是改变这个得值
*/
void CMJDataMgr::calcLoserFanZhongInfo(int place, vector<int>& fanZhongList)
{

}

void CMJDataMgr::calcFanZhongInfo(int place, int paoPlace, bool isZiMo, int huType, int lastCardId,
    const vector<int>& allCardCountAry, const vector<int>& shouCardAry, const vector<vector<int>>& shouPaiCard, 
    vector<int>& fanZhongList, const TTableRuleInfo &tableRule)
{
	CTableUser* pTUser = FParentTable->FindUserByChairIndex(place);

	fanZhongList.resize(mjfzCount);
	for (auto it = fanZhongList.begin(); it != fanZhongList.end(); it++)
	{
		(*it) = 0;
	}

    // 哈尔滨玩法
	if (FParentTable->m_tableRule.isHEBorHeiLongJiang == 0)
    {

        if (FLastCardID == FBaoPaiCardID && find(pTUser->willHuCardID.begin(), pTUser->willHuCardID.end(), FBaoPaiCardID) != pTUser->willHuCardID.end() && isZiMo && FParentTable->m_tableRule.isBaoZhongBao)
            fanZhongList[mjfzHuType] = htBaoZhongBao;
        else if (FLastCardID == FBaoPaiCardID && isZiMo)
            fanZhongList[mjfzHuType] = htMoBao;
        else if (FParentTable->m_tableRule.isLaizi && FLastCardID == 31 && isZiMo)
            fanZhongList[mjfzHuType] = htMoHongZhong;
        else if (huType == 7)
            fanZhongList[mjfzHuType] = htKuaDaFeng;
        else
            fanZhongList[mjfzHuType] = htPingHu;

        // 自摸
        if (isZiMo)
        {
            fanZhongList[mjfzZiMo] = 1;
        }
        // 门清加番
        if (tableRule.isMenQingJiaFen)
        {
            if (FMJShouPai->getUserCardCount(place) == 14)
                fanZhongList[mjfzMenQing] = 1;
        }
        //  暗刻
        if (tableRule.isAnKeJiaFen)
        {
            int anKeCount = 0;
            vector<vector<vector<int>>> tempAllZuHeList;
            tempAllZuHeList = g_logic_mgr->getAllZuHeList();
            for (vector<vector<int>> tmpVecVec : tempAllZuHeList)
            {
                bool checkKePai = !FMJMingPai->hasPengGang(place);
                bool  checkShunPai = !FMJMingPai->hasChiPai(place);
                int count = 0;
                for (vector<int> tmpVec : tmpVecVec)
                {
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                        checkShunPai = false;
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                        checkKePai = false;
                }
                if (!checkKePai && !checkShunPai)
                {
                    for (vector<int> tmpVec : tmpVecVec)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                            count++;
                    }
                }
                if (count > anKeCount)
                    anKeCount = count;
            }
            fanZhongList[mjfzAnKe] = anKeCount;
        }
    }
    // 大庆玩法
    else
    {
        if (FLastCardID == FBaoPaiCardID && find(pTUser->willHuCardID.begin(), pTUser->willHuCardID.end(), FBaoPaiCardID) != pTUser->willHuCardID.end() && isZiMo && FParentTable->m_tableRule.isBaoZhongBao)
            fanZhongList[mjfzdpBaoZhongBao] = 1;
        else if (FMJShouPai->getUserCardCount(place) >= 13)
            fanZhongList[mjfzdpMengQing] = 1;
        else if (FLastCardID == FBaoPaiCardID && isZiMo)
            fanZhongList[mjfzdpMoBaoHu] = 1;
        else if (FParentTable->m_tableRule.isLaizi && FLastCardID == 31 && isZiMo)
            fanZhongList[mjfzdpMoBaoHu] = 1;
        else if (isZiMo)
            fanZhongList[mjfzdpZiMoHu] = 1;
        else if (huType == 2 || huType == 3 || huType == 4)
            fanZhongList[mjfzdpJiaHu] = 1;
        else
            fanZhongList[mjfzdpPingHu] = 1;
        // 庄家
        if (place == FParentTable->m_bankerPlace)
            fanZhongList[mjfzdpZhuangJia] = 1;
    }
}


int CMJDataMgr::getMJCountZhuoPaiAndMingPai(int cardId)
{
    return  FMJZhuoPai->getMJCount(cardId) + FMJMingPai->getMJCount(cardId);
}

void CMJDataMgr::procMoBaoPai()
{
    if (FBaoPaiCardID == INVALID_CARD_VALUE)
    {
        if (!FMJDeck->isHuangPai())
        {
            do 
            {
                FBaoPaiCardID = FMJDeck->takePai();
                //FBaoPaiCardID = 14;//trytry
                FMJPaiQiang->moPai();
            } while (!FMJDeck->isHuangPai() && getMJCountZhuoPaiAndMingPai(FBaoPaiCardID) == 3);

            if (FMJDeck->isHuangPai())
            {
                FParentTable->endXingPaiCalcResult();
            }
            for (auto it = FParentTable->m_userList.begin(); it != FParentTable->m_userList.end(); it++)
            {
                int flag = 0;
                CPluto* pu = new CPluto();
                (*pu).Encode(MSGID_CLIENT_G_MO_BAO_NOTIFY) << FMJPaiQiang->m_currMoPaiPlace << FMJPaiQiang->m_cntList[FMJPaiQiang->m_currMoPaiPlace] << flag << FBaoPaiCardID;
                (*pu) << EndPluto;
                FParentTable->SendPlutoToUser(pu, *it);
            }

            LogInfo("CMJDataMgr::procMoBaoPai", "---------FBaoPaiCardID:%s----------", CAPTION_MJName[FBaoPaiCardID].c_str());//try

        }
        else
        {
            FParentTable->endXingPaiCalcResult();
        }
    }
}