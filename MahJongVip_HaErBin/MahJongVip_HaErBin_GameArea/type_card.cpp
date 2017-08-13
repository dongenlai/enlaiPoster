#include "type_card.h"
#include "type_area.h"
#include <algorithm>
#include "logger.h"
#include "util.h"
#include "mjActionMgr.h"


CMJDeck::CMJDeck(){}

CMJDeck::~CMJDeck(){}

void WriteCardsToPluto(vector<int>& cardList, CPluto& u)
{
	uint16_t len = cardList.size();
	u << len;
	for (size_t i = 0; i < len; ++i)
	{
		u << cardList[i];
	}
}

TMJCardSuit getCardSuitByCardTypeId(int cardId)
{
	TMJCardSuit result = mjcsError;
	if (cardId < 27)
		result = TMJCardSuit(1 + cardId / 9);
	else if (cardId < 31)
		result = mjcsWind;
	else if (cardId < 34)
		result = mjcsDragon;
	else if (cardId < 42)
		result = mjcsFlower;

	return result;
}

int cardId2CardValue(int cardId)
{
	int result;
	if (cardId < 9)
		result = cardId - 0 + 1;
	else if (cardId < 18)
		result = cardId - 9 + 1;
	else if (cardId < 27)
		result = cardId - 18 + 1;
	else if (cardId < 31)
		result = cardId - 27 + 1;
	else if (cardId < 34)
		result = cardId - 31 + 1;
	else if (cardId < 42)
		result = cardId - 34 + 1;
	return result;
}

//////////////////////////////////////////////////////////////////////////

void CMJDeck::initADeck()
{
	m_data.clear();
	for (int i = 0; i < 27; i++)
	{
		m_data.push_back(i);
		m_data.push_back(i);
		m_data.push_back(i);
		m_data.push_back(i);
	}
    m_data.push_back(31);
    m_data.push_back(31);
    m_data.push_back(31);
    m_data.push_back(31);
	m_currIdx = 0;

    // shuffer
    int shufferCount = GetRandomRange(1, 100);
    for (int i = 0; i < shufferCount; i++)
    {
        random_shuffle(m_data.begin(), m_data.end());
    }
}

bool CMJDeck::zhuaPai(int cardCnt, vector<int>& outCards)
{
	outCards.clear();
	for (int i = 0; i < cardCnt; i++)
	{
		if (!m_data.empty())
		{
			outCards.push_back(m_data.back());
			m_data.pop_back();
		}
		else
			return false;
	}
	return true;
}

int CMJDeck::takePai()
{
	int result = INVALID_CARD_VALUE;
	if (!m_data.empty())
	{
		result = m_data.back();
		m_data.pop_back();
	}
	return result;
}

int CMJDeck::getLastPai()
{
    int result = INVALID_CARD_VALUE;
    if (!m_data.empty())
    {
        result = m_data.front();
    }
    return result;
}


bool CMJDeck::isHuangPai()
{
	// 108 - 4 * 13 - 1 - X = 53 - X;
	return m_data.empty();
}

void CMJDeck::clearData()
{
	initADeck();
}

//////////////////////////////////////////////////////////////////////////

CMJPaiQiang::CMJPaiQiang()
{
	m_cntList.resize(4);
	m_cntBeginList.resize(4);
}

CMJPaiQiang::~CMJPaiQiang()
{
	m_cntList.clear();
	m_cntBeginList.clear();
}

void CMJPaiQiang::initPaiQiang(int eastPlace)
{
    m_cntBeginList[(0 + eastPlace) % 4] = 14 * 2;
    m_cntBeginList[(1 + eastPlace) % 4] = 14 * 2;
    m_cntBeginList[(2 + eastPlace) % 4] = 14 * 2;
    m_cntBeginList[(3 + eastPlace) % 4] = 14 * 2;
	for (int i = 0; i < 4; i++)
	{
		m_cntList[i] = m_cntBeginList[i];
	}
}

void CMJPaiQiang::beginZhuaPai(int startPlace, int remainderCol)
{
	m_startMoPaiPlace = startPlace;
	//int decCount = 53;
	int decCount = MAX_TABLE_USER_COUNT * 13 + 1;
	int currPlace = startPlace;
	int cnt = m_cntList[startPlace] - remainderCol * 2;
	do 
	{
		m_cntList[currPlace] -= cnt;
		decCount -= cnt;

		if (decCount <= 0)
		{
			break;
		}

		currPlace = (currPlace + 1) % 4;
		cnt = m_cntList[currPlace];
		if (cnt > decCount)
			cnt = decCount;
	} while (decCount > 0);
	m_currMoPaiPlace = currPlace;
}

