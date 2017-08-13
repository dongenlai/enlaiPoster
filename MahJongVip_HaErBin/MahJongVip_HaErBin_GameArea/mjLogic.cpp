
#include "mjLogic.h"
#include <iostream>
#include <ostream>
#include "global_var.h"

TMJFanZhongItem::TMJFanZhongItem()
{
	id = -1;
}

TMJFanZhongItem::TMJFanZhongItem(const TMJFanZhongItem& other)
{
	id = other.id;
	point = other.point;
	name = other.name;
}

TMJFanZhongItem::TMJFanZhongItem(int aId, int aPoint, const string& aName)
{
	id = aId;
	point = aPoint;
	name = aName;
}

//////////////////////////////////////////////////////////////////////////

TMJHuPaiInfoItem::TMJHuPaiInfoItem()
{

}

TMJHuPaiInfoItem::TMJHuPaiInfoItem(const TMJHuPaiInfoItem& other)
{
	isWinner = other.isWinner;
	isZiMo = other.isZiMo;
	dianPaoPlace = other.dianPaoPlace;
	lastCardId = other.lastCardId;
	scores = other.scores;
	fanZhongList.resize(other.fanZhongList.size());
	copy(other.fanZhongList.begin(), other.fanZhongList.end(), fanZhongList.begin());
}

TMJHuPaiInfoItem::TMJHuPaiInfoItem(bool aisWinner, bool aIsZimo, int aDianPaoPlace, int aLastCardId, const vector<int>& aFanZhongList)
{
	isWinner = aisWinner;
	isZiMo = aIsZimo;
	dianPaoPlace = aDianPaoPlace;
	lastCardId = aLastCardId;
	fanZhongList.resize(aFanZhongList.size());
	copy(aFanZhongList.begin(), aFanZhongList.end(), fanZhongList.begin());
}

void TMJHuPaiInfoItem::calcScores(int hebORdq)
{
    scores = g_logic_mgr->calcScores(fanZhongList,hebORdq);
}

///////////////////////////////////////////////////////////////////////////

TMJTingPaiInfoItem::TMJTingPaiInfoItem()
{

}

TMJTingPaiInfoItem::TMJTingPaiInfoItem(const TMJTingPaiInfoItem& other)
{
	huCardId = other.huCardId;
	huFan = other.huFan;
}

TMJTingPaiInfoItem::TMJTingPaiInfoItem(int aHuCardId, int aHuFan)
{
	huCardId = aHuCardId;
	huFan = aHuFan;
}


//////////////////////////////////////////////////////////////////////////

CMJLogicMgr::CMJLogicMgr()
{
	// 先分配好内存，省的后期频繁申请、释放
	// 注意： vector 的 popback, clear 并不会销毁内存(capacity 不会缩小)
	m_calcZuHeList.reserve(5);
	m_calcFanZhong.reserve(mjfzCount);

    // 哈尔滨玩法
	m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzHuType, 1, "基本胡"));

    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzBaoTing, 1, "上听"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzDianPao, 1, "点炮"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzKaiMen, 1, "开门"));

    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzZiMo, 1, "自摸"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzMenQing, 1, "门清"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzAnKe, 1, "暗刻"));

    // 大庆玩法
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpPingHu, 1, "平胡"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpJiaHu, 2, "夹胡"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpZiMoHu, 8, "自摸"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpMoBaoHu, 16, "摸宝"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpMengQing, 32, "门清"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpBaoZhongBao, 64, "宝中宝"));
    m_fanZhongConfigList.push_back(TMJFanZhongItem(mjfzdpZhuangJia, 1, "庄家"));

    m_calcHuType.clear();
    // 哈尔滨玩法
    m_calcHuType.push_back(1);
    m_calcHuType.push_back(3);
    m_calcHuType.push_back(3);
    m_calcHuType.push_back(3);
    m_calcHuType.push_back(6);

    if (m_calcHuType.size() != htCount)
    {
        LogWarning("错了", "！！！！！！胡牌类型不对！！！！");
    }
    if (m_fanZhongConfigList.size() != mjfzCount)
    {
        LogWarning("错了", "！！！！！！胡牌番数不对！！！！");
    }
}

