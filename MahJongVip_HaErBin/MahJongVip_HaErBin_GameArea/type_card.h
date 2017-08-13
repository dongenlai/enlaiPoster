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

// һ���齫��
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

// ��ǽ
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
	vector<int> m_cntList;       // ʣ������
	vector<int> m_cntBeginList;  // ��ǽ��ʼ����
	int m_startMoPaiPlace;
	int m_currMoPaiPlace;

	friend class CMJDataMgr;

	void initPaiQiang(int eastPlace);
};

//////////////////////////////////////////////////////////////////////////

// ����
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
	int FLastCardID;                          // ������ID
	int FLastPlace;                           // ���������
};



//////////////////////////////////////////////////////////////////////////

// ��������
struct TMJMingPaiItem
{
	TMJMingPaiItem();
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId);
	TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector);
	TMJMingPaiItem(const TMJMingPaiItem& other);
	~TMJMingPaiItem();

	int rPlace;					 // ˭������
	vector<int> rAryData;        // ������
	TMJActionName rMJAction;	 // ������ʽ������
	int rLastCardId;			 // �γ��ƴ���������(�����ܽ�����)
	int rLastPlace;				 // �γ��ƴ����Ǹ���(�������ܵ��Ǹ���)
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
	// �������ݣ� ע�⣺ vector��洢���Ƕ�����ָ�룬��Ϊû�ж������ݼ��룬���Բ�������ʱ���󴴽�/����/��������
	// ��Ƚϱ���ʱʵʱ��ע�ڴ�仯�����ô洢����ķ���
	vector<TMJMingPaiItem> m_data;   
};




//////////////////////////////////////////////////////////////////////////

struct TMJShouPaiItem
{
	vector<int> rData;						// ��������
	int rLastCardID;                        // ���һ�������������
	bool rBCommOrder;                       // �Ƿ�������˳��(���������� -- ����������)
	bool rBAsce;                            // �Ƿ���������(������϶�������)
	bool rBMoPai;                           // �Ƿ��������
	bool rBJinZhang;                        // �Ƿ��Ѿ�����

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

	void zhuaPai(int place, vector<int>& cardAry);      // ����ץ��
	void takePai(int place, int cardId);
	void chuPai(int place, int cardId);
	void pengGangPai(int place, int cardId, int cardCount);
	bool swapCards(int place, vector<int>& addCards, vector<int>& delCards);
	bool deleteACard(int APlace, int ACardID);
	void chiPai(int place, int cardId00, int cardId01);


	// ���ѡ�񽻻�����
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