int CMJPaiQiang::moPai()
{
	if (m_cntList[m_currMoPaiPlace] <= 0)
	{
		m_currMoPaiPlace = (m_currMoPaiPlace + 1) % 4;
	}
	return --m_cntList[m_currMoPaiPlace];
}

void CMJPaiQiang::clearData(int eastPlace)
{
	initPaiQiang(eastPlace);
}

vector<int> CMJPaiQiang::getPaiQiangCnt()
{
	vector<int> result;
	for (auto it = m_cntBeginList.begin(); it != m_cntBeginList.end(); it++)
	{
		result.push_back((*it));
	}
	return result;
}

void CMJPaiQiang::WriteToPluto(CPluto& u)
{
	u << m_startMoPaiPlace << m_currMoPaiPlace;
	uint16_t len = m_cntList.size();
	u << len;
	for (int i = 0; i < len; i++)
	{
		u << m_cntList[i];
	}

	len = m_cntBeginList.size();
	u << len;
	for (int i = 0; i < len; i++)
	{
		u << m_cntBeginList[i];
	}
}

//////////////////////////////////////////////////////////////////////////

CMJZhuoPai::CMJZhuoPai()
{
	m_data.resize(MAX_TABLE_USER_COUNT);
}

CMJZhuoPai::~CMJZhuoPai()
{

}

void CMJZhuoPai::clearData()
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		(*it).clear();
	}
}

void CMJZhuoPai::addCard(int place, int cardId)
{
	if (cardId == MJDATA_CARDID_ERROR)
		return;
	FLastCardID = cardId;
	FLastPlace = place;
	m_data[place].push_back(cardId);
}

bool CMJZhuoPai::delCard(int place, int cardId)
{
	// 从后向前删除
	vector<int>::reverse_iterator it = find(m_data[place].rbegin(), m_data[place].rend(), cardId);
	if (it == m_data[place].rend())
	{
		LogWarning("delCard", "%d, %d", place, cardId);
		return false; 
	} 
	else
	{
		m_data[place].erase((++it).base());
		return true;
	}
}

int CMJZhuoPai::getMJCount(int cardId)
{
	int result = 0;
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		for (auto itt = (*it).begin(); itt != (*it).end(); itt++)
		{
			if (cardId == (*itt))
			{
				result++;
			}
		}
	}
	return result;
}

void CMJZhuoPai::WriteToPluto(CPluto& u)
{
	u << uint16_t(MAX_TABLE_USER_COUNT);
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		uint16_t count = (*it).size();
		u << count;
		for (auto itt = (*it).begin(); itt != (*it).end(); itt++)
		{
			u << (*itt);
		}
	}
}

//////////////////////////////////////////////////////////////////////////

TMJMingPaiItem::TMJMingPaiItem()
{
	rMJAction = mjaError;
}

TMJMingPaiItem::TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId)
{
	rPlace = place;
	rLastPlace = lastPlace;
	rLastCardId = lastCardId;
	rMJAction = mjAction;

	if (mjaPeng == mjAction)
	{
		for (int i = 0; i < 3; i++)
		{
			rAryData.push_back(cardId);
		}
	}
	else if ((mjaDaMingGang == mjAction) || (mjaJiaGang == mjAction) || (mjaAnGang == mjAction))
	{
		for (int i = 0; i < 4; i++)
		{
			rAryData.push_back(cardId);
		}
	}
	else
	{
		LogWarning("TMJMingPaiItem", "error: place: %d, mjAction: %d", place, mjAction);
	}
}

TMJMingPaiItem::TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector)
{
	rPlace = place;
	rLastPlace = lastPlace;
	rLastCardId = lastCardId;
	rMJAction = mjAction;
	rAryData.resize(dataVector.size());
	copy(dataVector.begin(), dataVector.end(), rAryData.begin());
}

TMJMingPaiItem::TMJMingPaiItem(const TMJMingPaiItem& other)
{
	rAryData.resize(other.rAryData.size());
	copy(other.rAryData.begin(), other.rAryData.end(), rAryData.begin());
	rPlace = other.rPlace;
	rMJAction = other.rMJAction;
	rLastCardId = other.rLastCardId;
	rLastPlace = other.rLastPlace;
}

TMJMingPaiItem::~TMJMingPaiItem()
{

}



//////////////////////////////////////////////////////////////////////////


CMJMingPai::CMJMingPai()
{
	m_data.reserve(10);   // 增大容量，省得后续对象移动造成的拷贝构造
}

CMJMingPai::~CMJMingPai()
{
}