CMJLogicMgr::~CMJLogicMgr()
{
}



int CMJLogicMgr::calcScores(const vector<int>& fanZhongInfoVec,int hebORdq)
{
    // 哈尔滨玩法
    if (hebORdq == 0)
    {
        // 计算胡牌类型
        int huType = fanZhongInfoVec[mjfzHuType];
        int scores = m_calcHuType.at(huType);

        // 计算点炮开门门立
        if (scores == 1 && fanZhongInfoVec[mjfzDianPao] == 1 && fanZhongInfoVec[mjfzBaoTing]==0)
        {
            scores = 3;
        }
        else if (scores == 1 && fanZhongInfoVec[mjfzKaiMen] == 0 && fanZhongInfoVec[mjfzBaoTing] == 0)
        {
            scores = 3;
        }
        else if (scores == 1 && fanZhongInfoVec[mjfzZiMo] == 1 && fanZhongInfoVec[mjfzKaiMen] == 1)
        {
            scores = 2;
        }

        // 计算门清暗刻
        int fanCount = 0;
        for (int i = 5; i <= (mjfzCount - 1); i++)
        {
            if (fanZhongInfoVec[i] > 0)
            {
                fanCount += fanZhongInfoVec[i];
            }
        }
        for (int i = 0; i < fanCount; i++)
            scores = scores * 2;

        return scores;
    }
    // 大庆玩法
    else
    {
        int scores = 0;
        for (int i = 0; i < (mjfzCount - 1); i++)
        {
            if (fanZhongInfoVec[i] > 0)
            {
                scores += m_fanZhongConfigList[i].point;
            }
        }
        if (fanZhongInfoVec[mjfzCount - 1] > 0)
        {
            scores *= 2;
        }
        return scores;
    }
}

bool CMJLogicMgr::hasDelSuitCard(TMJCardSuit delSuit, const vector<int>& cardCountList)
{
	if (delSuit == mjcsError)
	{
		// 没有定缺
		return false;
	}

	int startIdx = (delSuit - 1) * 9;
	for (int i = 0; i < 9; i++)
	{
		if (cardCountList[i + startIdx] > 0)
			return true;
	}
	return false;
}

bool CMJLogicMgr::isPengPengHu(const vector<int>& cardCountList)
{
	bool hasJiang = false;
	for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
	{
		if (cardCountList[i] > 0)
		{
			if (2 == cardCountList[i])
			{
				if (hasJiang)
					return false;
				hasJiang = true;
			}
			else if (3 != cardCountList[i])
				return false;
		}
	}
	return true;
}

bool CMJLogicMgr::isTingPengPeng(const vector<int>& cardCountList)
{
	// 是否是碰碰胡的听牌
	bool hasJiang = false;
	for (int i = 0; i < MJDATA_TYPE_COUNT; i++)
	{
		if (cardCountList[i] > 0)
		{
			if (1 == cardCountList[i])
			{
				if (hasJiang)
					return false;
				hasJiang = true;
			}
			else if (3 != cardCountList[i])
				return false;
		}
	}
	return true;
}

