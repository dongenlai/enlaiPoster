
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
	// �ȷ�����ڴ棬ʡ�ĺ���Ƶ�����롢�ͷ�
	// ע�⣺ vector �� popback, clear �����������ڴ�(capacity ������С)
	m_calcZuHeList.reserve(5);
	// �����7������
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
	cardCountList: ���Ƶ��������飬������cardId, ֵ�Ǹ���
	hasJiang�� �Ƿ񺬽���
	retZuHeList�� �Ѿ��õ��������б�
	ע�⣺��Ϊ���� �˲�Ѫս�齫��˵��ֻ����������ƽ�����ֲ�����ƣ���������������ƽ�������ԣ��ȵݹ�����ƣ����ȼ��������
	     �������������齫����������齫���� ����ֻ�жϳ��ܺ������£�Ҫ�����п��ܵõ��ĺ�����ϵݹ�������Ա�������㷬�������ֵ��
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
	// �����������γ�5���ƣ�����5����϶����ܺ����ˡ�
	if (retZuHeList.size() >= 5)
		return false;
	// û�����ˣ�ֱ�ӷ���ʧ��
	if (hasNull)
		return false;
	for (size_t i = 0; i < cardCountList.size(); i++)
	{
		// ���� �� �ȼ����ƣ���Ϊ�����ȼ��������
		if (cardCountList[i] >= 3)
		{
			cardCountList[i] -= 3;
			retZuHeList.push_back(vector<int>(3, i));
			// ! ���ڹ����齫�ȣ����� return��Ҫ�ݹ�����п��ܵĺ�������
			if (checkCommHuPai(cardCountList, hasJiang, retZuHeList))
				return true;
			retZuHeList.pop_back();
			cardCountList[i] += 3;
		}

		// ����
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

		// ˳��
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
	shouPaiCard: ���Ƶĳ������
	mingPaiCard�� ���Ƶĳ������
	lastCardId�� ���������һ���ƻ��ߴ��ڵ�����
	isZimo�� �Ƿ�������
	isQiangGang�� �Ƿ�������
	hasGang�� �Ƿ��и��ƣ� ���Ͽ���
*/
void CMJLogicMgr::calcFanZhong(const vector<vector<int>>& shouPaiCard, 
	const vector<TMJMingPaiItem>& mingPaiCard,
	bool isZimo, vector<int>& retVec)
{
	// �� �� �� ����
	int suitCountAry[3] = {0, 0, 0};
	// ˳������ 123 �ĸ���
	int shunZiCount = 0;
	// �Ƿ��д����ܡ����� ��������
	int hasPengGang = false;  
	// ���ܸ���
	int mingGangCount = 0;
	// ���ܸ���
	int anGangCount = 0;

	// ---begin �������� --
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
	// ---end �������� --

	// ��һɫ
	if (suitCount == 1)
		retVec[0] = 1;
	// ������
	if (shunZiCount <= 0)
		retVec[1] = 1;
	// ƽ��
	if ((retVec[0] == 0) && (retVec[1] == 0))
		retVec[2] = 1;
	// ��ǰ��
	if (isZimo && !hasPengGang)
		retVec[3] = 1;
	retVec[4] = mingGangCount;
	retVec[5] = anGangCount;
}