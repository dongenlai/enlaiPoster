
#include "stdafx.h"
#include "mjLogic.h"
#include <iostream>
#include <ostream>

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


CMJLogicMgr::CMJLogicMgr()
{
	// 先分配好内存，省的后期频繁申请、释放
	// 注意： vector 的 popback, clear 并不会销毁内存(capacity 不会缩小)
	m_calcZuHeList.reserve(5);
	// 最多有7个番种
	m_calcFanZhong.reserve(7);

	
}

CMJLogicMgr::~CMJLogicMgr()
{
}

bool CMJLogicMgr::isHuPai(const vector<int>& cardCountList)
{
	for (auto i = m_calcZuHeList.begin(); i != m_calcZuHeList.end(); i++)
	{
		(*i).clear();
	}
	m_calcZuHeList.clear();

	m_runCount = 0;
	vector<int> tmpAry = cardCountList;
	return checkCommHuPai(tmpAry, false, m_calcZuHeList);
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
		return true;
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
			// ! 对于国标麻将等，不能 return，要递归出所有可能的胡牌牌组
			if (checkCommHuPai(cardCountList, hasJiang, retZuHeList))
				return true;
			retZuHeList.pop_back();
			cardCountList[i] += 3;
		}

		// 将牌
		if (!hasJiang && (cardCountList[i] >= 2))
		{
			cardCountList[i] -= 2;
			retZuHeList.push_back(vector<int>(2, i));
			if (checkCommHuPai(cardCountList, true, retZuHeList))
				return true;
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
			int tmpV[3] = {i, i+1, i+2};
			retZuHeList.push_back(vector<int>(tmpV, tmpV+3));
			if (checkCommHuPai(cardCountList, hasJiang, retZuHeList))
				return true;
			retZuHeList.pop_back();
			cardCountList[i + 0] += 1;
			cardCountList[i + 1] += 1;
			cardCountList[i + 2] += 1;
		}

  		if (cardCountList[i] > 0)
  			return false;
	}
	return false;
}


/*
	shouPaiCard: 手牌的成套组合
	mingPaiCard： 明牌的成套组合
	lastCardId： 自摸的最后一张牌或者打炮的炮牌
	isZimo： 是否是自摸
	isQiangGang： 是否是抢杠
	hasGang： 是否有杠牌， 杠上开花
*/
void CMJLogicMgr::calcFanZhong(const vector<vector<int>>& shouPaiCard, 
	const vector<TMJMingPaiItem>& mingPaiCard,
	bool isZimo, vector<int>& retVec)
{
	// 万 饼 条 个数
	int suitCountAry[3] = {0, 0, 0};
	// 顺子牌型 123 的个数
	int shunZiCount = 0;
	// 是否有大明杠、碰， 不含暗杠
	int hasPengGang = false;  
	// 明杠个数
	int mingGangCount = 0;
	// 暗杠个数
	int anGangCount = 0;

	// ---begin 分析牌型 --
	int tmpIdx;
	for (auto it = shouPaiCard.begin(); it != shouPaiCard.end(); it++)
	{
		for (auto itt = (*it).begin(); itt != (*it).end(); itt++)
		{
			tmpIdx = *itt / 9;
			suitCountAry[tmpIdx] = suitCountAry[tmpIdx] + 1;
		}
		if (((*it).size() == 3) && ((*it)[0] != (*it)[1]))
			shunZiCount++;
	}
	for (auto it = mingPaiCard.begin(); it != mingPaiCard.end(); it++)
	{
		TMJMingPaiItem mingPaitItem = (*it);
		if (mingPaitItem.rMJAction == mjaAnGang)
			anGangCount++;
		else
		{
			hasPengGang = true;
			if ((mingPaitItem.rMJAction == mjaJiaGang) || (mingPaitItem.rMJAction == mjaDaMingGang))
				mingGangCount++;
		}
		for (auto itt = mingPaitItem.rAryData.begin(); itt != mingPaitItem.rAryData.end(); itt++)
		{
			tmpIdx = *itt / 9;
			++suitCountAry[tmpIdx];
		}
	}
	int suitCount = 0;
	for (int i = 0; i < 3; i++)
	{
		if (suitCountAry[i] > 0)
			suitCount++;
	}
	// ---end 分析牌型 --

	// 清一色
	if (suitCount == 1)
		retVec[0] = 1;
	// 碰碰胡
	if (shunZiCount <= 0)
		retVec[1] = 1;
	// 平胡
	if ((retVec[0] == 0) && (retVec[1] == 0))
		retVec[2] = 1;
	// 门前清
	if (isZimo && !hasPengGang)
		retVec[3] = 1;
	retVec[4] = mingGangCount;
	retVec[5] = anGangCount;
}