/*
checkKePai: 是否检测含有刻牌（三张一样的）
checkShunPai: 是否检测含有顺牌
0: 不胡牌
1： 普通胡牌
*/
int CMJLogicMgr::isHuPai(const bool checkKePai, const  bool checkShunPai, const vector<int>& cardCountList, TTableRuleInfo &tableRule, int cardID, int GuaDaFengCardID, bool isGuaDaFeng)
{
	for (auto i = m_calcZuHeList.begin(); i != m_calcZuHeList.end(); i++)
	{
		(*i).clear();
	}
	m_calcZuHeList.clear();
	m_allZuHeList.clear();

	m_runCount = 0;
	vector<int> tmpAry = cardCountList;

    checkCommHuPai(tmpAry, false, m_calcZuHeList);

	if (m_allZuHeList.size() > 0)
	{
        // 对倒胡
        if (tableRule.isZhiDuiJia)
        {
            for (vector<vector<int>> tmpVecVec : m_allZuHeList)
            {
                bool kePai = checkKePai;
                bool shunPai = checkShunPai;
                bool isZhiDuiHu = false;

                bool guaFeng = true;
                if (isGuaDaFeng)
                    guaFeng = false;

                for (vector<int> tmpVec : tmpVecVec)
                {
                    if (kePai || shunPai)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                            shunPai = false;
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                            kePai = false;
                    }
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == cardID))
                        isZhiDuiHu = true;
                    if (isGuaDaFeng)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == GuaDaFengCardID))
                            guaFeng = true;
                    }
                }
                if (!kePai && !shunPai && isZhiDuiHu && guaFeng)
                    return 5;
            }
        }
        //单吊夹
        if (tableRule.isDanDiaoJia)
        {
            for (vector<vector<int>> tmpVecVec : m_allZuHeList)
            {
                bool kePai = checkKePai;
                bool shunPai = checkShunPai;
                bool isDanDiaoJia = false;

                bool guaFeng = true;
                if (isGuaDaFeng)
                    guaFeng = false;

                for (vector<int> tmpVec : tmpVecVec)
                {
                    if (kePai || shunPai)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                            shunPai = false;
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                            kePai = false;
                    }
                    if ((tmpVec.size() == 2) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(0) == cardID))
                        isDanDiaoJia = true;
                    if (isGuaDaFeng)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == GuaDaFengCardID))
                            guaFeng = true;
                    }
                }
                if (!kePai && !shunPai && isDanDiaoJia && guaFeng)
                    return 4;
            }
        }
        //三七夹
        if (tableRule.isSanQiJia)
        {
            for (vector<vector<int>> tmpVecVec : m_allZuHeList)
            {
                bool kePai = checkKePai;
                bool shunPai = checkShunPai;
                bool isSanQiJia= false;

                bool guaFeng = true;
                if (isGuaDaFeng)
                    guaFeng = false;

                for (vector<int> tmpVec : tmpVecVec)
                {
                    if (kePai || shunPai)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                            shunPai = false;
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                            kePai = false;
                    }
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                    {
                        if ((tmpVec.at(2) == cardID && cardId2CardValue(cardID) == 3) || (tmpVec.at(0) == cardID && cardId2CardValue(cardID) == 7))
                            isSanQiJia = true;
                    }
                    if (isGuaDaFeng)
                    {
                        if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == GuaDaFengCardID))
                            guaFeng = true;
                    }
                }
                if (!kePai && !shunPai && isSanQiJia && guaFeng)
                    return 3;
            }
        }
        // 夹胡
        for (vector<vector<int>> tmpVecVec : m_allZuHeList)
        {
            bool kePai = checkKePai;
            bool shunPai = checkShunPai;
            bool isJiaHu = false;

            bool guaFeng = true;
            if (isGuaDaFeng)
                guaFeng = false;

            for (vector<int> tmpVec : tmpVecVec)
            {
                if (kePai || shunPai)
                {
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                        shunPai = false;
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                        kePai = false;
                }
                if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                {
                    if (tmpVec.at(1) == cardID)
                    {
                        isJiaHu = true;
                    }
                }
                if (isGuaDaFeng)
                {
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == GuaDaFengCardID))
                        guaFeng = true;
                }
            }
            if (!kePai && !shunPai && isJiaHu && guaFeng)
                return 2;
        }
        // 屁胡
        for (vector<vector<int>> tmpVecVec : m_allZuHeList)
        {
            bool kePai = checkKePai;
            bool shunPai = checkShunPai;

            bool guaFeng = true;
            if (isGuaDaFeng)
                guaFeng = false;

            for (vector<int> tmpVec : tmpVecVec)
            {
                if (kePai || shunPai)
                {
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) != tmpVec.at(1)))
                        shunPai = false;
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)))
                        kePai = false;
                }
                if (isGuaDaFeng)
                {
                    if ((tmpVec.size() == 3) && (tmpVec.at(0) == tmpVec.at(1)) && (tmpVec.at(1) == tmpVec.at(2)) && (tmpVec.at(1) == GuaDaFengCardID))
                        guaFeng = true;
                }
            }
            if (!kePai && !shunPai && guaFeng)
                return 1;
        }
        return 0;
	}
	else
		return 0;
}

