#ifndef _MJ_LOGIC_H_
#define  _MJ_LOGIC_H_

#include <vector>
#include "stdafx.h"
#include "type_card.h"

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



class CMJLogicMgr
{
public:
	CMJLogicMgr();
	~CMJLogicMgr();

	bool isHuPai(const vector<int>& cardCountList);
	void getZuHeList(vector<vector<int>>& retVecVec);
	void calcFanZhong(const vector<vector<int>>& shouPaiCard, const vector<TMJMingPaiItem>& mingPaiCard,
		bool isZimo, vector<int>& retVec);


	inline int getRunCount() const
	{
		return m_runCount;
	}
private:
	bool isNullPai(const vector<int>& cardCountList);
	bool checkCommHuPai(vector<int>& cardCountList, bool hasJiang, vector<vector<int>>& retZuHeList);
private:
	vector<vector<int>> m_calcZuHeList;
	vector<int> m_calcFanZhong;
	int m_runCount;
};





#endif // !MJ_LOGIC_H
