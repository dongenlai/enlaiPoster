#ifndef __TYPE__CARD__HEAD__
#define __TYPE__CARD__HEAD__

#include <vector>
#include <string>
#include "pluto.h"
#include "mjTypeDefine.h"

using std::vector;
using std::string;

void WriteCardsToPluto(vector<int>& cardList, CPluto& u);
TMJCardSuit getCardSuitByCardTypeId(int cardId);
int cardId2CardValue(int cardId);

//////////////////////////////////////////////////////////////////////////

// 一副麻将牌
class CMJDeck
{
public:
	CMJDeck();
	~CMJDeck();

	void clearData();

	bool zhuaPai(int cardCnt, vector<int>& outCards);
	int takePai();
    int getLastPai();
	bool isHuangPai();
protected:
private:
	vector<int> m_data;
	int m_currIdx;

	void initADeck();
};

//////////////////////////////////////////////////////////////////////////

// 牌墙
class CMJPaiQiang
{
public:
	CMJPaiQiang();
	~CMJPaiQiang();

	void clearData(int eastPlace);
	void WriteToPluto(CPluto& u);
	vector<int> getPaiQiangCnt();

	void beginZhuaPai(int startPlace, int remainderCol);
	int moPai();
protected:
private:
	vector<int> m_cntList;       // 剩余数量
	vector<int> m_cntBeginList;  // 牌墙开始数量
	int m_startMoPaiPlace;
	int m_currMoPaiPlace;

	friend class CMJDataMgr;

	void initPaiQiang(int eastPlace);
};

//////////////////////////////////////////////////////////////////////////

// 桌牌
class CMJZhuoPai
{
public:
	CMJZhuoPai();
	~CMJZhuoPai();

	void clearData();
	void addCard(int place, int cardId);
	bool delCard(int place, int cardId);

	int getMJCount(int cardId);
	void WriteToPluto(CPluto& u);
private:
	vector<vector<int>> m_data;
	int FLastCardID;                          // 最后出牌ID
	int FLastPlace;                           // 最后出牌玩家
};



//////////////////////////////////////////////////////////////////////////

// 明牌数据
struct TMJMingPaiItem
{
	TMJMingPaiItem();
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId);
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector);
	TMJMingPaiItem(const TMJMingPaiItem& other);
	~TMJMingPaiItem();

	int rPlace;					 // 谁的数据
	vector<int> rAryData;        // 牌数据
	TMJActionName rMJAction;	 // 何种形式的明牌
	int rLastCardId;			 // 形成牌串的那张牌(吃碰杠进的牌)
	int rLastPlace;				 // 形成牌串的那个人(被吃碰杠的那个人)
};

class CMJMingPai
{
public:
	CMJMingPai();
	~CMJMingPai();

	void clearData();
	bool hasPengGangItem(int place, int lastCardId, TMJActionName mjAction);
	bool hasPengGang(int place);
	bool hasChiPai(int place);
	void addMingPaiItem(TMJMingPaiItem addItem);
	int jiaGang(int place, int lastCardId);
	bool mdfJiaGang2Peng(int place, int lastCardId);

	void getMJCountAry(int place, vector<int>& countAry);
	int getMJCount(int cardId);
	int getMingGangCount(int place);
	int getAnGangCount(int place);
	void getMingPaiListByPlace(int place, vector<TMJMingPaiItem>& mingPaiList);
	void WriteToPluto(CPluto& u);
private:
	// 明牌数据， 注意： vector里存储的是对象不是指针，因为没有多少数据加入，所以不担心临时对象创建/销毁/拷贝构造
	// 相比较编码时实时关注内存变化，采用存储对象的方案
	vector<TMJMingPaiItem> m_data;   
};




//////////////////////////////////////////////////////////////////////////

struct TMJShouPaiItem
{
	vector<int> rData;						// 数据数组
	int rLastCardID;                        // 最后一张摸到或出的牌
	bool rBCommOrder;                       // 是否是正常顺序(万饼条风箭花 -- 风箭花万饼条)
	bool rBAsce;                            // 是否升序排列(风箭花肯定是升序)
	bool rBMoPai;                           // 是否刚摸到牌
	bool rBJinZhang;                        // 是否已经进张

};

class CMJActionMgr;
class CMJShouPai
{
public:
	CMJShouPai();
	CMJShouPai(CMJActionMgr* pMJActionMgr);
	~CMJShouPai();

	void clearData();
	void doStop();
	void WriteToPluto(int place, CPluto& u);

	void zhuaPai(int place, vector<int>& cardAry);      // 开局抓牌
	void takePai(int place, int cardId);
	void chuPai(int place, int cardId);
	void pengGangPai(int place, int cardId, int cardCount);
	bool swapCards(int place, vector<int>& addCards, vector<int>& delCards);
	bool deleteACard(int APlace, int ACardID);
	void chiPai(int place, int cardId00, int cardId01);


	// 随机选择交换的牌
	void calcSwapCard(int place, vector<int>& cardAry);  
	TMJCardSuit calcSelDelSuit(int place);
	vector<int>& getUserCardList(int place);
	int getUserCardCount(int place);


	bool isJinZhang(int place);
	int cardCount(int place, int cardId) const;
	bool hasCard(int place, int cardId) const;
	void getMJCountAry(int place, vector<int>& countAry);
private:
	vector<TMJShouPaiItem*> m_data;
	CMJActionMgr* m_pMJActionMgr;

	void sortMJCard(int APlace);
	
};

//////////////////////////////////////////////////////////////////////////

struct TMJSpecialGangItem
{
	int gangFlag;
	vector<int> dataVec;

	TMJSpecialGangItem();
	~TMJSpecialGangItem();
	TMJSpecialGangItem(const TMJSpecialGangItem& other);
	TMJSpecialGangItem(int aGangFlag, const vector<int>& aVec);
};



#endif