void CMJLogicMgr::getZuHeList(vector<vector<int>>& retVecVec)
{
	for (auto i = m_calcZuHeList.begin(); i != m_calcZuHeList.end(); i++)
	{
		retVecVec.push_back(vector<int>((*i).begin(), (*i).end()));
	}
}

bool CMJLogicMgr::isNullPai(const vector<int>& cardCountList)
{
	vector<int> nullVector(cardCountList.size(), 0);
	return std::equal(cardCountList.begin(), cardCountList.end(), nullVector.begin());
}

/*
	cardCountList: 手牌的牌数数组，索引是cardId, 值是个数
	hasJiang： 是否含将牌
	retZuHeList： 已经得到的牌组列表
	注意：因为对于 宜昌血战麻将来说，只有碰碰胡和平胡两种差异胡牌，不是碰碰胡就是平胡，所以，先递归检测刻牌，优先检测碰碰胡
	     对于其他类型麻将（比如国标麻将）， 不能只判断出能胡牌完事，要把所有可能得到的胡牌组合递归出来，以便后续计算番种找最大值！
*/
bool CMJLogicMgr::checkCommHuPai(vector<int>& cardCountList, bool hasJiang, vector<vector<int>>& retZuHeList)
{
 	m_runCount++;
//   	std::cout << "run: " << m_runCount << " |  ";
//   	for (auto it = retZuHeList.begin(); it != retZuHeList.end(); it++)
//   	{
//   		for (auto itt = (*it).begin(); itt != (*it).end(); itt++)
//   		{
//   			std::cout << (*itt) << ",";
//   		}
//   		std::cout << "  | ";
//   	}
//   	std::cout << std::endl;

	bool hasNull = isNullPai(cardCountList);
    if (hasJiang && hasNull)
    {
        m_allZuHeList.push_back(retZuHeList);
        return true;
    }

	// 手牌中最多可形成5套牌，多于5套则肯定不能胡牌了。
	if (retZuHeList.size() >= 5)
		return false;
	// 没有牌了，直接返回失败
	if (hasNull)
		return false;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		// 刻牌 ， 先检测刻牌，是为了优先检测碰碰胡
		if (cardCountList[i] >= 3)
		{
			cardCountList[i] -= 3;
			retZuHeList.push_back(vector<int>(3, i));
			checkCommHuPai(cardCountList, hasJiang, retZuHeList);
			retZuHeList.pop_back();
			cardCountList[i] += 3;
		}

		// 将牌
		if (!hasJiang && (cardCountList[i] >= 2))
		{
			cardCountList[i] -= 2;
			retZuHeList.push_back(vector<int>(2, i));
			checkCommHuPai(cardCountList, true, retZuHeList);
			retZuHeList.pop_back();
			cardCountList[i] += 2;
		}

		if (i > 24)
			continue;

		// 顺牌
		if ((i % 9 <= 6) && (cardCountList[i + 0] > 0) && (cardCountList[i+ 1] > 0) && 
			(cardCountList[i + 2] > 0))
		{
			cardCountList[i + 0] -= 1;
			cardCountList[i + 1] -= 1;
			cardCountList[i + 2] -= 1;
			size_t tmpV[3] = {i, i+1, i+2};
			retZuHeList.push_back(vector<int>(tmpV, tmpV+3));
			checkCommHuPai(cardCountList, hasJiang, retZuHeList);
			retZuHeList.pop_back();
			cardCountList[i + 0] += 1;
			cardCountList[i + 1] += 1;
			cardCountList[i + 2] += 1;
		}

		// 无处可用的牌，必然无法胡牌了。
		if (cardCountList[i] > 0)
			return false;
	}
	return false;
}