void CMJMingPai::clearData()
{
	m_data.clear();
}

bool CMJMingPai::hasPengGangItem(int place, int lastCardId, TMJActionName mjAction)
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && ((*it).rLastCardId == lastCardId) && ((*it).rMJAction == mjAction))
			return true;
	}
	return false;
}

bool CMJMingPai::hasPengGang(int place)
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && (((*it).rMJAction == mjaPeng) || ((*it).rMJAction == mjaDaMingGang) ||
			((*it).rMJAction == mjaJiaGang)))
			return true;
	}
	return false;
}

bool CMJMingPai::hasChiPai(int place)
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && ((*it).rMJAction == mjaChi))
			return true;
	}
	return false;
}

void CMJMingPai::addMingPaiItem(TMJMingPaiItem addItem)
{
	m_data.push_back(addItem);
}

int CMJMingPai::jiaGang(int place, int lastCardId)
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && ((*it).rLastCardId == lastCardId) && ((*it).rMJAction == mjaPeng))
		{
			(*it).rMJAction = mjaJiaGang;
			(*it).rAryData.push_back(lastCardId);
			return (*it).rLastPlace;
		}
	}

	return -1;
}

// 抢杠胡牌时，要把抢杠的牌还原成碰的牌
bool CMJMingPai::mdfJiaGang2Peng(int place, int lastCardId)
{
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && ((*it).rLastCardId == lastCardId) && ((*it).rMJAction == mjaJiaGang))
		{
			(*it).rMJAction = mjaPeng;
			(*it).rAryData.pop_back();
			return true;
		}
	}

	return false;
}

void CMJMingPai::getMJCountAry(int place, vector<int>& countAry)
{
	if (countAry.size() != MJDATA_TYPE_COUNT)
	{
		LogWarning("CMJMingPai::getMJCountAry", "countAry.size error!!");
		return;
	}

	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if ((*it).rPlace == place)
		{
			if (((*it).rMJAction == mjaJiaGang) || ((*it).rMJAction == mjaAnGang) || ((*it).rMJAction == mjaDaMingGang))
			{
				countAry[(*it).rLastCardId] += 4;
			}
			else if (((*it).rMJAction == mjaPeng))
			{
				countAry[(*it).rLastCardId] += 3;
			}
			else if (((*it).rMJAction == mjaChi))
			{
				for (int cardId : (*it).rAryData)
				{
					countAry[cardId]++;
				}
			}
			else
			{
				LogWarning("CMJMingPai::getMJCountAry", "data Error, place: %d, mjAction: %d", place, int((*it).rMJAction));
			}
		}
	}
}

int CMJMingPai::getMJCount(int cardId)
{
	int result = 0;
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rMJAction != mjaChi))
		{
			if ((*it).rLastCardId == cardId)
			{
				if (((*it).rMJAction == mjaJiaGang) || ((*it).rMJAction == mjaAnGang) || ((*it).rMJAction == mjaDaMingGang))
				{
					result += 4;
				}
				else if (((*it).rMJAction == mjaPeng))
				{
					result += 3;
				}
				else
				{
					LogWarning("CMJMingPai::getMJCount", "data Error,  mjAction: %d", int((*it).rMJAction));
				}
			}
		}
		else
		{
			for (int itCardId : (*it).rAryData)
			{
				if (itCardId == cardId)
				{
					result++;
				}
			}
		}
	}

	return result;
}

void CMJMingPai::getMingPaiListByPlace(int place, vector<TMJMingPaiItem>& mingPaiList)
{
	mingPaiList.clear();
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if ((*it).rPlace == place)
		{
			mingPaiList.push_back(TMJMingPaiItem(*it));
		}
	}
}

int CMJMingPai::getMingGangCount(int place)
{
	int result = 0;
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && 
			(((*it).rMJAction == mjaDaMingGang) || ((*it).rMJAction == mjaJiaGang)))
		{
			result++;
		}
	}
	return result;
}

int CMJMingPai::getAnGangCount(int place)
{
	int result = 0;
	for (auto it = m_data.begin(); it != m_data.end(); it++)
	{
		if (((*it).rPlace == place) && ((*it).rMJAction == mjaAnGang))
		{
			result++;
		}
	}
	return result;
}

