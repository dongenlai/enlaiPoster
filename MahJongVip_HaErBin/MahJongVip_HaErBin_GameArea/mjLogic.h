#ifndef _MJ_LOGIC_H_
#define  _MJ_LOGIC_H_

#include <vector>
#include "type_card.h"
#include "type_area.h"


using std::vector;
using std::string;


struct TMJFanZhongItem
{
	TMJFanZhongItem();
	TMJFanZhongItem(const TMJFanZhongItem& other);
	TMJFanZhongItem(int aId, int aPoint, const string& aName);

	int id;
	int point;
	string name;
};

/*
	胡牌信息
*/
struct TMJHuPaiInfoItem
{
	TMJHuPaiInfoItem();
	TMJHuPaiInfoItem(const TMJHuPaiInfoItem& other);
	TMJHuPaiInfoItem(bool aisWinner, bool aIsZimo, int aDianPaoPlace, int aLastCardId, const vector<int>& aFanZhongList);
    void calcScores(int hebORdq);
	bool isWinner;              // 是否是赢家
	bool isZiMo;                // 是否自摸
	int dianPaoPlace;			// 如果不是自摸，点炮玩家或者赢家
	int lastCardId;				// 最后一张炮牌（自摸的最后一张）
	int scores;					// 总番数
	vector<int> fanZhongList;   // 番数列表
};

/*
	听牌信息
*/
struct TMJTingPaiInfoItem
{
	TMJTingPaiInfoItem();
	TMJTingPaiInfoItem(const TMJTingPaiInfoItem& other);
	TMJTingPaiInfoItem(int aHuCardId, int aHuFan);

	int huCardId;				// 玩家胡的是哪张
	int huFan;					// 玩家胡牌的番数
};

class CMJLogicMgr
{
public:
	CMJLogicMgr();
	~CMJLogicMgr();

	bool isPengPengHu(const vector<int>& cardCountList);
	bool isTingPengPeng(const vector<int>& cardCountList);
    int isHuPai(const bool checkKePai, const  bool checkShunPai, const vector<int>& cardCountList, TTableRuleInfo &tableRule, int cardID, int GuaDaFengCardID, bool isGuaDaFeng);
	bool hasDelSuitCard(TMJCardSuit delSuit, const vector<int>& cardCountList);
	int getMenSuitCount(const vector<int>& cardCountList);
	int getSuitCout(const vector<int>& cardCountList);
	bool hasYaoJiuCard(const vector<int>& cardCountList);

	void getZuHeList(vector<vector<int>>& retVecVec);
	void getMaxFanZhong(bool isCheckBianKaDiao, bool isZimo, int lastCardId, vector<int>& retVec);
    int calcScores(const vector<int>& fanZhongInfoVec, int hebORdq);
	bool checkQiDuiHuPai(const vector<int>& cardCountList);
	bool checkTingQiDuiHuPai(const vector<int>& cardCountList, bool& retIsHaoHua);

	inline int getRunCount() const
	{
		return m_runCount;
	}
	inline vector<TMJFanZhongItem> getFanZhongCfgList() const
	{
		return m_fanZhongConfigList; 
	}
    inline vector<vector<vector<int>>> getAllZuHeList() const
    {
        return m_allZuHeList;
    }
private:
	bool isNullPai(const vector<int>& cardCountList);
	bool checkCommHuPai(vector<int>& cardCountList, bool hasJiang, vector<vector<int>>& retZuHeList);
    bool checkCommHuPaiWithLaiZi(int laiZiCount, vector<int>& cardCountList, bool hasJiang, vector<vector<int>>& retZuHeList);
private:
	vector<TMJFanZhongItem> m_fanZhongConfigList;
	vector<vector<int>> m_calcZuHeList;
	vector<vector<vector<int>>>  m_allZuHeList;
	vector<int> m_calcFanZhong;
    vector<int> m_calcHuType;
	int m_runCount;
};





#endif // !MJ_LOGIC_H