bool CMJLogicMgr::checkCommHuPaiWithLaiZi(int laiZiCount, vector<int>& cardCountList, bool hasJiang, vector<vector<int>>& retZuHeList)
{
    m_runCount++;
    bool hasNull = isNullPai(cardCountList);
    if (hasNull)
    {
        if (((laiZiCount <= 0) && (hasJiang)) ||      // 没有癞子
            ((!hasJiang) && (laiZiCount == 2)) ||     // 癞子做将
            (hasJiang && (laiZiCount == 3)))	      // 癞子做刻牌		
        {
            m_allZuHeList.push_back(retZuHeList);
            return true;
        }
    }
    // 手牌中最多可形成5套牌，多于5套则肯定不能胡牌了。
    if (retZuHeList.size() >= 5)
        return false;
    // 没有牌了，直接返回失败
    if (hasNull)
        return false;
    for (size_t i = 0; i < cardCountList.size(); i++)
    {
        int cardCount = cardCountList[i];

        // 刻牌 
        if ((cardCount + laiZiCount) >= 3)
        {
            if (cardCount < 3)
            {
                laiZiCount -= 3 - cardCount;
                cardCountList[i] = 0;
            }
            else
            {
                cardCountList[i] -= 3;
            }
            retZuHeList.push_back(vector<int>(3, i));
            // ! 对于国标麻将等，不能 return，要递归出所有可能的胡牌牌组
            if (checkCommHuPaiWithLaiZi(laiZiCount, cardCountList, hasJiang, retZuHeList))
                return true;
            retZuHeList.pop_back();
            if (cardCount < 3)
            {
                laiZiCount += 3 - cardCount;
                cardCountList[i] = cardCount;
            }
            else
            {
                cardCountList[i] += 3;
            }
        }

        // 将牌
        if (!hasJiang && ((cardCountList[i] > 0) && (cardCountList[i] + laiZiCount) >= 2))
        {
            {
                vector<int> tmpVec;
                if (cardCount < 2)
                {
                    laiZiCount -= 2 - cardCount;
                    cardCountList[i] = 0;
                }
                else
                {
                    cardCountList[i] -= 2;
                }
                tmpVec.push_back(i);
                tmpVec.push_back(i);
                retZuHeList.push_back(tmpVec);
                if (checkCommHuPaiWithLaiZi(laiZiCount, cardCountList, true, retZuHeList))
                    return true;
                retZuHeList.pop_back();
                if (cardCount < 2)
                {
                    laiZiCount += 2 - cardCount;
                    cardCountList[i] = cardCount;
                }
                else
                {
                    cardCountList[i] += 2;
                }
            }
        }

        // 中发白可以参与顺牌
        if ((i > 24))
            continue;

        // 顺牌
        if ((i % 9 > 6))
            continue;
        int replaceAry[3]{0, 0, 0};
        if (laiZiCount <= 0)
        {
            if ((cardCountList[i + 0] <= 0) || (cardCountList[i + 1] <= 0) ||
                (cardCountList[i + 2] <= 0))
                continue;
        }
        else
        {
            int tmpLaiZiCount = laiZiCount;
            for (int j = 0; j < 3; j++)
            {
                if (cardCountList[i + j] <= 0)
                {
                    tmpLaiZiCount--;
                    replaceAry[j] = 1;
                }
            }
            if (tmpLaiZiCount < 0)
                continue;

            for (int j = 0; j < 3; j++)
            {
                if (replaceAry[j] > 0)
                {
                    cardCountList[i + j] = 1;
                    laiZiCount--;
                }
            }
        }
        {
            cardCountList[i + 0] -= 1;
            cardCountList[i + 1] -= 1;
            cardCountList[i + 2] -= 1;
            size_t tmpV[3] = { i, i + 1, i + 2 };
            retZuHeList.push_back(vector<int>(tmpV, tmpV + 3));
            if (checkCommHuPaiWithLaiZi(laiZiCount, cardCountList, hasJiang, retZuHeList))
                return true;
            retZuHeList.pop_back();
            cardCountList[i + 0] += 1;
            cardCountList[i + 1] += 1;
            cardCountList[i + 2] += 1;
        }
        // 还原
        for (int j = 0; j < 3; j++)
        {
            if (replaceAry[j] > 0)
            {
                cardCountList[i + j] = 0;
                laiZiCount++;
            }
        }

        // 无处可用的牌，必然无法胡牌了。
        if (cardCountList[i] > 0)
            return false;
    }
    return false;
}

