#ifndef __MJ_ACTION_MGR__HEAD__
#define __MJ_ACTION_MGR__HEAD__

#include <string>
#include <vector>
#include <stdint.h>
#include "mjTypeDefine.h"
#include "pluto.h"
#include <sstream>

using std::string;
using std::vector;


struct TPlayerMJAction
{
	TMJActionName MJAName;   // 动作名称
	int Place;				 // 玩家标示
	bool HasPass;			 // 玩家是否已经申请过掉该动作
	bool HasApply;           // 玩家是否已经申请执行该动作
	string ExpandStr;        // 相关联的字符串

	TPlayerMJAction()
	{
		MJAName = mjaError;
	}

	TPlayerMJAction(TMJActionName aName, int aPlace, bool aHasPass, bool aHasApply, const string& aStr)
	{
		MJAName = aName;
		Place = aPlace;
		HasPass = aHasPass;
		HasApply = aHasApply;
		ExpandStr = aStr;
	}

	TPlayerMJAction(const TPlayerMJAction& other)
	{
		MJAName = other.MJAName;
		Place = other.Place;
		HasPass = other.HasPass;
		HasApply = other.HasApply;
		ExpandStr = other.ExpandStr;
	}
};

class CGameTable;
class CMJDataMgr;
class CMJActionMgr
{
public:
	CMJActionMgr();
	~CMJActionMgr();

	void init(CGameTable* aParentTable, CMJDataMgr* mjDataMgr);
	// 清空数据
	void initData();
	// 开始行牌
	void beginXingPai();
	// 结束行牌
	void endXingPai();
	// 申请某个动作
	bool applyAction(int place, TMJActionName mjAction, const string expandStr);

	void doActionStateRunTime();

	void clearActionList();
	void addAction(int place, TMJActionName mjAction, bool hasApply, bool hasPass, const string expandStr);
	void delHuPaiAction(int place);
	void delAllActionExceptHuPaiAction();
	void sortALLAction();
	
	bool hasChuPai();
	bool hasHuPaiAciton();
	bool hasAciton(int place, TMJActionName mjAction);
	bool hasAcitonExact(int place, TMJActionName mjAction, const string& expandStr);
	void updateTimerState();

	void writeUserAction2Pluto(int place, CPluto* pu);
	void analyseSpecialGangExpandStr(const string& expandStr, int& gangFlag, vector<int>& retCardList);

	void debugStr(stringstream& aStream);
public:
	inline int getDecTimeCount(){ return FDecTimeCount; }
private:
	void DoActionStateAnimation();
	void DoActionStateWaitChu();
	void DoActionStateWaitDongZuo();

	bool procAction(TMJActionName mjAction);
	bool procAction(int place, TMJActionName mjAction);
	bool procAction(vector<TPlayerMJAction>::iterator itProc);

	void trustProcAciton(int place);
	void trustChuPai();
	void procHighPRIValidAction();

	bool isOnlyDongZuo(TMJActionName mjAction);
	bool isAutoChu();
	bool isAutoHu();
	TMJActionName getAutoGangAction(bool isMoPai);
	void calcDecTimeCount4Animi();
private:
	CGameTable* FParentTable;
	CMJDataMgr* FMJDataMgr;
	vector<TPlayerMJAction> FCurrActionList;             // 当前有效的动作列表
	vector<TPlayerMJAction> FCurrTingPaiActionList;      // 玩家听牌的动作列表， 因为听牌只是让客户端呈现界面，没有实际的上听动作，所以独立成表
	TActionState FCurrActionState;                       // 当前动作状态
	TMJActionName FLastActionName;                       // 上一次处理的动作
	TMJActionName FCurrProcAciton;                       // 正在处理的动作
	TTimerState FTimerState;                             // 时钟状态(同步客户端)
	int32_t FDecTimeCount;                               // 倒计时
	bool FBIsGangBu;                                     // 是否是杠后补张
	bool FIsGangPao;
	bool FIsGangShangKaiHua;

	friend class CGameTable;
	friend class CMJDataMgr;
};





#endif