void CMJMingPai::WriteToPluto(CPluto& u)
{
	u << uint16_t(MAX_TABLE_USER_COUNT);
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		uint16_t count = 0;
		for (auto it = m_data.begin(); it != m_data.end(); it++)
		{
			if ((*it).rPlace == i)
				count++;
		}

		u << count;
		if (count > 0)
		{
			for (auto it = m_data.begin(); it != m_data.end(); it++)
			{
				if ((*it).rPlace == i)
				{
					u << int32_t((*it).rMJAction) << (*it).rLastPlace;
					string tmpStr;
					Vector2Str((*it).rAryData, true, ',', tmpStr);
					u << tmpStr;
				}
			}
		}
	}
}


//////////////////////////////////////////////////////////////////////////

CMJShouPai::CMJShouPai()
{
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		TMJShouPaiItem* newItem = new TMJShouPaiItem();
		m_data.push_back(newItem);
	}
}

CMJShouPai::CMJShouPai(CMJActionMgr* pMJActionMgr)
{
	m_pMJActionMgr = pMJActionMgr;
	for (int i = 0; i < MAX_TABLE_USER_COUNT; i++)
	{
		TMJShouPaiItem* newItem = new TMJShouPaiItem();
		m_data.push_back(newItem);
	}
}

CMJShouPai::~CMJShouPai()
{
	clearData();
	ClearContainer(m_data);
}

void CMJShouPai::clearData()
{
	for (vector<TMJShouPaiItem*>::iterator it = m_data.begin(); it != m_data.end(); it++)
	{
		(*it)->rData.clear();
		(*it)->rLastCardID = MJDATA_CARDID_ERROR;
		(*it)->rBMoPai = false;
		(*it)->rBJinZhang = false;
	}
}

bool CMJShouPai::deleteACard(int APlace, int ACardID)
{
	if ((APlace < 0) || (APlace >= MAX_TABLE_USER_COUNT))
	{
		LogWarning("CMJShouPai::deleteCards", "error place(%d, %d)", APlace, ACardID);
		return false;
	}

	if (ACardID == MJDATA_CARDID_ERROR)
		return false;

	vector<int>::iterator itFind = find(m_data[APlace]->rData.begin(), m_data[APlace]->rData.end(), ACardID);
	if (itFind != m_data[APlace]->rData.end())
	{
		m_data[APlace]->rData.erase(itFind);
		return true;
	}
	else
	{
		string errorMsg;
		Vector2Str(m_data[APlace]->rData, true, ',', errorMsg);
		LogWarning("CMJShouPai::deleteCards", "noCards(%d, %d,  %s)", APlace, ACardID, errorMsg.c_str());
		return false;
	}
}

void CMJShouPai::chiPai(int place, int cardId00, int cardId01)
{
	deleteACard(place, cardId00);
	deleteACard(place, cardId01);
	m_data[place]->rBJinZhang = true;
	m_data[place]->rBMoPai = false;
}

void CMJShouPai::sortMJCard(int APlace)
{
	// 从小到大
	sort(m_data[APlace]->rData.begin(), m_data[APlace]->rData.end());
}

void CMJShouPai::zhuaPai(int place, vector<int>& cardAry)
{
	m_data[place]->rData.clear();
	m_data[place]->rData.resize(cardAry.size());
	if (cardAry.size() == 14)
	{
		m_data[place]->rBMoPai = true;
		m_data[place]->rBJinZhang = true;
		m_data[place]->rLastCardID = cardAry.back();
	}
	else
	{
		m_data[place]->rBMoPai = false;
		m_data[place]->rBJinZhang = false;
		m_data[place]->rLastCardID = MJDATA_CARDID_ERROR;
	}
	copy(cardAry.begin(), cardAry.end(), m_data[place]->rData.begin());
	sortMJCard(place);
}

void CMJShouPai::takePai(int place, int cardId)
{
	m_data[place]->rBMoPai = true;
	m_data[place]->rBJinZhang = true;
	m_data[place]->rLastCardID = cardId;
	m_data[place]->rData.push_back(cardId);
}

void CMJShouPai::chuPai(int place, int cardId)
{
	if (deleteACard(place, cardId))
	{
		m_data[place]->rBMoPai = false;
		m_data[place]->rBJinZhang = false;
		sortMJCard(place);
	}
}

void CMJShouPai::pengGangPai(int place, int cardId, int cardCount)
{
	for (int i = 0; i < cardCount; i++)
		deleteACard(place, cardId);

	// 杠牌时要把手牌列到明牌中,所以没有进张。 碰牌时已经进张
	if (cardCount == 2)
		m_data[place]->rBJinZhang = true;
	else
		m_data[place]->rBJinZhang = false;
}