bool CMJLogicMgr::checkQiDuiHuPai(const vector<int>& cardCountList)
{
	int sumCount = 0;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		if (cardCountList[i] <= 0)
			continue;
		if ((cardCountList[i] != 2) && (cardCountList[i] != 4))
			return false;

		sumCount += cardCountList[i];
	}

	if (sumCount != 14)
		return false;

	return true;
}

bool CMJLogicMgr::checkTingQiDuiHuPai(const vector<int>& cardCountList, bool& retIsHaoHua)
{
	int sumCount = 0;
	int singleCount = 0;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		if (cardCountList[i] <= 0)
			continue;
		if ((cardCountList[i] != 2) && (cardCountList[i] != 4))
		{
			if (singleCount > 0)
				return false;
			singleCount++;
			if (cardCountList[i] == 3)
				retIsHaoHua = true;
		}
		sumCount += cardCountList[i];
	}

	if (sumCount != 13)
		return false;
	if (singleCount != 1)
		return false;

	return true;
}


void CMJLogicMgr::getMaxFanZhong(bool isCheckBianKaDiao, bool isZimo, int lastCardId, vector<int>& retVec)
{
	retVec.resize(m_fanZhongConfigList.size());
	for (auto it = retVec.begin(); it != retVec.end(); it++)
	{
		(*it) = 0;
	}


	if (isCheckBianKaDiao)
	{
		int maxFan = 0;

		vector<int> maxFanZhong = retVec;
		for (vector<vector<int>> tmpVecVec : m_allZuHeList)
		{
			int currFan = 0;
			vector<int> tmpFanZhong = retVec;
			for (vector<int> tmpVec : tmpVecVec)
			{
				
			}

			if (currFan > 0)
			{
				retVec = tmpFanZhong;
				return;
			}
		}
	}
}

int CMJLogicMgr::getMenSuitCount(const vector<int>& cardCountList)
{
	// 万 饼 条 个数
	int suitCountAry[3] = { 0, 0, 0 };
	int tmpIdx = 0;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		if (i >= 27)
			continue;
		if (cardCountList[i] > 0)
		{
			tmpIdx = i / 9;
			suitCountAry[tmpIdx] = suitCountAry[tmpIdx] + 1;
		}
	}

	int suitCount = 0;
	for (int i = 0; i < 3; i++)
	{
		if (suitCountAry[i] > 0)
			suitCount++;
	}

	return suitCount;
}

int CMJLogicMgr::getSuitCout(const vector<int>& cardCountList)
{
	int suitCountAry[5] = { 0, 0, 0, 0, 0 };
	int tmpIdx = 0;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		if (cardCountList[i] > 0)
		{
			tmpIdx = getCardSuitByCardTypeId(i) - 1;
			suitCountAry[tmpIdx] = suitCountAry[tmpIdx] + 1;
		}
	}

	int suitCount = 0;
	for (int i = 0; i < 5; i++)
	{
		if (suitCountAry[i] > 0)
			suitCount++;
	}

	return suitCount;
}

bool CMJLogicMgr::hasYaoJiuCard(const vector<int>& cardCountList)
{
	if ((cardCountList[0] > 0) || (cardCountList[8] > 0) ||
		(cardCountList[9] > 0) || (cardCountList[17] > 0) ||
        (cardCountList[18] > 0) || (cardCountList[26] > 0) || (cardCountList[31] > 0))
		return true;
	return false;
}