bool CMJShouPai::swapCards(int place, vector<int>& addCards, vector<int>& delCards)
{
	if (addCards.size() != 3)
	{
		LogWarning("CMJShouPai::swapCards", "addCards.size() != 3");
		return false;
	}
	if (delCards.size() != 3)
	{
		LogWarning("CMJShouPai::swapCards", "delCards.size() != 3");
		return false;
	}

	int successCnt = 0;
	for (int i = 0; i < 3; i++)
	{
		int aCards = delCards[i];
		for (vector<int>::iterator it = m_data[place]->rData.begin(); it != m_data[place]->rData.end(); it++)
		{
			if (*it == aCards)
			{
				*it = addCards[i];
				successCnt++;
				break;
			}
		}
	}

	if (successCnt != 3)
	{
		LogWarning("CMJShouPai::swapCards", "failed");
		return false;
	}

	sortMJCard(place);

	return true;
}

void CMJShouPai::calcSwapCard(int place, vector<int>& cardAry)
{
	// 计算3种花色
	int suitCountAry[3] = { 0, 0, 0 };
	int tmpIdx = 0;
	for (auto it = m_data[place]->rData.begin(); it != m_data[place]->rData.end(); it++)
	{
		tmpIdx = (*it) / 9;
		suitCountAry[tmpIdx] = suitCountAry[tmpIdx] + 1;
	}

	// 从三种花色中找出牌最少的花色，但是至少要有3张牌
	int minIdx = -1;
	int minCount = 100;
	for (int i = 0; i < 3; i++)
	{
		if ((suitCountAry[i] >= 3) && (suitCountAry[i] < minCount))
		{
			minIdx = i;
			minCount = suitCountAry[i];
		}
	}

	if (minIdx < 0)
	{
		string tmpStr;
		Vector2Str(m_data[place]->rData, true, ',', tmpStr);
		LogError("calcSwapCard", "%d 玩家 找不到可以换的牌： %s", place, tmpStr.c_str());
		return;
	}

	// 拿出三张牌
	cardAry.clear();
	for (auto it = m_data[place]->rData.begin(); it != m_data[place]->rData.end(); it++)
	{
		tmpIdx = (*it) / 9;
		if (tmpIdx == minIdx)
		{
			cardAry.push_back((*it));
			if (cardAry.size() == 3)
			{
				break;
			}
		}
	}
}

TMJCardSuit CMJShouPai::calcSelDelSuit(int place)
{
	// todo 智能
	return mjcsCharacter;
}

void CMJShouPai::doStop()
{

}

void CMJShouPai::WriteToPluto(int place, CPluto& u)
{
	if ((place < 0) || (place >= MAX_TABLE_USER_COUNT))
	{
		LogWarning("CMJShouPai::WriteToPluto", "error place(%d)", place);
		return;
	}

	TMJShouPaiItem* shouItem = m_data[place];
	WriteCardsToPluto(shouItem->rData, u);
	//u << shouItem->rLastCardID << int(shouItem->rBJinZhang) << int(shouItem->rBMoPai);
}

vector<int>& CMJShouPai::getUserCardList(int place)
{
	return m_data[place]->rData;
}

int CMJShouPai::getUserCardCount(int place)
{
	return m_data[place]->rData.size();
}

bool CMJShouPai::hasCard(int place, int cardId) const
{
	return find(m_data[place]->rData.begin(), m_data[place]->rData.end(), cardId) != m_data[place]->rData.end();
}

int CMJShouPai::cardCount(int place, int cardId) const
{
	return count(m_data[place]->rData.begin(), m_data[place]->rData.end(), cardId);
}

bool CMJShouPai::isJinZhang(int place)
{
	return m_data[place]->rBJinZhang;
}

/*
   countAry: 要在外部初始化好！！
*/
void CMJShouPai::getMJCountAry(int place, vector<int>& countAry)
{
	if (countAry.size() != MJDATA_TYPE_COUNT)
	{
		LogWarning("CMJShouPai::getMJCountAry", "countAry.size error!!"); 
		return;
	}
	for (auto it = m_data[place]->rData.begin(); it != m_data[place]->rData.end(); it++)
		countAry[(*it)]++;
}


//////////////////////////////////////////////////////////////////////////

TMJSpecialGangItem::TMJSpecialGangItem()
{

}

TMJSpecialGangItem::~TMJSpecialGangItem()
{
	dataVec.clear();
}

TMJSpecialGangItem::TMJSpecialGangItem(const TMJSpecialGangItem& other)
{
	gangFlag = other.gangFlag;
	dataVec = other.dataVec;
}

TMJSpecialGangItem::TMJSpecialGangItem(int aGangFlag, const vector<int>& aVec)
{
	gangFlag = aGangFlag;
	dataVec = aVec;
}